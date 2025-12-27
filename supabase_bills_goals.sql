-- ============================================
-- SALDO LIVRE REAL - ADDITIONAL TABLES
-- Execute after supabase_setup.sql
-- ============================================

-- ============================================
-- 1. SCHEDULED BILLS (Contas a Pagar)
-- ============================================
create table if not exists scheduled_bills (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  amount decimal(10,2) not null check (amount > 0),
  due_day integer not null check (due_day >= 1 and due_day <= 31),
  category text not null default 'Contas',
  is_recurring boolean default true,
  is_paid boolean default false,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for scheduled_bills
create index if not exists scheduled_bills_user_id_idx on scheduled_bills(user_id);
create index if not exists scheduled_bills_due_day_idx on scheduled_bills(due_day);

-- Enable RLS
alter table scheduled_bills enable row level security;

-- Policies for scheduled_bills
create policy "Users can view own bills" 
  on scheduled_bills for select 
  using (auth.uid() = user_id);

create policy "Users can insert own bills" 
  on scheduled_bills for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own bills" 
  on scheduled_bills for update 
  using (auth.uid() = user_id);

create policy "Users can delete own bills" 
  on scheduled_bills for delete 
  using (auth.uid() = user_id);

-- ============================================
-- 2. CREDIT CARDS (Cartões de Crédito)
-- ============================================
create table if not exists credit_cards (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  card_limit decimal(10,2) not null default 0,
  current_invoice decimal(10,2) not null default 0,
  closing_day integer not null check (closing_day >= 1 and closing_day <= 31),
  due_day integer not null check (due_day >= 1 and due_day <= 31),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for credit_cards
create index if not exists credit_cards_user_id_idx on credit_cards(user_id);

-- Enable RLS
alter table credit_cards enable row level security;

-- Policies for credit_cards
create policy "Users can view own cards" 
  on credit_cards for select 
  using (auth.uid() = user_id);

create policy "Users can insert own cards" 
  on credit_cards for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own cards" 
  on credit_cards for update 
  using (auth.uid() = user_id);

create policy "Users can delete own cards" 
  on credit_cards for delete 
  using (auth.uid() = user_id);

-- ============================================
-- 3. SAVINGS GOALS (Metas de Economia)
-- ============================================
create table if not exists savings_goals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  target_amount decimal(10,2) not null check (target_amount > 0),
  current_amount decimal(10,2) not null default 0 check (current_amount >= 0),
  monthly_reserve decimal(10,2) not null default 0 check (monthly_reserve >= 0),
  target_date timestamp with time zone,
  icon text default '🎯',
  color text default '#B4975A',
  is_completed boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for savings_goals
create index if not exists savings_goals_user_id_idx on savings_goals(user_id);

-- Enable RLS
alter table savings_goals enable row level security;

-- Policies for savings_goals
create policy "Users can view own goals" 
  on savings_goals for select 
  using (auth.uid() = user_id);

create policy "Users can insert own goals" 
  on savings_goals for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own goals" 
  on savings_goals for update 
  using (auth.uid() = user_id);

create policy "Users can delete own goals" 
  on savings_goals for delete 
  using (auth.uid() = user_id);

-- ============================================
-- VERIFICATION
-- ============================================
-- After running, verify RLS is enabled:
-- SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- ============================================
-- 4. INSTALLMENTS (Parcelas)
-- ============================================
create table if not exists installments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  parent_id uuid, -- Groups related installments together
  installment_number integer not null,
  total_installments integer not null,
  amount decimal(10,2) not null check (amount > 0),
  due_date date not null,
  description text not null,
  category text not null,
  payment_method text not null check (payment_method in ('credit_card', 'boleto', 'pix')),
  status text not null default 'pending' check (status in ('pending', 'paid')),
  paid_at timestamp with time zone,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for installments
create index if not exists installments_user_id_idx on installments(user_id);
create index if not exists installments_parent_id_idx on installments(parent_id);
create index if not exists installments_due_date_idx on installments(due_date);
create index if not exists installments_status_idx on installments(status);

-- Enable RLS
alter table installments enable row level security;

-- Policies for installments
create policy "Users can view own installments" 
  on installments for select 
  using (auth.uid() = user_id);

create policy "Users can insert own installments" 
  on installments for insert 
  with check (auth.uid() = user_id);

create policy "Users can update own installments" 
  on installments for update 
  using (auth.uid() = user_id);

create policy "Users can delete own installments" 
  on installments for delete 
  using (auth.uid() = user_id);
