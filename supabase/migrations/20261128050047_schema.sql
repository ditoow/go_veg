-- BE1-01 / BE1-02: schema, relations, profiles & roles

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- profiles ---------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  phone       text,
  role        text not null default 'customer' check (role in ('customer', 'admin')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'phone');
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Only admins (or service role / SQL editor, where auth.uid() is null) may change roles.
create or replace function public.guard_profile_role()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'only admin can change role' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger profiles_guard_role before update on public.profiles
  for each row execute function public.guard_profile_role();

-- catalog ----------------------------------------------------------------
create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  created_at  timestamptz not null default now()
);

create table public.products (
  id           uuid primary key default gen_random_uuid(),
  category_id  uuid references public.categories(id) on delete set null,
  name         text not null,
  description  text,
  price        integer not null check (price >= 0),
  stock        integer not null default 0 check (stock >= 0),
  image_url    text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index products_category_idx on public.products (category_id);
create trigger products_updated_at before update on public.products
  for each row execute function public.set_updated_at();

-- orders -----------------------------------------------------------------
create table public.orders (
  id                text primary key,
  user_id           uuid not null references public.profiles(id) on delete restrict,
  gross_amount      integer not null check (gross_amount > 0),
  status            text not null default 'PENDING'
                    check (status in ('PENDING', 'PAID', 'FAILED', 'EXPIRED', 'CANCELLED')),
  shipping_address  text,
  latitude          double precision,
  longitude         double precision,
  stock_applied     boolean not null default false,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index orders_user_idx on public.orders (user_id, created_at desc);
create trigger orders_updated_at before update on public.orders
  for each row execute function public.set_updated_at();

create table public.order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      text not null references public.orders(id) on delete cascade,
  product_id    uuid not null references public.products(id) on delete restrict,
  product_name  text not null,
  price         integer not null check (price >= 0),
  qty           integer not null check (qty > 0),
  subtotal      integer not null check (subtotal >= 0),
  unique (order_id, product_id)
);

create index order_items_order_idx on public.order_items (order_id);

-- payments (written by BE-2 with service role) ---------------------------
create table public.payments (
  id                  uuid primary key default gen_random_uuid(),
  order_id            text not null unique references public.orders(id) on delete cascade,
  snap_token          text,
  redirect_url        text,
  transaction_id      text,
  payment_type        text,
  transaction_status  text,
  fraud_status        text,
  gross_amount        integer,
  raw_notification    jsonb,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create trigger payments_updated_at before update on public.payments
  for each row execute function public.set_updated_at();
