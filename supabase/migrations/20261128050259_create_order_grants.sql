-- BE1-04: execute grants for order functions
revoke all on function public.create_order(jsonb, text, double precision, double precision) from public, anon;
grant execute on function public.create_order(jsonb, text, double precision, double precision) to authenticated;
revoke all on function public.apply_paid_order(text) from public, anon, authenticated;
grant execute on function public.apply_paid_order(text) to service_role;
