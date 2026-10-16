-- Prisma — Finanças & Estudos
-- Execute este arquivo no SQL Editor do Supabase.
-- Todas as tabelas têm RLS habilitado e cada usuário só acessa os próprios registros.

create table if not exists public.prisma_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('income', 'expense')),
  amount numeric(12,2) not null check (amount > 0),
  category text not null default 'Outros',
  transaction_date date not null default current_date,
  description text not null check (char_length(trim(description)) between 1 and 100),
  created_at timestamptz not null default now()
);

create table if not exists public.prisma_study_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  subject text not null check (char_length(trim(subject)) between 1 and 70),
  due_date date,
  notes text not null default '' check (char_length(notes) <= 300),
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists prisma_transactions_user_date_idx
  on public.prisma_transactions (user_id, transaction_date desc);
create index if not exists prisma_study_tasks_user_created_idx
  on public.prisma_study_tasks (user_id, created_at desc);

alter table public.prisma_transactions enable row level security;
alter table public.prisma_study_tasks enable row level security;

drop policy if exists "Users manage their own transactions" on public.prisma_transactions;
create policy "Users manage their own transactions"
  on public.prisma_transactions
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users manage their own study tasks" on public.prisma_study_tasks;
create policy "Users manage their own study tasks"
  on public.prisma_study_tasks
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update, delete on public.prisma_transactions to authenticated;
grant select, insert, update, delete on public.prisma_study_tasks to authenticated;
