/**
 * Supabase PostgREST adapter aligned with BE-1's schema & RPCs:
 * - public.orders (status, stock_applied)
 * - public.payments (order_id, snap_token, redirect_url, transaction_id,
 *   payment_type, transaction_status, fraud_status, gross_amount, raw_notification)
 * - public.apply_paid_order(p_order_id) RPC for idempotent PAID + stock deduction
 */
export class SupabaseStore {
  constructor(config, fetchImpl = globalThis.fetch) {
    this.baseUrl = `${config.supabaseUrl}/rest/v1`;
    this.serviceRoleKey = config.supabaseServiceRoleKey;
    this.fetch = fetchImpl;
  }

  _headers(extra = {}) {
    const isJwt = this.serviceRoleKey.split('.').length === 3;
    return {
      apikey: this.serviceRoleKey,
      ...(isJwt ? { Authorization: `Bearer ${this.serviceRoleKey}` } : {}),
      'Content-Type': 'application/json',
      ...extra,
    };
  }

  async _request(pathWithQuery, options = {}) {
    const res = await this.fetch(`${this.baseUrl}${pathWithQuery}`, {
      ...options,
      headers: this._headers(options.headers),
    });

    const text = await res.text();
    const data = text ? JSON.parse(text) : null;

    if (!res.ok) {
      const err = new Error(data?.message ?? `Supabase REST error (${res.status})`);
      err.statusCode = 502;
      throw err;
    }

    return data;
  }

  async getOrderById(orderId) {
    const rows = await this._request(
      `/orders?id=eq.${encodeURIComponent(orderId)}&select=*&limit=1`,
    );
    return rows?.[0] ?? null;
  }

  async getPaymentByOrderId(orderId) {
    const rows = await this._request(
      `/payments?order_id=eq.${encodeURIComponent(orderId)}&select=*&limit=1`,
    );
    return rows?.[0] ?? null;
  }

  async upsertPayment(paymentInput) {
    // Only send columns defined in BE-1's public.payments table.
    const payload = {
      order_id: paymentInput.order_id,
      snap_token: paymentInput.snap_token ?? null,
      redirect_url: paymentInput.redirect_url ?? null,
      transaction_id: paymentInput.transaction_id ?? null,
      payment_type: paymentInput.payment_type ?? null,
      transaction_status: paymentInput.transaction_status ?? null,
      fraud_status: paymentInput.fraud_status ?? null,
      gross_amount: paymentInput.gross_amount ?? null,
      raw_notification: paymentInput.raw_notification ?? null,
    };

    const rows = await this._request('/payments?on_conflict=order_id', {
      method: 'POST',
      headers: {
        Prefer: 'resolution=merge-duplicates,return=representation',
      },
      body: JSON.stringify(payload),
    });

    return rows?.[0] ?? payload;
  }

  async updateOrderStatus(orderId, status) {
    if (status === 'PAID') {
      await this._request('/rpc/apply_paid_order', {
        method: 'POST',
        body: JSON.stringify({ p_order_id: orderId }),
      });
      return await this.getOrderById(orderId);
    }

    const rows = await this._request(`/orders?id=eq.${encodeURIComponent(orderId)}`, {
      method: 'PATCH',
      headers: {
        Prefer: 'return=representation',
      },
      body: JSON.stringify({ status }),
    });

    return rows?.[0] ?? null;
  }
}
