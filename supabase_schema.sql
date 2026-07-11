-- 街歩きログ(Supabase版) 初期テーブル作成スクリプト
-- Supabaseの SQL Editor に貼り付けて実行してください。

-- 記録(スポット)
create table spots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  number integer not null,
  taken_at timestamptz not null,
  lat double precision,
  lng double precision,
  photo text,
  memo text,
  created_at timestamptz not null default now()
);

-- 散歩ルート
create table walks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distance double precision not null,
  path jsonb not null, -- [{lat, lng, t}, ...]
  created_at timestamptz not null default now()
);

-- アルバム
create table albums (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) default auth.uid(),
  title text not null,
  created_at timestamptz not null default now()
);

-- アルバムに入っている記録(どのアルバムにどの記録が含まれるか)
create table album_spots (
  album_id uuid not null references albums(id) on delete cascade,
  spot_id uuid not null references spots(id) on delete cascade,
  primary key (album_id, spot_id)
);

-- ---- Row Level Security(自分のデータしか見えない・操作できないようにする) ----
alter table spots enable row level security;
alter table walks enable row level security;
alter table albums enable row level security;
alter table album_spots enable row level security;

create policy "spots_own_data" on spots
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "walks_own_data" on walks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "albums_own_data" on albums
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- album_spotsは自分が所有するアルバムに対してのみ操作できるようにする
create policy "album_spots_own_data" on album_spots
  for all using (
    exists (select 1 from albums where albums.id = album_spots.album_id and albums.user_id = auth.uid())
  ) with check (
    exists (select 1 from albums where albums.id = album_spots.album_id and albums.user_id = auth.uid())
  );
