-- Apply only to an isolated test database before production.
create or replace function public.prisma_restore_v2(payload jsonb, preview boolean default true) returns jsonb language plpgsql security invoker set search_path = '' as $$
declare u uuid := auth.uid(); item jsonb; result jsonb := '{}'::jsonb; added integer; skipped integer; n integer;
begin
if u is null then raise exception 'Authentication required'; end if;
if payload is null or jsonb_typeof(payload) <> 'object' or payload->>'version' is distinct from '2' or octet_length(payload::text)>5242880 then raise exception 'Invalid backup'; end if;
perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text, 0));
added:=0; skipped:=0;
if jsonb_typeof(payload->'transactions') is distinct from 'array' then raise exception 'Invalid transactions'; end if;
if jsonb_array_length(payload->'transactions')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'transactions') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_transactions a cross join lateral jsonb_populate_record(null::public.prisma_transactions,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.type is not distinct from x.type and a.amount is not distinct from x.amount and a.category is not distinct from x.category and a.transaction_date is not distinct from x.transaction_date and a.description is not distinct from x.description))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_transactions(user_id,type,amount,category,transaction_date,description) select u,x.type,x.amount,x.category,x.transaction_date,x.description from jsonb_populate_record(null::public.prisma_transactions,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('transactions',jsonb_build_object('new',added,'skipped',skipped));
added:=0; skipped:=0;
if jsonb_typeof(payload->'study_tasks') is distinct from 'array' then raise exception 'Invalid study_tasks'; end if;
if jsonb_array_length(payload->'study_tasks')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'study_tasks') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_study_tasks a cross join lateral jsonb_populate_record(null::public.prisma_study_tasks,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.title is not distinct from x.title and a.subject is not distinct from x.subject and a.due_date is not distinct from x.due_date and a.notes is not distinct from x.notes and a.done is not distinct from x.done and a.estimated_minutes is not distinct from x.estimated_minutes))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_study_tasks(user_id,title,subject,due_date,notes,done,estimated_minutes,completed_at) select u,x.title,x.subject,x.due_date,x.notes,x.done,x.estimated_minutes,x.completed_at from jsonb_populate_record(null::public.prisma_study_tasks,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('study_tasks',jsonb_build_object('new',added,'skipped',skipped));
added:=0; skipped:=0;
if jsonb_typeof(payload->'bill_reminders') is distinct from 'array' then raise exception 'Invalid bill_reminders'; end if;
if jsonb_array_length(payload->'bill_reminders')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'bill_reminders') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_bill_reminders a cross join lateral jsonb_populate_record(null::public.prisma_bill_reminders,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.title is not distinct from x.title and a.amount is not distinct from x.amount and a.due_date is not distinct from x.due_date and a.paid is not distinct from x.paid))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_bill_reminders(user_id,title,amount,due_date,paid) select u,x.title,x.amount,x.due_date,x.paid from jsonb_populate_record(null::public.prisma_bill_reminders,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('bill_reminders',jsonb_build_object('new',added,'skipped',skipped));
added:=0; skipped:=0;
if jsonb_typeof(payload->'investments') is distinct from 'array' then raise exception 'Invalid investments'; end if;
if jsonb_array_length(payload->'investments')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'investments') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_investments a cross join lateral jsonb_populate_record(null::public.prisma_investments,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.ticker is not distinct from x.ticker and a.name is not distinct from x.name and a.asset_type is not distinct from x.asset_type and a.quantity is not distinct from x.quantity and a.average_price is not distinct from x.average_price and a.purchase_date is not distinct from x.purchase_date and a.monthly_income is not distinct from x.monthly_income and a.notes is not distinct from x.notes and a.manual_price is not distinct from x.manual_price))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_investments(user_id,ticker,name,asset_type,quantity,average_price,purchase_date,monthly_income,notes,manual_price) select u,x.ticker,x.name,x.asset_type,x.quantity,x.average_price,x.purchase_date,x.monthly_income,x.notes,x.manual_price from jsonb_populate_record(null::public.prisma_investments,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('investments',jsonb_build_object('new',added,'skipped',skipped));
added:=0; skipped:=0;
if jsonb_typeof(payload->'investment_snapshots') is distinct from 'array' then raise exception 'Invalid investment_snapshots'; end if;
if jsonb_array_length(payload->'investment_snapshots')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'investment_snapshots') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_investment_snapshots a cross join lateral jsonb_populate_record(null::public.prisma_investment_snapshots,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.snapshot_date is not distinct from x.snapshot_date))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_investment_snapshots(user_id,snapshot_date,total_value,total_cost) select u,x.snapshot_date,x.total_value,x.total_cost from jsonb_populate_record(null::public.prisma_investment_snapshots,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('investment_snapshots',jsonb_build_object('new',added,'skipped',skipped));
added:=0; skipped:=0;
if jsonb_typeof(payload->'investment_dividends') is distinct from 'array' then raise exception 'Invalid investment_dividends'; end if;
if jsonb_array_length(payload->'investment_dividends')>10000 then raise exception 'Too many rows'; end if;
for item in select value from jsonb_array_elements(payload->'investment_dividends') loop
if jsonb_typeof(item) <> 'object' then raise exception 'Invalid row'; end if;
if exists(select 1 from public.prisma_investment_dividends a cross join lateral jsonb_populate_record(null::public.prisma_investment_dividends,item) x where a.user_id=u and ((x.id is not null and a.id=x.id) or (a.asset_name is not distinct from x.asset_name and a.amount is not distinct from x.amount and a.payment_date is not distinct from x.payment_date and a.notes is not distinct from x.notes))) then skipped:=skipped+1;
else
if not preview then insert into public.prisma_investment_dividends(user_id,asset_name,amount,payment_date,notes) select u,x.asset_name,x.amount,x.payment_date,x.notes from jsonb_populate_record(null::public.prisma_investment_dividends,item) x; end if;
added:=added+1; end if;
end loop;
result:=result||jsonb_build_object('investment_dividends',jsonb_build_object('new',added,'skipped',skipped));
return result; end; $$;
revoke all on function public.prisma_restore_v2(jsonb,boolean) from public, anon;
grant execute on function public.prisma_restore_v2(jsonb,boolean) to authenticated;
