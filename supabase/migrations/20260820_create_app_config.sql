-- Singleton AI provider config row. Only the service role (Edge
-- Functions) may read or write it: RLS is enabled with no policies,
-- so anon/authenticated get nothing. The admin Edge Function edits
-- this row; generate-wish reads it per request with an env fallback.
create table if not exists public.app_config (
  id int primary key default 1 check (id = 1),
  base_url text not null check (base_url <> ''),
  model text not null check (model <> ''),
  api_key text,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;

-- Drop any future accidental policy grants. Keep this table locked to
-- the service role.
drop policy if exists "any access to app_config" on public.app_config;
