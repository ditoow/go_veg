import crypto from 'node:crypto';

const TERMINAL_PAID_STATUS = 'PAID';
export const DEFAULT_EXPIRY_MINUTES = 10;

/**
 * Formats a Date into Midtrans `yyyy-MM-dd HH:mm:ss +0700` (WIB / GMT+7).
 */
export function formatMidtransStartTime(date = new Date()) {
  const wibMs = date.getTime() + 7 * 60 * 60 * 1000;
  const wib = new Date(wibMs);
  const pad = (n) => String(n).padStart(2, '0');
  return `${wib.getUTCFullYear()}-${pad(wib.getUTCMonth() + 1)}-${pad(wib.getUTCDate())} ${pad(wib.getUTCHours())}:${pad(wib.getUTCMinutes())}:${pad(wib.getUTCSeconds())} +0700`;
}

/**
 * Maps Midtrans transaction_status & fraud_status to standardized app statuses:
 * PENDING | PAID | FAILED | EXPIRED | CANCELLED
 */
export function mapMidtransStatus(transactionStatus, fraudStatus = '') {
  const tx = String(transactionStatus ?? '').toLowerCase();
  const fraud = String(fraudStatus ?? '').toLowerCase();

  switch (tx) {
    case 'capture':
      if (fraud === 'challenge') return 'PENDING';
      if (fraud === 'deny') return 'FAILED';
      return 'PAID';
    case 'settlement':
      return 'PAID';
    case 'pending':
      return 'PENDING';
    case 'deny':
      return 'FAILED';
    case 'expire':
      return 'EXPIRED';
    case 'cancel':
      return 'CANCELLED';
    default:
      return 'PENDING';
  }
}

/**
 * Generates Midtrans webhook signature:
 * SHA512(order_id + status_code + gross_amount + serverKey)
 */
export function computeMidtransSignature({ orderId, statusCode, grossAmount, serverKey }) {
  const payload = `${orderId}${statusCode}${grossAmount}${serverKey}`;
  return crypto.createHash('sha512').update(payload).digest('hex');
}

/**
 * Timing-safe verification for Midtrans webhook signature_key.
 */
export function verifyMidtransSignature({
  orderId,
  statusCode,
  grossAmount,
  signatureKey,
  serverKey,
}) {
  if (!orderId || !statusCode || !grossAmount || !signatureKey || !serverKey) {
    return false;
  }
  const expected = computeMidtransSignature({ orderId, statusCode, grossAmount, serverKey });
  const received = String(signatureKey).toLowerCase();
  const expectedBuf = Buffer.from(expected, 'utf8');
  const receivedBuf = Buffer.from(received, 'utf8');
  if (expectedBuf.length !== receivedBuf.length) return false;
  return crypto.timingSafeEqual(expectedBuf, receivedBuf);
}

/**
 * Parses Midtrans gross_amount (e.g. "50000.00" or 50000) into integer Rupiah.
 */
export function parseGrossAmount(rawAmount) {
  const num = Number(rawAmount);
  if (!Number.isFinite(num) || num <= 0) return null;
  return Math.round(num);
}

/**
 * Prevents out-of-order/duplicate webhooks from regressing an already PAID order.
 */
export function resolveNextStatus(currentStatus, incomingStatus) {
  if (currentStatus === TERMINAL_PAID_STATUS && incomingStatus !== TERMINAL_PAID_STATUS) {
    return TERMINAL_PAID_STATUS;
  }
  return incomingStatus;
}

export class MidtransService {
  constructor(config, fetchImpl = globalThis.fetch) {
    this.config = config;
    this.fetch = fetchImpl;
  }

  get _authHeader() {
    const encoded = Buffer.from(`${this.config.midtransServerKey}:`).toString('base64');
    return `Basic ${encoded}`;
  }

  async createSnapTransaction({
    orderId,
    grossAmount,
    customerDetails,
    itemDetails,
    enabledPayments,
    expiryMinutes = DEFAULT_EXPIRY_MINUTES,
  }) {
    const now = new Date();
    const expiresAt = new Date(now.getTime() + expiryMinutes * 60 * 1000).toISOString();

    if (this.config.midtransMode === 'mock') {
      const token = `mock-snap-${crypto.randomUUID()}`;
      return {
        snapToken: token,
        redirectUrl: `https://app.sandbox.midtrans.com/snap/v4/redirection/${token}`,
        expiresAt,
      };
    }

    const body = {
      transaction_details: {
        order_id: orderId,
        gross_amount: grossAmount,
      },
      expiry: {
        start_time: formatMidtransStartTime(now),
        unit: 'minutes',
        duration: expiryMinutes,
      },
      page_expiry: {
        duration: expiryMinutes,
        unit: 'minutes',
      },
      ...(Array.isArray(enabledPayments) && enabledPayments.length > 0
        ? { enabled_payments: enabledPayments }
        : {}),
      ...(customerDetails ? { customer_details: customerDetails } : {}),
      ...(itemDetails ? { item_details: itemDetails } : {}),
    };

    const res = await this.fetch(`${this.config.midtransSnapBaseUrl}/transactions`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: this._authHeader,
      },
      body: JSON.stringify(body),
    });

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const errMsg = Array.isArray(data?.error_messages)
        ? data.error_messages.join('; ')
        : data?.status_message ?? `Midtrans Snap API error (${res.status})`;
      const err = new Error(errMsg);
      err.statusCode = 502;
      throw err;
    }

    return {
      snapToken: data.token,
      redirectUrl: data.redirect_url,
      expiresAt,
    };
  }

  async getTransactionStatus(orderId) {
    if (this.config.midtransMode === 'mock') {
      return null;
    }

    const res = await this.fetch(
      `${this.config.midtransApiBaseUrl}/${encodeURIComponent(orderId)}/status`,
      {
        method: 'GET',
        headers: {
          Accept: 'application/json',
          Authorization: this._authHeader,
        },
      },
    );

    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      if (res.status === 404) return null;
      const err = new Error(data?.status_message ?? `Midtrans Status API error (${res.status})`);
      err.statusCode = 502;
      throw err;
    }

    return data;
  }
}
