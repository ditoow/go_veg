import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const BACKEND_ROOT = path.resolve(__dirname, '..');

/**
 * Load `.env` from backend root if it exists without overriding already-set process.env vars.
 */
function loadDotEnvIfPresent() {
  const envPath = path.join(BACKEND_ROOT, '.env');
  if (!fs.existsSync(envPath)) return;
  const content = fs.readFileSync(envPath, 'utf8');
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const eqIndex = line.indexOf('=');
    if (eqIndex <= 0) continue;
    const key = line.slice(0, eqIndex).trim();
    let value = line.slice(eqIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

export function loadConfig(overrides = {}) {
  loadDotEnvIfPresent();

  const storageMode = (overrides.storageMode ?? process.env.STORAGE_MODE ?? 'local').toLowerCase();
  const midtransMode = (overrides.midtransMode ?? process.env.MIDTRANS_MODE ?? 'mock').toLowerCase();
  const isProduction = String(overrides.isProduction ?? process.env.MIDTRANS_IS_PRODUCTION ?? 'false') === 'true';

  if (!['local', 'supabase'].includes(storageMode)) {
    throw new Error(`Invalid STORAGE_MODE "${storageMode}". Expected "local" or "supabase".`);
  }
  if (!['mock', 'sandbox'].includes(midtransMode)) {
    throw new Error(`Invalid MIDTRANS_MODE "${midtransMode}". Expected "mock" or "sandbox".`);
  }

  const config = {
    port: Number(overrides.port ?? process.env.PORT ?? 8080),
    storageMode,
    midtransMode,
    midtransServerKey: overrides.midtransServerKey ?? process.env.MIDTRANS_SERVER_KEY ?? 'mock-midtrans-server-key',
    midtransSnapBaseUrl: isProduction
      ? 'https://app.midtrans.com/snap/v1'
      : 'https://app.sandbox.midtrans.com/snap/v1',
    midtransApiBaseUrl: isProduction
      ? 'https://api.midtrans.com/v2'
      : 'https://api.sandbox.midtrans.com/v2',
    supabaseUrl: (overrides.supabaseUrl ?? process.env.SUPABASE_URL ?? '').replace(/\/+$/, ''),
    supabaseServiceRoleKey: overrides.supabaseServiceRoleKey ?? process.env.SUPABASE_SERVICE_ROLE_KEY ?? '',
    localDbPath:
      overrides.localDbPath ??
      (process.env.VERCEL
        ? path.join(os.tmpdir(), 'go_veg_db.json')
        : path.join(BACKEND_ROOT, 'data', 'db.json')),
  };

  if (config.storageMode === 'supabase') {
    if (
      !config.supabaseUrl ||
      config.supabaseUrl.includes('YOUR_PROJECT_REF') ||
      !config.supabaseServiceRoleKey ||
      config.supabaseServiceRoleKey.includes('YOUR_SUPABASE')
    ) {
      throw new Error(
        'STORAGE_MODE=supabase requires valid SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.',
      );
    }
  }

  if (config.midtransMode === 'sandbox') {
    if (!config.midtransServerKey || config.midtransServerKey.includes('REPLACE_WITH')) {
      throw new Error('MIDTRANS_MODE=sandbox requires a valid MIDTRANS_SERVER_KEY.');
    }
  }

  return config;
}
