import { createApp } from '../src/server.js';

let app;

/**
 * Vercel Serverless Function entrypoint routing all HTTP endpoints to BE-2.
 */
export default async function handler(req, res) {
  if (!app) {
    app = createApp();
  }
  return await app.handler(req, res);
}
