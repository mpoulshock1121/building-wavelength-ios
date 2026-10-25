-- Fails (RAISE) when a table that holds user data has row-level security off or
-- has no policy. Edit the table list for your app. Run with:
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f scripts/ci/check-rls.sql
do $$
declare
  t text;
  tables text[] := array['profiles'];   -- EDIT: every table with user data
  rls_on boolean;
  policies int;
begin
  foreach t in array tables loop
    select relrowsecurity into rls_on
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relname = t;
    if rls_on is null then
      raise exception 'RLS check: table public.% does not exist (fix the list)', t;
    end if;
    if not rls_on then
      raise exception 'RLS regression: public.% has row-level security OFF', t;
    end if;
    select count(*) into policies from pg_policies where schemaname = 'public' and tablename = t;
    if policies = 0 then
      raise exception 'RLS regression: public.% has RLS on but no policy', t;
    end if;
    raise notice 'ok: % (% policies)', t, policies;
  end loop;
end $$;
