import http from 'node:http';
import { pathToFileURL } from 'node:url';
import { loadConfig } from './config.js';
import { createStore } from './store/index.js';
import { MidtransService } from './services/midtransService.js';
import { createPaymentHandlers } from './handlers/paymentHandlers.js';
import { fail, sendJson } from './utils/http.js';

export function createApp(overrides = {}) {
  const config = loadConfig(overrides);
  const store = overrides.store ?? createStore(config);
  const midtrans = overrides.midtrans ?? new MidtransService(config);
  const handlers = createPaymentHandlers({ config, store, midtrans });

  const handler = async (req, res) => {
    try {
      if (req.method === 'OPTIONS') {
        return sendJson(res, 204, null);
      }

      const url = new URL(req.url ?? '/', `http://${req.headers?.host ?? 'localhost'}`);
      const pathname = url.pathname.replace(/\/+$/, '') || '/';

      if (req.method === 'GET' && (pathname === '/' || pathname === '/api/health')) {
        return await handlers.health(req, res);
      }
      if (req.method === 'POST' && pathname === '/api/dev/orders') {
        return await handlers.devCreateOrder(req, res);
      }
      if (req.method === 'GET' && pathname === '/api/dev/orders') {
        return await handlers.devListOrders(req, res);
      }
      if (req.method === 'POST' && pathname === '/api/dev/simulate-webhook') {
        return await handlers.devSimulateWebhook(req, res);
      }
      if (req.method === 'POST' && pathname === '/api/payments/create') {
        return await handlers.createPayment(req, res);
      }
      if (req.method === 'POST' && pathname === '/api/payments/webhook') {
        return await handlers.handleWebhook(req, res);
      }

      const statusMatch = pathname.match(/^\/api\/payments\/([^/]+)\/status$/);
      if (req.method === 'GET' && statusMatch) {
        const orderId = decodeURIComponent(statusMatch[1]);
        return await handlers.getStatus(req, res, orderId, url.searchParams);
      }

      return fail(res, `Route not found: ${req.method} ${pathname}`, 404);
    } catch (err) {
      const statusCode = Number(err?.statusCode) || 500;
      return fail(res, err?.message ?? 'Internal server error', statusCode);
    }
  };

  const server = http.createServer(handler);

  return { server, handler, config, store, midtrans };
}

const isMainModule =
  process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;

if (isMainModule) {
  const { server, config } = createApp();
  server.listen(config.port, () => {
    console.log(
      `[GoVeg BE-2] listening on http://localhost:${config.port} (storage=${config.storageMode}, midtrans=${config.midtransMode})`,
    );
  });
}
