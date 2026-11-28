# Spec BE-1 — Skema Supabase, RLS/RBAC, & Validasi Order

Owner: BE-1 · Branch: `be-1` · Status: draft

## Tujuan
1. Skema PostgreSQL untuk `profiles`, `categories`, `products`, `orders`, `order_items`, `payments`.
2. RBAC di level database lewat RLS (`customer` vs `admin`).
3. Order hanya bisa dibuat lewat RPC `create_order`, yang menghitung `gross_amount` di server dari harga di DB.

## Di luar cakupan (milik BE-2)
Edge Function Midtrans, webhook, verifikasi signature, mapping status Midtrans → status aplikasi.
BE-1 hanya menyediakan tabel `payments` dan kolom status yang ditulis BE-2 memakai service role.

## Model Data

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `profiles` | `id` (= `auth.users.id`), `full_name`, `phone`, `role` (`customer`/`admin`) | Dibuat otomatis oleh trigger saat user sign-up. User tidak bisa mengubah `role` sendiri. |
| `categories` | `id`, `name`, `slug` | Dibutuhkan katalog FE-1. |
| `products` | `id`, `category_id`, `name`, `description`, `price` (int Rupiah), `stock`, `image_url`, `is_active` | |
| `orders` | `id` (`ORD-YYYYMMDD-XXXX`), `user_id`, `gross_amount` (int), `status`, `shipping_address`, `latitude`, `longitude` | `status` ∈ `PENDING, PAID, FAILED, EXPIRED, CANCELLED`. |
| `order_items` | `order_id`, `product_id`, `product_name`, `price`, `qty`, `subtotal` | Snapshot harga & nama saat order dibuat. |
| `payments` | `order_id` (unique), `snap_token`, `redirect_url`, `transaction_id`, `payment_type`, `transaction_status`, `fraud_status`, `gross_amount`, `raw_notification` (jsonb) | Ditulis oleh BE-2 (service role). |

## Matriks RLS

| Tabel | customer | admin | anon |
|---|---|---|---|
| profiles | read/update milik sendiri (kecuali `role`) | read/update semua | – |
| categories, products | read (produk hanya `is_active`) | full CRUD | read |
| orders | read milik sendiri; insert **hanya via RPC** | read semua, update status | – |
| order_items | read milik order sendiri | read semua | – |
| payments | read milik order sendiri | read semua | – |

Penulisan `payments` dan update status dari webhook memakai service role (bypass RLS).

## Kontrak RPC `create_order`

```
supabase.rpc('create_order', params: {
  'p_items': [{'product_id': '<uuid>', 'qty': 2}, ...],
  'p_shipping_address': 'Jl. ...',   // opsional
  'p_latitude': -6.2, 'p_longitude': 106.8  // opsional
})
→ { "order_id": "ORD-20261128-A1B2", "gross_amount": 45000, "status": "PENDING" }
```

Validasi: user wajib login; item tidak boleh kosong; `qty` > 0; `product_id` duplikat digabung; produk ada & `is_active`; stok cukup.
Harga diambil dari `products.price` (input harga dari client diabaikan). Dijalankan dalam satu transaksi dengan `FOR UPDATE` pada baris produk.

## Keputusan & asumsi
- **Stok tidak dikurangi saat order dibuat**, hanya divalidasi. Pengurangan stok saat `PAID` ditangani BE-2 lewat `public.apply_paid_order(order_id)` yang disediakan BE-1 (khusus service role).
- Admin pertama di-promote manual via SQL (`update profiles set role='admin' where id=...`).
- `orders` masuk publikasi `supabase_realtime` supaya FE-2 bisa memantau status secara real-time.
- Ongkir belum dihitung (gross_amount = total item). Kalau nanti dipakai, tambahkan di RPC, bukan di client.
