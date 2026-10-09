-- Ejecutar completo en Supabase > SQL Editor

create table public.restaurants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  zone text,
  cuisine text,
  url text,
  g numeric(2,1) check (g between 0 and 5),
  status text not null default 'p' check (status in ('p','v')),
  notes text,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null
);

create table public.ratings (
  restaurant_id uuid not null references public.restaurants on delete cascade,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  stars int not null check (stars between 1 and 5),
  primary key (restaurant_id, user_id)
);

alter table public.restaurants enable row level security;
alter table public.profiles enable row level security;
alter table public.ratings enable row level security;

-- Solo usuarios con sesión iniciada pueden leer/escribir restaurantes
create policy "restaurants_all" on public.restaurants
  for all to authenticated using (true) with check (true);

-- Perfiles: todos leen, cada uno edita el suyo
create policy "profiles_read" on public.profiles
  for select to authenticated using (true);
create policy "profiles_insert" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "profiles_update" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Evaluaciones: todos leen, cada uno modifica solo las suyas
create policy "ratings_read" on public.ratings
  for select to authenticated using (true);
create policy "ratings_insert" on public.ratings
  for insert to authenticated with check (user_id = auth.uid());
create policy "ratings_update" on public.ratings
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ratings_delete" on public.ratings
  for delete to authenticated using (user_id = auth.uid());

-- Actualización en vivo entre ambos
alter publication supabase_realtime add table public.restaurants, public.ratings;
