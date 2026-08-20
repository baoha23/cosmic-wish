-- Published APK releases for in-app self-update. Anyone with the
-- anon key may read the newest row (the app checks for updates);
-- writes are service-role only (CI release workflow), like
-- anonymous_wishes.
create table if not exists public.app_releases (
  version_code int primary key,
  version_name text not null check (version_name <> ''),
  apk_url text not null check (apk_url <> ''),
  notes text,
  created_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;

-- Drop existing policies so this script is idempotent.
drop policy if exists "public read app_releases" on public.app_releases;

-- Public read: the update check runs with the anon key.
create policy "public read app_releases"
  on public.app_releases
  for select
  to anon, authenticated
  using (true);

-- No insert/update/delete policies: only the service role (CI) writes.
