create table if not exists public.prisma_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 60),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.prisma_profiles enable row level security;
grant select, insert, update on public.prisma_profiles to authenticated;
create policy "Prisma users read own profile" on public.prisma_profiles for select to authenticated using ((select auth.uid()) = id);
create policy "Prisma users insert own profile" on public.prisma_profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy "Prisma users update own profile" on public.prisma_profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create table if not exists public.prisma_user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  currency text not null default 'BRL' check (currency in ('BRL','USD','EUR','GBP','CAD','AUD')),
  monthly_budget numeric(12,2) not null default 0 check (monthly_budget >= 0),
  expense_categories jsonb not null default '["Alimentação","Moradia","Transporte","Educação","Saúde","Lazer","Outros"]'::jsonb check (jsonb_typeof(expense_categories) = 'array'),
  income_categories jsonb not null default '["Salário","Investimentos","Outros"]'::jsonb check (jsonb_typeof(income_categories) = 'array'),
  theme text not null default 'mista' check (theme in ('clara','escura','mista')),
  compact_mode boolean not null default false,
  weekly_study_goal_hours smallint not null default 5 check (weekly_study_goal_hours between 1 and 100),
  study_session_minutes smallint not null default 25 check (study_session_minutes between 5 and 240),
  study_subjects jsonb not null default '[]'::jsonb check (jsonb_typeof(study_subjects) = 'array'),
  weekly_plan jsonb not null default '[]'::jsonb check (jsonb_typeof(weekly_plan) = 'array'),
  reminders jsonb not null default '{"tasks":true,"budget":true,"bills":true,"browser":false,"daysAhead":2}'::jsonb check (jsonb_typeof(reminders) = 'object'),
  ai_preferences jsonb not null default '{"personalizeSuggestions":false,"includeFinance":false,"includeStudies":false}'::jsonb check (jsonb_typeof(ai_preferences) = 'object'),
  updated_at timestamptz not null default now()
);
alter table public.prisma_user_settings enable row level security;
grant select, insert, update on public.prisma_user_settings to authenticated;
create policy "Prisma users read own settings" on public.prisma_user_settings for select to authenticated using ((select auth.uid()) = user_id);
create policy "Prisma users insert own settings" on public.prisma_user_settings for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Prisma users update own settings" on public.prisma_user_settings for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

alter table public.prisma_study_tasks add column if not exists estimated_minutes integer not null default 25;
alter table public.prisma_study_tasks add column if not exists completed_at timestamptz;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'prisma_study_tasks_estimated_minutes_check') then
    alter table public.prisma_study_tasks add constraint prisma_study_tasks_estimated_minutes_check check (estimated_minutes between 5 and 600);
  end if;
end $$;

create table if not exists public.prisma_bill_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 100),
  amount numeric(12,2) not null check (amount > 0),
  due_date date not null,
  paid boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.prisma_bill_reminders enable row level security;
grant select, insert, update, delete on public.prisma_bill_reminders to authenticated;
create policy "Prisma users read own bill reminders" on public.prisma_bill_reminders for select to authenticated using ((select auth.uid()) = user_id);
create policy "Prisma users insert own bill reminders" on public.prisma_bill_reminders for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Prisma users update own bill reminders" on public.prisma_bill_reminders for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Prisma users delete own bill reminders" on public.prisma_bill_reminders for delete to authenticated using ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('prisma-avatars', 'prisma-avatars', false, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
create policy "Prisma users read own avatar" on storage.objects for select to authenticated
using (bucket_id = 'prisma-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Prisma users upload own avatar" on storage.objects for insert to authenticated
with check (bucket_id = 'prisma-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Prisma users update own avatar" on storage.objects for update to authenticated
using (bucket_id = 'prisma-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'prisma-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Prisma users delete own avatar" on storage.objects for delete to authenticated
using (bucket_id = 'prisma-avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);