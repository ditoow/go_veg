import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { Readable } from 'node:stream';
import { createApp } from '../src/server.js';
import {
  computeMidtransSignature,
  MidtransService,
} from '../src/services/midtransService.js';
import { SupabaseStore } from '../src/store/supabaseStore.js';

function createTempDbPath() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'goveg-be2-'));
  return { dir, dbPath: path.join(dir, 'db.json') };
}

async function startTestApp(overrides = {}) {
  const { dir, dbPath } = createTempDbPath();
  const { handler, config, store } = createApp({
    port: 0,
    storageMode: 'local',
    midtransMode: 'mock',
    midtransServerKey: 'test-server-key',
    localDbPath: dbPath,
    ...overrides,
  });

  return {
    handler,
    baseUrl: handler,
    config,
    store,
    close: async () => {
      fs.rmSync(dir, { recursive: true, force: true });
    },
  };
}

async function requestJson(handler, method, route, body) {
  const chunks = body !== undefined ? [Buffer.from(JSON.stringify(body), 'utf8')] : [];
  const req = Readable.from(chunks);
  req.method = method;
  req.url = route;
  req.headers = { host: 'localhost', 'content-type': 'application/json' };

  let status = 200;
  let headers = {};
  let rawBody = '';

  await new Promise((resolve, reject) => {
    const res = {
      writeHead(code, hdrs = {}) {
        status = code;
        headers = hdrs;
      },
      end(chunk = '') {
        rawBody += chunk ? String(chunk) : '';
        resolve();
      },
    };
    Promise.resolve(handler(req, res)).catch(reject);
  });

  const json = rawBody ? JSON.parse(rawBody) : null;
  return { status, headers, json };
}

test('full local payment lifecycle: create order -> initiate snap -> webhook settlement -> idempotency', async () => {
  const ctx = await startTestApp();
  try {
    const rootHealth = await requestJson(ctx.baseUrl, 'GET', '/');
    assert.equal(rootHealth.status, 200);
    assert.equal(rootHealth.json.success, true);

    const health = await requestJson(ctx.baseUrl, 'GET', '/api/health');
    assert.equal(health.status, 200);
    assert.equal(health.json.success, true);
    assert.equal(health.json.data.storage_mode, 'local');

    // 1. Create order locally (simulates BE-1)
    const createdOrder = await requestJson(ctx.baseUrl, 'POST', '/api/dev/orders', {
      order_id: 'ORD-TEST-100',
      user_id: 'uid-1',
      gross_amount: 50000,
    });
    assert.equal(createdOrder.status, 201);
    assert.equal(createdOrder.json.data.status, 'PENDING');

    // 2. Initiate payment
    const init1 = await requestJson(ctx.baseUrl, 'POST', '/api/payments/create', {
      order_id: 'ORD-TEST-100',
    });
    assert.equal(init1.status, 201);
    assert.equal(init1.json.success, true);
    assert.equal(init1.json.data.order_id, 'ORD-TEST-100');
    assert.equal(init1.json.data.payment_status, 'PENDING');
    assert.ok(init1.json.data.expires_at);
    assert.ok(init1.json.data.snap_token.startsWith('mock-snap-'));
    assert.ok(init1.json.data.redirect_url.includes(init1.json.data.snap_token));

    // 3. Re-calling create returns same pending token (idempotent)
    const init2 = await requestJson(ctx.baseUrl, 'POST', '/api/payments/create', {
      order_id: 'ORD-TEST-100',
    });
    assert.equal(init2.status, 200);
    assert.equal(init2.json.data.snap_token, init1.json.data.snap_token);

    // 4. Reject invalid signature on webhook
    const badWebhook = await requestJson(ctx.baseUrl, 'POST', '/api/payments/webhook', {
      order_id: 'ORD-TEST-100',
      status_code: '200',
      gross_amount: '50000.00',
      transaction_status: 'settlement',
      signature_key: 'invalid-signature',
    });
    assert.equal(badWebhook.status, 401);
    assert.equal(badWebhook.json.success, false);

    // 5. Reject gross_amount mismatch even with valid signature
    const mismatchSig = computeMidtransSignature({
      orderId: 'ORD-TEST-100',
      statusCode: '200',
      grossAmount: '10000.00',
      serverKey: 'test-server-key',
    });
    const mismatchWebhook = await requestJson(ctx.baseUrl, 'POST', '/api/payments/webhook', {
      order_id: 'ORD-TEST-100',
      status_code: '200',
      gross_amount: '10000.00',
      transaction_status: 'settlement',
      signature_key: mismatchSig,
    });
    assert.equal(mismatchWebhook.status, 400);

    // 6. Valid settlement webhook updates order & payment to PAID
    const validSig = computeMidtransSignature({
      orderId: 'ORD-TEST-100',
      statusCode: '200',
      grossAmount: '50000.00',
      serverKey: 'test-server-key',
    });
    const paidWebhook = await requestJson(ctx.baseUrl, 'POST', '/api/payments/webhook', {
      order_id: 'ORD-TEST-100',
      status_code: '200',
      gross_amount: '50000.00',
      transaction_status: 'settlement',
      payment_type: 'qris',
      transaction_id: 'tx-midtrans-123',
      signature_key: validSig,
    });
    assert.equal(paidWebhook.status, 200);
    assert.equal(paidWebhook.json.data.order_status, 'PAID');
    assert.equal(paidWebhook.json.data.payment_status, 'PAID');

    // 7. Out-of-order expire/pending webhook must NOT regress PAID order
    const lateExpireSig = computeMidtransSignature({
      orderId: 'ORD-TEST-100',
      statusCode: '202',
      grossAmount: '50000.00',
      serverKey: 'test-server-key',
    });
    const lateWebhook = await requestJson(ctx.baseUrl, 'POST', '/api/payments/webhook', {
      order_id: 'ORD-TEST-100',
      status_code: '202',
      gross_amount: '50000.00',
      transaction_status: 'expire',
      signature_key: lateExpireSig,
    });
    assert.equal(lateWebhook.status, 200);
    assert.equal(lateWebhook.json.data.order_status, 'PAID');

    // 8. Cannot re-initiate payment on already PAID order
    const reInitPaid = await requestJson(ctx.baseUrl, 'POST', '/api/payments/create', {
      order_id: 'ORD-TEST-100',
    });
    assert.equal(reInitPaid.status, 409);

    // 9. Status endpoint reflects PAID
    const statusRes = await requestJson(ctx.baseUrl, 'GET', '/api/payments/ORD-TEST-100/status');
    assert.equal(statusRes.status, 200);
    assert.equal(statusRes.json.data.payment_status, 'PAID');
    assert.equal(statusRes.json.data.payment_type, 'qris');
  } finally {
    await ctx.close();
  }
});

test('status mapping via dev simulator covers expire, cancel, and deny', async () => {
  const ctx = await startTestApp();
  try {
    const cases = [
      { orderId: 'ORD-EXPIRE', tx: 'expire', expected: 'EXPIRED' },
      { orderId: 'ORD-CANCEL', tx: 'cancel', expected: 'CANCELLED' },
      { orderId: 'ORD-DENY', tx: 'deny', expected: 'FAILED' },
    ];

    for (const c of cases) {
      await requestJson(ctx.baseUrl, 'POST', '/api/dev/orders', {
        order_id: c.orderId,
        gross_amount: 25000,
      });
      await requestJson(ctx.baseUrl, 'POST', '/api/payments/create', {
        order_id: c.orderId,
      });
      const sim = await requestJson(ctx.baseUrl, 'POST', '/api/dev/simulate-webhook', {
        order_id: c.orderId,
        transaction_status: c.tx,
      });
      assert.equal(sim.status, 200);
      assert.equal(sim.json.data.order_status, c.expected);
      assert.equal(sim.json.data.payment_status, c.expected);
    }
  } finally {
    await ctx.close();
  }
});

test('SupabaseStore issues expected PostgREST requests with service role key', async () => {
  const calls = [];
  const fakeFetch = async (url, options) => {
    calls.push({ url, options });
    return {
      ok: true,
      status: 200,
      text: async () => JSON.stringify([{ id: 'ORD-SB-1', status: 'PAID', gross_amount: 30000 }]),
    };
  };

  const store = new SupabaseStore(
    {
      supabaseUrl: 'https://demo.supabase.co',
      supabaseServiceRoleKey: 'eyJ.jwt.secret',
    },
    fakeFetch,
  );

  const order = await store.getOrderById('ORD-SB-1');
  assert.equal(order.id, 'ORD-SB-1');
  assert.equal(calls[0].url, 'https://demo.supabase.co/rest/v1/orders?id=eq.ORD-SB-1&select=*&limit=1');
  assert.equal(calls[0].options.headers.apikey, 'eyJ.jwt.secret');
  assert.equal(calls[0].options.headers.Authorization, 'Bearer eyJ.jwt.secret');

  await store.upsertPayment({
    order_id: 'ORD-SB-1',
    transaction_status: 'settlement',
    fraud_status: 'accept',
    payment_type: 'qris',
    gross_amount: 30000,
  });
  assert.equal(calls[1].url, 'https://demo.supabase.co/rest/v1/payments?on_conflict=order_id');
  assert.equal(calls[1].options.method, 'POST');
  assert.match(calls[1].options.headers.Prefer, /resolution=merge-duplicates/);
  const upsertBody = JSON.parse(calls[1].options.body);
  assert.equal(upsertBody.transaction_status, 'settlement');
  assert.equal(upsertBody.payment_status, undefined);

  await store.updateOrderStatus('ORD-SB-1', 'PAID');
  assert.equal(calls[2].url, 'https://demo.supabase.co/rest/v1/rpc/apply_paid_order');
  assert.equal(calls[2].options.method, 'POST');
  assert.deepEqual(JSON.parse(calls[2].options.body), { p_order_id: 'ORD-SB-1' });
  assert.equal(calls[3].url, 'https://demo.supabase.co/rest/v1/orders?id=eq.ORD-SB-1&select=*&limit=1');

  await store.updateOrderStatus('ORD-SB-1', 'EXPIRED');
  assert.equal(calls[4].url, 'https://demo.supabase.co/rest/v1/orders?id=eq.ORD-SB-1');
  assert.equal(calls[4].options.method, 'PATCH');
  assert.deepEqual(JSON.parse(calls[4].options.body), { status: 'EXPIRED' });

  // Verify new opaque sb_secret_ key omits Authorization Bearer header
  const secretStore = new SupabaseStore(
    {
      supabaseUrl: 'https://demo.supabase.co',
      supabaseServiceRoleKey: 'sb_secret_opaque_key',
    },
    fakeFetch,
  );
  await secretStore.getOrderById('ORD-SB-1');
  assert.equal(calls[5].options.headers.apikey, 'sb_secret_opaque_key');
  assert.equal(calls[5].options.headers.Authorization, undefined);
});

test('MidtransService sends 10-minute expiry and page_expiry to Snap API', async () => {
  let sentBody = null;
  const fakeFetch = async (_url, options) => {
    sentBody = JSON.parse(options.body);
    return {
      ok: true,
      status: 201,
      json: async () => ({
        token: 'snap-10m',
        redirect_url: 'https://app.sandbox.midtrans.com/snap/v4/redirection/snap-10m',
      }),
    };
  };

  const svc = new MidtransService(
    {
      midtransMode: 'sandbox',
      midtransServerKey: 'SB-Mid-server-test',
      midtransSnapBaseUrl: 'https://app.sandbox.midtrans.com/snap/v1',
      midtransApiBaseUrl: 'https://api.sandbox.midtrans.com/v2',
    },
    fakeFetch,
  );

  const result = await svc.createSnapTransaction({ orderId: 'ORD-10M', grossAmount: 20000 });
  assert.equal(result.snapToken, 'snap-10m');
  assert.ok(result.expiresAt);
  assert.equal(sentBody.expiry.unit, 'minutes');
  assert.equal(sentBody.expiry.duration, 10);
  assert.match(sentBody.expiry.start_time, /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+0700$/);
  assert.equal(sentBody.page_expiry.unit, 'minutes');
  assert.equal(sentBody.page_expiry.duration, 10);
});
