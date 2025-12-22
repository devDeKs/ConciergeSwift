-- INSTRUÇÕES PARA CONFIGURAR O SUPABASE
-- Execute estes comandos no SQL Editor do console do Supabase
-- https://supabase.com/dashboard/project/[YOUR_PROJECT]/sql

-- ============================================
-- 1. TABELA DE PERFIS
-- ============================================
create table if not exists profiles (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null unique,
  full_name text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Index para busca rápida por user_id
create index if not exists profiles_user_id_idx on profiles(user_id);

-- Habilitar RLS (Row Level Security) - OBRIGATÓRIO PARA SEGURANÇA
alter table profiles enable row level security;

-- Policies de segurança para profiles
-- Usuários só podem ver seu próprio perfil
create policy "Users can view own profile" 
  on profiles for select 
  using (auth.uid() = user_id);

-- Usuários só podem criar seu próprio perfil
create policy "Users can insert own profile" 
  on profiles for insert 
  with check (auth.uid() = user_id);

-- Usuários só podem atualizar seu próprio perfil
create policy "Users can update own profile" 
  on profiles for update 
  using (auth.uid() = user_id);

-- ============================================
-- 2. TABELA DE TRANSAÇÕES
-- ============================================
create table if not exists transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  description text not null,
  amount decimal(10,2) not null check (amount > 0),
  type text check (type in ('income', 'expense')) not null,
  category text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Index para busca rápida por user_id e data
create index if not exists transactions_user_id_idx on transactions(user_id);
create index if not exists transactions_created_at_idx on transactions(created_at desc);
create index if not exists transactions_user_date_idx on transactions(user_id, created_at desc);

-- Habilitar RLS (Row Level Security) - OBRIGATÓRIO PARA SEGURANÇA
alter table transactions enable row level security;

-- Policies de segurança para transactions
-- Usuários só podem ver suas próprias transações
create policy "Users can view own transactions" 
  on transactions for select 
  using (auth.uid() = user_id);

-- Usuários só podem criar suas próprias transações
create policy "Users can insert own transactions" 
  on transactions for insert 
  with check (auth.uid() = user_id);

-- Usuários só podem atualizar suas próprias transações
create policy "Users can update own transactions" 
  on transactions for update 
  using (auth.uid() = user_id);

-- Usuários só podem deletar suas próprias transações
create policy "Users can delete own transactions" 
  on transactions for delete 
  using (auth.uid() = user_id);

-- ============================================
-- 3. FUNÇÃO PARA CRIAR PERFIL AUTOMATICAMENTE
-- (Opcional - cria perfil quando usuário é criado)
-- ============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (user_id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', 'Usuário'));
  return new;
end;
$$ language plpgsql security definer;

-- Trigger para criar perfil automaticamente (opcional)
-- drop trigger if exists on_auth_user_created on auth.users;
-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute procedure public.handle_new_user();

-- ============================================
-- VERIFICAÇÃO DE SEGURANÇA
-- ============================================
-- Execute após criar as tabelas para verificar que RLS está ativo:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';
-- Todas as tabelas devem ter rowsecurity = true
