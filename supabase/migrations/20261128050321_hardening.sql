-- Security advisor fixes
alter function public.set_updated_at() set search_path = '';

-- trigger-only functions: not callable via RPC (triggers don't need EXECUTE)
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.guard_profile_role() from public, anon, authenticated;

-- is_admin is needed by RLS policies for signed-in users only
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
