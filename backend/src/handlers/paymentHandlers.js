import crypto from 'node:crypto';
import { ok, fail, readJsonBody } from '../utils/http.js';
import {
  computeMidtransSignature,
  DEFAULT_EXPIRY_MINUTES,
  mapMidtransStatus,
  parseGrossAmount,
  resolveNextStatus,
  verifyMidtransSignature,
} from '../services/midtransService.js';

function generateOrderId() {
  const now = new Date();
  const datePart = now.toISOString().slice(0, 10).replaceAll('-', '');
  const randPart = crypto.randomBytes(2).toString('hex').toUpperCase();
  return `ORD-${datePart}-${randPart}`;
}

function resolvePaymentExpiresAt(payment) {
  const timestamp = payment?.updated_at ?? payment?.created_at;
  if (!timestamp) return null;
  const parsed = Date.parse(timestamp);
  if (Number.isNaN(parsed)) return null;
  return new Date(parsed + DEFAULT_EXPIRY_MINUTES * 60 * 1000).toISOString();
}

function resolvePaymentStatus(order, payment) {
  if (order?.status) return order.status;
  if (payment?.transaction_status) {
    return mapMidtransStatus(payment.transaction_status, payment.fraud_status);
  }
  return 'PENDING';
}

async function applyTransactionUpdate({
  store,
  order,
  existingPayment,
  transactionStatus,
  fraudStatus,
  paymentType,
  transactionId,
  rawNotification,
}) {
  const mappedStatus = mapMidtransStatus(transactionStatus, fraudStatus);
  const nextStatus = resolveNextStatus(order.status, mappedStatus);

  const updatedPayment = await store.upsertPayment({
    order_id: order.id,
    snap_token: existingPayment?.snap_token ?? null,
    redirect_url: existingPayment?.redirect_url ?? null,
    transaction_id: transactionId ?? existingPayment?.transaction_id ?? null,
    payment_type: paymentType ?? existingPayment?.payment_type ?? null,
    transaction_status:
      transactionStatus ?? existingPayment?.transaction_status ?? 'pending',
    fraud_status: fraudStatus ?? existingPayment?.fraud_status ?? null,
    gross_amount: order.gross_amount,
    raw_notification: rawNotification,
  });

  const updatedOrder = await store.updateOrderStatus(order.id, nextStatus);
  return { updatedOrder, updatedPayment };
}

export function createPaymentHandlers({ config, store, midtrans }) {
  return {
    async health(req, res) {
      return ok(res, 'GoVeg BE-2 Midtrans service is running', {
        storage_mode: config.storageMode,
        midtrans_mode: config.midtransMode,
      });
    },

    /**
     * Local-only helper to create a test order without BE-1.
     */
    async devCreateOrder(req, res) {
      if (config.storageMode !== 'local') {
        return fail(res, 'Dev order endpoint is only enabled in STORAGE_MODE=local', 403);
      }

      const body = await readJsonBody(req);
      const grossAmount = parseGrossAmount(body.gross_amount);
      if (!grossAmount) {
        return fail(res, 'gross_amount must be a positive integer (Rupiah)', 400);
      }

      const order = await store.createOrder({
        id: body.order_id ? String(body.order_id).trim() : generateOrderId(),
        userId: body.user_id ? String(body.user_id).trim() : 'demo-user-1',
        grossAmount,
      });

      return ok(res, 'Local test order created', order, 201);
    },

    async devListOrders(req, res) {
      if (config.storageMode !== 'local') {
        return fail(res, 'Dev order endpoint is only enabled in STORAGE_MODE=local', 403);
      }
      const orders = await store.listOrders();
      return ok(res, 'Local orders retrieved', orders);
    },

    /**
     * POST /api/payments/create
     * Input: { order_id, customer_details?, item_details?, enabled_payments?, force_new? }
     */
    async createPayment(req, res) {
      const body = await readJsonBody(req);
      const orderId = String(body.order_id ?? '').trim();
      if (!orderId) {
        return fail(res, 'order_id is required', 400);
      }

      const order = await store.getOrderById(orderId);
      if (!order) {
        return fail(res, `Order "${orderId}" not found`, 404);
      }

      if (order.status === 'PAID') {
        return fail(res, `Order "${orderId}" is already PAID`, 409);
      }

      const existingPayment = await store.getPaymentByOrderId(orderId);
      const existingExpiresAt = resolvePaymentExpiresAt(existingPayment);
      const isPendingAndUnexpired =
        order.status === 'PENDING' &&
        existingPayment &&
        existingPayment.snap_token &&
        existingPayment.redirect_url &&
        (!existingExpiresAt || Date.parse(existingExpiresAt) > Date.now());

      if (isPendingAndUnexpired && !body.force_new) {
        return ok(res, 'Existing pending payment retrieved', {
          order_id: orderId,
          snap_token: existingPayment.snap_token,
          redirect_url: existingPayment.redirect_url,
          payment_status: resolvePaymentStatus(order, existingPayment),
          transaction_status: existingPayment.transaction_status ?? 'pending',
          expires_at: existingExpiresAt,
        });
      }

      const { snapToken, redirectUrl, expiresAt } = await midtrans.createSnapTransaction({
        orderId,
        grossAmount: order.gross_amount,
        customerDetails: body.customer_details,
        itemDetails: body.item_details,
        enabledPayments: body.enabled_payments,
      });

      const payment = await store.upsertPayment({
        order_id: orderId,
        snap_token: snapToken,
        redirect_url: redirectUrl,
        transaction_id: existingPayment?.transaction_id ?? null,
        payment_type: existingPayment?.payment_type ?? null,
        transaction_status: 'pending',
        fraud_status: null,
        gross_amount: order.gross_amount,
        raw_notification: null,
      });

      return ok(
        res,
        'Payment initiated',
        {
          order_id: orderId,
          snap_token: payment.snap_token,
          redirect_url: payment.redirect_url,
          payment_status: order.status,
          transaction_status: payment.transaction_status ?? 'pending',
          expires_at: resolvePaymentExpiresAt(payment) ?? expiresAt,
        },
        201,
      );
    },

    /**
     * POST /api/payments/webhook
     * Midtrans HTTP Notification receiver with SHA-512 signature_key verification & idempotency.
     */
    async handleWebhook(req, res) {
      const payload = await readJsonBody(req);
      const orderId = String(payload.order_id ?? '').trim();
      const statusCode = String(payload.status_code ?? '').trim();
      const rawGrossAmount = String(payload.gross_amount ?? '').trim();
      const signatureKey = String(payload.signature_key ?? '').trim();

      const validSignature = verifyMidtransSignature({
        orderId,
        statusCode,
        grossAmount: rawGrossAmount,
        signatureKey,
        serverKey: config.midtransServerKey,
      });

      if (!validSignature) {
        return fail(res, 'Invalid Midtrans signature_key', 401);
      }

      const grossAmount = parseGrossAmount(rawGrossAmount);
      if (!grossAmount) {
        return fail(res, 'Invalid gross_amount in webhook payload', 400);
      }

      const order = await store.getOrderById(orderId);
      if (!order) {
        return fail(res, `Order "${orderId}" not found`, 404);
      }

      if (order.gross_amount !== grossAmount) {
        return fail(
          res,
          `Amount mismatch: expected ${order.gross_amount}, got ${grossAmount}`,
          400,
        );
      }

      const existingPayment = await store.getPaymentByOrderId(orderId);
      const { updatedOrder, updatedPayment } = await applyTransactionUpdate({
        store,
        order,
        existingPayment,
        transactionStatus: payload.transaction_status,
        fraudStatus: payload.fraud_status,
        paymentType: payload.payment_type,
        transactionId: payload.transaction_id,
        rawNotification: payload,
      });

      return ok(res, 'Webhook processed', {
        order_id: updatedOrder.id,
        order_status: updatedOrder.status,
        payment_status: resolvePaymentStatus(updatedOrder, updatedPayment),
        transaction_status: updatedPayment.transaction_status,
        fraud_status: updatedPayment.fraud_status,
        payment_type: updatedPayment.payment_type,
        transaction_id: updatedPayment.transaction_id,
      });
    },

    /**
     * GET /api/payments/:orderId/status (?sync=true to poll Midtrans API in sandbox mode)
     */
    async getStatus(req, res, orderId, query) {
      const order = await store.getOrderById(orderId);
      if (!order) {
        return fail(res, `Order "${orderId}" not found`, 404);
      }

      let payment = await store.getPaymentByOrderId(orderId);
      let currentOrder = order;

      if (query.get('sync') === 'true' && config.midtransMode === 'sandbox') {
        const remoteStatus = await midtrans.getTransactionStatus(orderId);
        if (remoteStatus?.transaction_status) {
          const result = await applyTransactionUpdate({
            store,
            order,
            existingPayment: payment,
            transactionStatus: remoteStatus.transaction_status,
            fraudStatus: remoteStatus.fraud_status,
            paymentType: remoteStatus.payment_type,
            transactionId: remoteStatus.transaction_id,
            rawNotification: remoteStatus,
          });
          currentOrder = result.updatedOrder;
          payment = result.updatedPayment;
        }
      }

      return ok(res, 'Payment status retrieved', {
        order_id: currentOrder.id,
        gross_amount: currentOrder.gross_amount,
        order_status: currentOrder.status,
        payment_status: resolvePaymentStatus(currentOrder, payment),
        transaction_status: payment?.transaction_status ?? null,
        fraud_status: payment?.fraud_status ?? null,
        payment_type: payment?.payment_type ?? null,
        snap_token: payment?.snap_token ?? null,
        redirect_url: payment?.redirect_url ?? null,
        expires_at: resolvePaymentExpiresAt(payment),
        updated_at: payment?.updated_at ?? currentOrder.updated_at,
      });
    },

    /**
     * Local/mock helper to simulate a Midtrans webhook with a valid SHA-512 signature.
     */
    async devSimulateWebhook(req, res) {
      if (config.midtransMode !== 'mock' || config.storageMode !== 'local') {
        return fail(
          res,
          'Webhook simulator is only available when STORAGE_MODE=local and MIDTRANS_MODE=mock',
          403,
        );
      }

      const body = await readJsonBody(req);
      const orderId = String(body.order_id ?? '').trim();
      if (!orderId) {
        return fail(res, 'order_id is required', 400);
      }

      const order = await store.getOrderById(orderId);
      if (!order) {
        return fail(res, `Order "${orderId}" not found`, 404);
      }

      const transactionStatus = String(body.transaction_status ?? 'settlement');
      const statusCode = String(body.status_code ?? (transactionStatus === 'deny' ? '202' : '200'));
      const grossAmountStr = `${order.gross_amount}.00`;
      const signatureKey = computeMidtransSignature({
        orderId,
        statusCode,
        grossAmount: grossAmountStr,
        serverKey: config.midtransServerKey,
      });

      const simulatedPayload = {
        order_id: orderId,
        status_code: statusCode,
        gross_amount: grossAmountStr,
        transaction_status: transactionStatus,
        fraud_status: body.fraud_status ?? 'accept',
        payment_type: body.payment_type ?? 'qris',
        transaction_id: body.transaction_id ?? `mock-tx-${crypto.randomUUID()}`,
        signature_key: signatureKey,
      };

      const existingPayment = await store.getPaymentByOrderId(orderId);
      const { updatedOrder, updatedPayment } = await applyTransactionUpdate({
        store,
        order,
        existingPayment,
        transactionStatus: simulatedPayload.transaction_status,
        fraudStatus: simulatedPayload.fraud_status,
        paymentType: simulatedPayload.payment_type,
        transactionId: simulatedPayload.transaction_id,
        rawNotification: simulatedPayload,
      });

      return ok(res, 'Simulated Midtrans webhook processed', {
        order_id: updatedOrder.id,
        order_status: updatedOrder.status,
        payment_status: resolvePaymentStatus(updatedOrder, updatedPayment),
        transaction_status: updatedPayment.transaction_status,
        payment_type: updatedPayment.payment_type,
        simulated_payload: simulatedPayload,
      });
    },
  };
}
