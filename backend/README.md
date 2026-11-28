# GoVeg BE-2 — Midtrans Payment, Webhook & Status Sync

Service backend **BE-2** yang dirancang **local-first** (langsung bisa dijalankan dan dites di lokal sebelum BE-1 push skema Supabase) dan **Supabase-ready** (tinggal ganti variabel `.env` saat BE-1 sudah siap).

Format response seluruh endpoint mengikuti envelope `ApiResponse<T>` milik FE (`lib/model/response/api_response.dart`):

```json
{
  "success": true,
  "message": "...",
  "data": { ... }
}
```

## 1. Menjalankan Tes Lokal (Tanpa BE-1 & Tanpa Key Midtrans)

1. Salin `.env.example` menjadi `.env`:
   ```powershell
   Copy-Item backend\.env.example backend\.env
   ```
   Default di `.env.example` sudah memakai `STORAGE_MODE=local` dan `MIDTRANS_MODE=mock`.

2. Jalankan unit/integration test bawaan Node.js:
   ```powershell
   cd backend
   npm test
   ```

3. Jalankan server lokal:
   ```powershell
   cd backend
   npm start
   ```
   Server berjalan di `http://localhost:8080`.

## 2. Alur Tes Manual dengan PowerShell / curl

1. **Cek server & order seed (`ORD-20261126-0001`):**
   ```powershell
   Invoke-RestMethod http://localhost:8080/api/health
   Invoke-RestMethod http://localhost:8080/api/dev/orders
   ```

2. **Buat order lokal baru (simulasi kerja BE-1):**
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/dev/orders -ContentType "application/json" -Body '{"gross_amount": 45000}'
   ```

3. **Inisiasi pembayaran Midtrans (`POST /api/payments/create`):**
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/payments/create -ContentType "application/json" -Body '{"order_id": "ORD-20261126-0001"}'
   ```

4. **Simulasikan webhook Midtrans (`settlement` -> `PAID`):**
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/dev/simulate-webhook -ContentType "application/json" -Body '{"order_id": "ORD-20261126-0001", "transaction_status": "settlement", "payment_type": "qris"}'
   ```

5. **Cek status transaksi (`GET /api/payments/:orderId/status`):**
   ```powershell
   Invoke-RestMethod http://localhost:8080/api/payments/ORD-20261126-0001/status
   ```

## 3. Switch ke Midtrans Sandbox Asli & Supabase BE-1

Skema BE-1 sudah ter-merge di `supabase/migrations/` dan `SUPABASE_URL` sudah diisi di `.env.example` (`https://tatcjwgbswpclkarnzwh.supabase.co`). Anda tinggal:

1. Ubah `backend/.env`:
   ```env
   STORAGE_MODE=supabase
   MIDTRANS_MODE=sandbox
   MIDTRANS_SERVER_KEY=SB-Mid-server-...
   SUPABASE_URL=https://tatcjwgbswpclkarnzwh.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=eyJ...
   ```
2. `src/store/supabaseStore.js` sudah disesuaikan langsung ke tabel `public.orders` & `public.payments` milik BE-1 (`transaction_status`, `fraud_status`) dan otomatis memanggil RPC `public.apply_paid_order(p_order_id)` saat status berubah menjadi `PAID`.
3. Untuk menguji webhook Midtrans Sandbox ke server lokal Anda, expose port `8080` (mis. via ngrok/Cloudflare Tunnel) lalu daftarkan `https://<tunnel-url>/api/payments/webhook` sebagai **Payment Notification URL** di Midtrans Sandbox Dashboard.
