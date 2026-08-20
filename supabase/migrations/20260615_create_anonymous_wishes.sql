-- Anonymous community wishes table.
-- Anyone can read. Writes are accepted only through the validated Edge
-- Function, which inserts with the service role.
create table if not exists public.anonymous_wishes (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  transcript text not null check (length(transcript) > 0 and length(transcript) <= 500),
  created_at timestamptz not null default now()
);

create index if not exists anonymous_wishes_created_at_idx
  on public.anonymous_wishes (created_at desc);

alter table public.anonymous_wishes enable row level security;

-- Drop existing policies so this script is idempotent.
drop policy if exists "anon can read anonymous_wishes" on public.anonymous_wishes;
drop policy if exists "anon can insert anonymous_wishes" on public.anonymous_wishes;
drop policy if exists "anon can delete anonymous_wishes" on public.anonymous_wishes;

-- Public read (the whole point of the feature).
create policy "anon can read anonymous_wishes"
  on public.anonymous_wishes
  for select
  to anon, authenticated
  using (true);

-- No inserts, updates or deletes from clients. New wishes are validated by
-- the Edge Function and inserted with the service role.
