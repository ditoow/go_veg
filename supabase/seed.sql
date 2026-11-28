insert into public.categories (id, name, slug) values
  ('11111111-1111-1111-1111-111111111111', 'Sayur', 'sayur'),
  ('22222222-2222-2222-2222-222222222222', 'Buah', 'buah');

insert into public.products (category_id, name, description, price, stock, image_url) values
  ('11111111-1111-1111-1111-111111111111', 'Bayam Segar', 'Bayam hijau 250g', 5000, 100, null),
  ('11111111-1111-1111-1111-111111111111', 'Brokoli', 'Brokoli 500g', 15000, 50, null),
  ('11111111-1111-1111-1111-111111111111', 'Wortel', 'Wortel 1kg', 12000, 80, null),
  ('22222222-2222-2222-2222-222222222222', 'Apel Fuji', 'Apel 1kg', 35000, 40, null),
  ('22222222-2222-2222-2222-222222222222', 'Pisang Cavendish', 'Pisang 1 sisir', 25000, 30, null);
