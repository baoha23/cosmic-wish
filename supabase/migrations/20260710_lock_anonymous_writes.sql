-- Existing projects may already have the original public insert policy.
-- Remove it so writes must pass through the validated Edge Function.
drop policy if exists "anon can insert anonymous_wishes"
  on public.anonymous_wishes;

-- Older deployments may contain the removed analytics table. Keep it
-- service-only rather than leaving its historical anon insert policy open.
do $$
begin
  if to_regclass('public.wishes') is not null then
    execute 'drop policy if exists "anon can insert wishes" on public.wishes';
  end if;
end
$$;
