import fs from 'node:fs';
import path from 'node:path';

const DEFAULT_SEED_DATA = {
  orders: [
    {
      id: 'ORD-20261126-0001',
      user_id: 'demo-user-1',
      gross_amount: 38500,
      status: 'PENDING',
      created_at: '2026-11-26T08:30:00.000Z',
      updated_at: '2026-11-26T08:30:00.000Z',
    },
  ],
  payments: [],
};

/**
 * File-backed JSON store for local testing before BE-1 pushes Supabase tables.
 */
export class LocalStore {
  constructor(dbPath) {
    this.dbPath = dbPath;
    this._ensureDb();
  }

  _ensureDb() {
    const dir = path.dirname(this.dbPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    if (!fs.existsSync(this.dbPath)) {
      fs.writeFileSync(this.dbPath, JSON.stringify(DEFAULT_SEED_DATA, null, 2), 'utf8');
    }
  }

  _read() {
    this._ensureDb();
    const raw = fs.readFileSync(this.dbPath, 'utf8');
    const parsed = JSON.parse(raw);
    return {
      orders: Array.isArray(parsed.orders) ? parsed.orders : [],
      payments: Array.isArray(parsed.payments) ? parsed.payments : [],
    };
  }

  _write(data) {
    this._ensureDb();
    fs.writeFileSync(this.dbPath, JSON.stringify(data, null, 2), 'utf8');
  }

  async getOrderById(orderId) {
    const db = this._read();
    return db.orders.find((o) => o.id === orderId) ?? null;
  }

  async createOrder({ id, userId, grossAmount }) {
    const db = this._read();
    if (db.orders.some((o) => o.id === id)) {
      const err = new Error(`Order "${id}" already exists`);
      err.statusCode = 409;
      throw err;
    }
    const now = new Date().toISOString();
    const order = {
      id,
      user_id: userId,
      gross_amount: grossAmount,
      status: 'PENDING',
      stock_applied: false,
      created_at: now,
      updated_at: now,
    };
    db.orders.push(order);
    this._write(db);
    return order;
  }

  async listOrders() {
    return this._read().orders;
  }

  async getPaymentByOrderId(orderId) {
    const db = this._read();
    return db.payments.find((p) => p.order_id === orderId) ?? null;
  }

  async upsertPayment(paymentInput) {
    const db = this._read();
    const now = new Date().toISOString();
    const idx = db.payments.findIndex((p) => p.order_id === paymentInput.order_id);

    if (idx >= 0) {
      const updated = {
        ...db.payments[idx],
        ...paymentInput,
        updated_at: now,
      };
      db.payments[idx] = updated;
      this._write(db);
      return updated;
    }

    const created = {
      id: db.payments.length + 1,
      payment_type: null,
      transaction_id: null,
      transaction_status: null,
      fraud_status: null,
      raw_notification: null,
      ...paymentInput,
      created_at: now,
      updated_at: now,
    };
    db.payments.push(created);
    this._write(db);
    return created;
  }

  async updateOrderStatus(orderId, status) {
    const db = this._read();
    const idx = db.orders.findIndex((o) => o.id === orderId);
    if (idx < 0) return null;

    const current = db.orders[idx];
    const updated = {
      ...current,
      status,
      stock_applied: status === 'PAID' ? true : Boolean(current.stock_applied),
      updated_at: new Date().toISOString(),
    };
    db.orders[idx] = updated;
    this._write(db);
    return updated;
  }
}
