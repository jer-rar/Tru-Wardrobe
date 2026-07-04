-- Tru Wardrobe initial schema

create extension if not exists "pgcrypto";

-- Sections (e.g. "Closet", "Shoe Rack", "Dresser")
create table tw_sections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  icon text,
  color text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- Clothing items
create table tw_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  section_id uuid references tw_sections(id) on delete set null,
  name text not null,
  category text,
  color_primary text,
  color_secondary text,
  pattern text,
  size text,
  brand text,
  season text,
  formality text,
  image_url text,
  thumbnail_url text,
  ai_tags jsonb,
  notes text,
  favorite boolean not null default false,
  wear_count int not null default 0,
  last_worn_at timestamptz,
  created_at timestamptz not null default now()
);

-- Saved/AI-suggested outfits
create table tw_outfits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text,
  item_ids uuid[] not null default '{}',
  ai_generated boolean not null default false,
  reasoning text,
  created_at timestamptz not null default now()
);

-- OTA update feed (mirrors TruBrief's trl_app_version)
create table tw_app_version (
  id uuid primary key default gen_random_uuid(),
  version_code int not null,
  version_name text not null,
  download_url text not null,
  release_notes text,
  force_update boolean not null default false,
  created_at timestamptz not null default now()
);

create index tw_items_user_id_idx on tw_items(user_id);
create index tw_items_section_id_idx on tw_items(section_id);
create index tw_sections_user_id_idx on tw_sections(user_id);
create index tw_outfits_user_id_idx on tw_outfits(user_id);
create index tw_app_version_version_code_idx on tw_app_version(version_code desc);

-- RLS
alter table tw_sections enable row level security;
alter table tw_items enable row level security;
alter table tw_outfits enable row level security;
alter table tw_app_version enable row level security;

create policy "own sections" on tw_sections for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own items" on tw_items for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own outfits" on tw_outfits for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- app_version is public read (every logged-in device needs to check for updates), no writes from the app
create policy "anyone can read app_version" on tw_app_version for select
  using (true);

-- Storage bucket for wardrobe photos
insert into storage.buckets (id, name, public)
values ('tw-wardrobe-images', 'tw-wardrobe-images', true)
on conflict (id) do nothing;

create policy "users manage their own wardrobe images"
  on storage.objects for all
  using (bucket_id = 'tw-wardrobe-images' and auth.uid()::text = (storage.foldername(name))[1])
  with check (bucket_id = 'tw-wardrobe-images' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "public read of wardrobe images"
  on storage.objects for select
  using (bucket_id = 'tw-wardrobe-images');
