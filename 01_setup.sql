-- =====================================================================
-- VNHN 3D Parts Library — Supabase setup (chạy 1 lần trong SQL Editor)
-- File: supabase/01_setup.sql
-- Idempotent: chạy lại không lỗi.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Bảng admin
-- ---------------------------------------------------------------------
create table if not exists public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security;

drop policy if exists admins_self_read on public.admins;
create policy admins_self_read on public.admins
  for select to authenticated
  using (user_id = auth.uid());
-- Không có policy INSERT/UPDATE/DELETE → chỉ thêm admin bằng SQL Editor.

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
grant execute on function public.is_admin() to anon, authenticated;

-- ---------------------------------------------------------------------
-- 2. Bảng models
-- ---------------------------------------------------------------------
create table if not exists public.models (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  category       text not null default 'other',
  maker          text,
  part_no        text,
  description    text,
  file_type      text not null,
  original_path  text not null,
  preview_path   text,
  thumb_path     text,
  file_size      integer not null,
  uploader_name  text not null,
  created_at     timestamptz not null default now(),
  is_hidden      boolean not null default false,
  download_count integer not null default 0,

  constraint models_name_len      check (char_length(btrim(name)) between 1 and 200),
  constraint models_uploader_len  check (char_length(btrim(uploader_name)) between 1 and 100),
  constraint models_category_fmt  check (category ~ '^[a-z0-9_]{1,40}$'),
  constraint models_maker_len     check (maker is null or char_length(maker) <= 100),
  constraint models_partno_len    check (part_no is null or char_length(part_no) <= 100),
  constraint models_desc_len      check (description is null or char_length(description) <= 4000),
  constraint models_file_type     check (file_type in ('html','glb','gltf','step','iges','stl','obj')),
  constraint models_file_size     check (file_size > 0 and file_size <= 20971520),
  -- đường dẫn phải nằm trong thư mục {id}/
  constraint models_orig_path     check (original_path like id::text || '/original.%'),
  constraint models_prev_path     check (preview_path is null or preview_path = id::text || '/preview.glb'),
  constraint models_thumb_path    check (thumb_path is null or thumb_path ~ ('^' || id::text || '/thumb\.(webp|png)$'))
);

create index if not exists models_created_idx  on public.models (created_at desc);
create index if not exists models_category_idx on public.models (category);
create index if not exists models_maker_idx    on public.models (lower(maker));

-- Trigger: anon không tự đặt được created_at / is_hidden / download_count
create or replace function public.models_before_insert()
returns trigger
language plpgsql
as $$
begin
  new.created_at     := now();
  new.download_count := 0;
  if not public.is_admin() then
    new.is_hidden := false;
  end if;
  new.name          := btrim(new.name);
  new.uploader_name := btrim(new.uploader_name);
  return new;
end;
$$;

drop trigger if exists trg_models_before_insert on public.models;
create trigger trg_models_before_insert
  before insert on public.models
  for each row execute function public.models_before_insert();

-- RLS
alter table public.models enable row level security;

drop policy if exists models_read   on public.models;
drop policy if exists models_insert on public.models;
drop policy if exists models_update on public.models;
drop policy if exists models_delete on public.models;

create policy models_read on public.models
  for select to anon, authenticated
  using (is_hidden = false or public.is_admin());

create policy models_insert on public.models
  for insert to anon, authenticated
  with check (true);  -- ràng buộc nằm ở constraint + trigger

create policy models_update on public.models
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy models_delete on public.models
  for delete to authenticated
  using (public.is_admin());

-- RPC tăng lượt tải (anon không có quyền UPDATE)
create or replace function public.increment_download(p_id uuid)
returns void
language sql security definer
set search_path = public
as $$
  update public.models
     set download_count = download_count + 1
   where id = p_id and is_hidden = false;
$$;
revoke all on function public.increment_download(uuid) from public;
grant execute on function public.increment_download(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. Storage bucket `models` (public read, 20 MB/file)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit)
values ('models', 'models', true, 20971520)
on conflict (id) do update
  set public = true, file_size_limit = 20971520;

drop policy if exists models_obj_insert       on storage.objects;
drop policy if exists models_obj_admin_select on storage.objects;
drop policy if exists models_obj_admin_update on storage.objects;
drop policy if exists models_obj_admin_delete on storage.objects;

-- Anon chỉ được tạo file mới đúng cấu trúc: {uuid}/original.ext | preview.glb | thumb.webp/png
-- (không có policy UPDATE cho anon → không ghi đè được file đã có)
create policy models_obj_insert on storage.objects
  for insert to anon, authenticated
  with check (
    bucket_id = 'models'
    and array_length(storage.foldername(name), 1) = 1
    and (storage.foldername(name))[1] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and storage.filename(name) ~ '^(original\.(html|glb|gltf|step|stp|iges|igs|stl|obj)|preview\.glb|thumb\.(webp|png))$'
  );

-- Admin: liệt kê / sửa / xóa file
create policy models_obj_admin_select on storage.objects
  for select to authenticated
  using (bucket_id = 'models' and public.is_admin());

create policy models_obj_admin_update on storage.objects
  for update to authenticated
  using (bucket_id = 'models' and public.is_admin())
  with check (bucket_id = 'models' and public.is_admin());

create policy models_obj_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'models' and public.is_admin());

-- ---------------------------------------------------------------------
-- 4. Thêm admin (chạy SAU khi đã tạo user trong Authentication > Users)
-- ---------------------------------------------------------------------
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'EMAIL_ADMIN@domain.com'
-- on conflict do nothing;
