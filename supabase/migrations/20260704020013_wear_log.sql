-- Per-wear history log, so an item can show a timeline of every time it was worn
-- (with an optional date + occasion), not just an aggregate wear_count.

create table tw_wear_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references tw_items(id) on delete cascade,
  worn_at date not null default current_date,
  occasion text,
  created_at timestamptz not null default now()
);

create index tw_wear_log_item_id_idx on tw_wear_log(item_id);
create index tw_wear_log_user_id_idx on tw_wear_log(user_id);

alter table tw_wear_log enable row level security;

create policy "own wear log" on tw_wear_log for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
