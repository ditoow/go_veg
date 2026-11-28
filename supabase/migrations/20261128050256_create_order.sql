-- BE1-04 / BE1-05: server-side order creation & hook for BE-2

create or replace function public.create_order(
  p_items             jsonb,
  p_shipping_address  text default null,
  p_latitude          double precision default null,
  p_longitude         double precision default null
)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_user      uuid := auth.uid();
  v_order_id  text;
  v_total     integer := 0;
  v_line      record;
  v_items     jsonb;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'items must be a non-empty array' using errcode = '22023';
  end if;

  -- normalize: merge duplicate product_ids
  select coalesce(jsonb_agg(jsonb_build_object('product_id', product_id, 'qty', qty)), '[]'::jsonb)
  into v_items
  from (
    select (i ->> 'product_id')::uuid as product_id, sum((i ->> 'qty')::integer)::integer as qty
    from jsonb_array_elements(p_items) i
    group by 1
  ) t;

  if exists (
    select 1 from jsonb_to_recordset(v_items) as it(product_id uuid, qty integer)
    where it.product_id is null or it.qty is null or it.qty <= 0
  ) then
    raise exception 'invalid product_id or qty' using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_to_recordset(v_items) as it(product_id uuid, qty integer)
    where not exists (select 1 from public.products p where p.id = it.product_id)
  ) then
    raise exception 'product not found' using errcode = '22023';
  end if;

  -- lock products, validate, compute total from DB price
  for v_line in
    select it.product_id, it.qty, p.name, p.price, p.stock, p.is_active
    from jsonb_to_recordset(v_items) as it(product_id uuid, qty integer)
    join public.products p on p.id = it.product_id
    order by it.product_id
    for update of p
  loop
    if not v_line.is_active then
      raise exception 'product % not available', v_line.product_id using errcode = '22023';
    end if;
    if v_line.stock < v_line.qty then
      raise exception 'insufficient stock for %', v_line.name using errcode = '22023';
    end if;
    v_total := v_total + v_line.price * v_line.qty;
  end loop;

  if v_total <= 0 then
    raise exception 'order total must be positive' using errcode = '22023';
  end if;

  -- unique id ORD-YYYYMMDD-XXXX
  loop
    v_order_id := 'ORD-' || to_char(now() at time zone 'Asia/Jakarta', 'YYYYMMDD') || '-'
                  || upper(substr(md5(gen_random_uuid()::text), 1, 4));
    exit when not exists (select 1 from public.orders where id = v_order_id);
  end loop;

  insert into public.orders (id, user_id, gross_amount, shipping_address, latitude, longitude)
  values (v_order_id, v_user, v_total, p_shipping_address, p_latitude, p_longitude);

  insert into public.order_items (order_id, product_id, product_name, price, qty, subtotal)
  select v_order_id, p.id, p.name, p.price, it.qty, p.price * it.qty
  from jsonb_to_recordset(v_items) as it(product_id uuid, qty integer)
  join public.products p on p.id = it.product_id;

  return jsonb_build_object('order_id', v_order_id, 'gross_amount', v_total, 'status', 'PENDING');
end;
$$;


-- Called by BE-2 (service role) after a successful payment. Idempotent.
create or replace function public.apply_paid_order(p_order_id text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.orders set status = 'PAID', stock_applied = true
  where id = p_order_id and not stock_applied;

  if found then
    update public.products p
    set stock = greatest(p.stock - oi.qty, 0)
    from public.order_items oi
    where oi.order_id = p_order_id and oi.product_id = p.id;
  end if;
end;
$$;


-- realtime for FE-2 order tracking
alter publication supabase_realtime add table public.orders;
