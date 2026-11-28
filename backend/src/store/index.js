import { LocalStore } from './localStore.js';
import { SupabaseStore } from './supabaseStore.js';

export function createStore(config) {
  if (config.storageMode === 'supabase') {
    return new SupabaseStore(config);
  }
  return new LocalStore(config.localDbPath);
}
