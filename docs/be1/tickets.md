# Tiket BE-1

## BE1-01 — Skema tabel & relasi
**Yang dikerjakan:** migrasi `profiles`, `categories`, `products`, `orders`, `order_items`, `payments` + FK, check constraint, index, trigger `updated_at`.
**AC:** `supabase db reset` sukses; semua FK dan check (`price >= 0`, `qty > 0`, enum status) aktif.
**File:** `supabase/migrations/20261128050047_schema.sql`

## BE1-02 — Profil otomatis & role
**Yang dikerjakan:** trigger `on_auth_user_created` → insert `profiles` (role `customer`); helper `public.is_admin()`; guard agar non-admin tidak bisa mengubah `role`.
**AC:** sign-up baru punya profile `customer`; customer yang update `role` ditolak.
**Blocked by:** BE1-01 · **File:** `20261128050047_schema.sql`

## BE1-03 — RLS/RBAC
**Yang dikerjakan:** enable RLS di semua tabel dan buat policy sesuai matriks di spec.
**AC:** customer A tidak bisa membaca order customer B; customer tidak bisa insert langsung ke `orders`; admin bisa membaca semua.
**Blocked by:** BE1-02 · **File:** `supabase/migrations/20261128050050_rls.sql`

## BE1-04 — RPC `create_order` (kalkulasi server)
**Yang dikerjakan:** fungsi `security definer` yang memvalidasi item, mengunci produk, menghitung total, lalu membuat order dan item-nya.
**AC:** total = Σ price DB × qty; produk nonaktif/stok kurang/qty ≤ 0 menghasilkan error; output sesuai kontrak.
**Blocked by:** BE1-03 · **File:** `supabase/migrations/20261128050256_create_order.sql` + `..._create_order_grants.sql`

## BE1-05 — Hook untuk BE-2 & realtime
**Yang dikerjakan:** `apply_paid_order(order_id)` (hanya service role) yang mengurangi stok secara idempotent; `orders` masuk publikasi realtime.
**AC:** panggilan ganda tidak mengurangi stok dua kali.
**Blocked by:** BE1-04 · **File:** `20261128050256_create_order.sql`

## BE1-06 — Seed & uji SQL
**Yang dikerjakan:** `supabase/seed.sql` (kategori + produk contoh) dan `supabase/tests/be1_test.sql`.
**Blocked by:** BE1-05
