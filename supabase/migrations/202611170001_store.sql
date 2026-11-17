begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table private.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table private.admin_users enable row level security;
revoke all on private.admin_users from public, anon, authenticated;

grant usage on schema private to anon, authenticated;
create or replace function private.is_admin() returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from private.admin_users where user_id = (select auth.uid()) and active); $$;
revoke all on function private.is_admin() from public;
grant execute on function private.is_admin() to anon, authenticated;
create or replace function public.is_admin() returns boolean
language sql stable security invoker set search_path = ''
as $$ select private.is_admin(); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

create table public.disciplines (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check(length(btrim(name)) between 2 and 120),
  active boolean not null default true
);
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check(length(btrim(name)) between 2 and 120),
  active boolean not null default true
);
create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check(length(btrim(name)) between 3 and 160),
  description text not null check(length(btrim(description)) between 20 and 10000),
  course text not null default 'Odontologia' check(length(btrim(course)) between 2 and 120),
  discipline_id uuid not null references public.disciplines(id) on delete restrict,
  category_id uuid not null references public.categories(id) on delete restrict,
  price_cents integer not null check(price_cents between 100 and 1000000),
  cover_path text check(cover_path is null or cover_path ~ '^[a-f0-9-]+\.(jpg|png|webp)$'),
  preview_paths text[] not null default '{}' check(cardinality(preview_paths)<=6),
  contents text[] not null check(cardinality(contents) between 1 and 100),
  checkout_url text not null check(length(checkout_url)<=2000 and checkout_url ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+(/[^[:space:]]*)?$'),
  status text not null default 'draft' check(status in ('draft','published','inactive')),
  featured boolean not null default false,
  is_new boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_catalog on public.products(status, created_at desc);
create index products_discipline on public.products(discipline_id);
create index products_category on public.products(category_id);

-- Never put original file paths in products or a public view.
create table public.product_files (
  product_id uuid primary key references public.products(id) on delete cascade,
  pdf_path text not null check(pdf_path ~ '^[a-f0-9-]+\.pdf$'),
  updated_at timestamptz not null default now()
);
create table public.store_settings (
  id integer primary key check(id=1),
  brand_name text not null default '' check(length(brand_name)<=120),
  logo_path text check(logo_path is null or logo_path ~ '^[a-f0-9-]+\.(jpg|png|webp)$'),
  contact_email text not null default '' check(length(contact_email)<=254),
  instagram_url text not null default '' check(length(instagram_url)<=2000 and (instagram_url='' or instagram_url ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+(/[^[:space:]]*)?$')),
  whatsapp_url text not null default '' check(length(whatsapp_url)<=2000 and (whatsapp_url='' or whatsapp_url ~ '^https://[^/@[:space:]]+\.[^/@[:space:]]+(/[^[:space:]]*)?$')),
  about text not null default '' check(length(about)<=1000)
);

alter table public.products enable row level security;
alter table public.product_files enable row level security;
alter table public.disciplines enable row level security;
alter table public.categories enable row level security;
alter table public.store_settings enable row level security;
revoke all on public.products, public.product_files, public.disciplines, public.categories, public.store_settings from public, anon, authenticated;
grant select on public.products, public.disciplines, public.categories, public.store_settings to anon, authenticated;
grant insert, update, delete on public.products, public.disciplines, public.categories to authenticated;
grant select, insert, update, delete on public.product_files to authenticated;
grant update on public.store_settings to authenticated;

create policy disciplines_public on public.disciplines for select to anon,authenticated using(active or (select public.is_admin()));
create policy disciplines_admin on public.disciplines for all to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy categories_public on public.categories for select to anon,authenticated using(active or (select public.is_admin()));
create policy categories_admin on public.categories for all to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy products_public on public.products for select to anon,authenticated using(
  (status='published' and exists(select 1 from public.disciplines d where d.id=discipline_id and d.active)
    and exists(select 1 from public.categories c where c.id=category_id and c.active))
  or (select public.is_admin())
);
create policy products_admin on public.products for all to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy files_admin on public.product_files for all to authenticated using((select public.is_admin())) with check((select public.is_admin()));
create policy settings_read on public.store_settings for select to anon,authenticated using(true);
create policy settings_admin on public.store_settings for update to authenticated using((select public.is_admin())) with check((select public.is_admin()));

create or replace function private.validate_product() returns trigger
language plpgsql set search_path='' as $$
declare item text;
begin
  new.updated_at=now();
  foreach item in array new.preview_paths loop
    if item is null or item !~ '^[a-f0-9-]+\.(jpg|png|webp)$' then raise exception 'Invalid public preview'; end if;
  end loop;
  foreach item in array new.contents loop
    if item is null or length(btrim(item)) not between 1 and 300 then raise exception 'Invalid content item'; end if;
  end loop;
  if new.status='published' then
    if new.cover_path is null or not exists(select 1 from public.product_files where product_id=new.id) then raise exception 'Cover and private PDF required'; end if;
    if not exists(select 1 from public.disciplines where id=new.discipline_id and active) or not exists(select 1 from public.categories where id=new.category_id and active) then raise exception 'Active taxonomy required'; end if;
  end if;
  return new;
end; $$;
create trigger validate_product before insert or update on public.products for each row execute function private.validate_product();

create or replace function private.guard_taxonomy() returns trigger
language plpgsql set search_path='' as $$
begin
  if old.active and not new.active then
    if (tg_table_name='disciplines' and exists(select 1 from public.products where discipline_id=old.id and status='published'))
      or (tg_table_name='categories' and exists(select 1 from public.products where category_id=old.id and status='published')) then
      raise exception 'Unpublish linked products first';
    end if;
  end if;
  return new;
end; $$;
create trigger guard_disciplines before update on public.disciplines for each row execute function private.guard_taxonomy();
create trigger guard_categories before update on public.categories for each row execute function private.guard_taxonomy();

create or replace function public.save_product(p_id uuid, p_product jsonb, p_pdf_path text default null)
returns uuid language plpgsql security invoker set search_path='' as $$
declare requested_status text := p_product->>'status';
begin
  if not public.is_admin() then raise exception 'Forbidden' using errcode='42501'; end if;
  if requested_status is null or requested_status not in ('draft','published','inactive') then raise exception 'Invalid status'; end if;
  insert into public.products(id,name,description,course,discipline_id,category_id,price_cents,cover_path,preview_paths,contents,checkout_url,status,featured,is_new)
  values(p_id,p_product->>'name',p_product->>'description',p_product->>'course',(p_product->>'discipline_id')::uuid,(p_product->>'category_id')::uuid,(p_product->>'price_cents')::integer,p_product->>'cover_path',array(select jsonb_array_elements_text(p_product->'preview_paths')),array(select jsonb_array_elements_text(p_product->'contents')),p_product->>'checkout_url','draft',(p_product->>'featured')::boolean,(p_product->>'is_new')::boolean)
  on conflict(id) do update set name=excluded.name,description=excluded.description,course=excluded.course,discipline_id=excluded.discipline_id,category_id=excluded.category_id,price_cents=excluded.price_cents,cover_path=excluded.cover_path,preview_paths=excluded.preview_paths,contents=excluded.contents,checkout_url=excluded.checkout_url,status='draft',featured=excluded.featured,is_new=excluded.is_new;
  if p_pdf_path is not null then
    insert into public.product_files(product_id,pdf_path) values(p_id,p_pdf_path) on conflict(product_id) do update set pdf_path=excluded.pdf_path,updated_at=now();
  end if;
  update public.products set status=requested_status where id=p_id;
  return p_id;
end; $$;
revoke all on function public.save_product(uuid,jsonb,text) from public, anon;
grant execute on function public.save_product(uuid,jsonb,text) to authenticated;

insert into public.disciplines(name) values
('Anatomia Humana'),('Anatomia Dental'),('Histologia'),('Embriologia'),('Fisiologia'),('Bioquímica'),('Microbiologia'),('Farmacologia'),('Patologia'),('Materiais Dentários'),('Dentística'),('Periodontia'),('Endodontia'),('Cirurgia Bucomaxilofacial'),('Prótese Dentária'),('Ortodontia'),('Radiologia Odontológica');
insert into public.categories(name) values('Resumos em PDF');
insert into public.store_settings(id,brand_name,about) values(1,'Dentwise','Materiais de apoio para tornar sua rotina de estudos mais organizada.');

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('public-media','public-media',true,5242880,array['image/jpeg','image/png','image/webp']),
('original-pdfs','original-pdfs',false,52428800,array['application/pdf']);
create policy media_read on storage.objects for select to anon,authenticated using(bucket_id='public-media');
create policy media_admin on storage.objects for all to authenticated using(bucket_id in ('public-media','original-pdfs') and (select public.is_admin())) with check(bucket_id in ('public-media','original-pdfs') and (select public.is_admin()));

-- Future webhook inbox. No public API, no purchase processing in this release.
create table private.checkout_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  external_event_id text not null,
  received_at timestamptz not null default now(),
  payload jsonb not null,
  processed_at timestamptz,
  unique(provider,external_event_id)
);
alter table private.checkout_events enable row level security;
revoke all on private.checkout_events from public, anon, authenticated;
commit;
