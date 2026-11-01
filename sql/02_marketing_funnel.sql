create or replace view `bigquerycourse-444500.WarpJump.marketing_funnel` as

with users as (
select
user_id,
channel,
cast(signup_ts as timestamp) as signup_ts,
date_trunc(cast(signup_ts as date), month) as signup_month
from `bigquerycourse-444500.WarpJump.users`
),

events as (
select
u.user_id,
min(if(e.event_name = 'app_install', e.event_ts, null)) as install_ts,
min(if(e.event_name = 'onboarding_complete', e.event_ts, null)) as onboarding_ts,
min(if(e.event_name = 'paywall_view', e.event_ts, null)) as paywall_ts,
min(if(e.event_name = 'trial_start', e.event_ts, null)) as trial_ts
from users u
join `bigquerycourse-444500.WarpJump.events` e
on u.user_id = e.user_id
where e.event_name in ('app_install', 'onboarding_complete', 'paywall_view', 'trial_start')
and e.event_ts < timestamp '2026-10-01 00:00:00+00'
and (e.event_name = 'app_install' or e.event_ts >= u.signup_ts)
group by u.user_id
),

monthly_activity as (
select
date_trunc(cast(e.event_ts as date), month) as month,
u.channel,
count(distinct u.user_id) as active_users
from users u
join `bigquerycourse-444500.WarpJump.events` e
on u.user_id = e.user_id
where e.event_name = 'session_start'
and e.event_ts >= u.signup_ts
and e.event_ts < timestamp '2026-10-01 00:00:00+00'
group by 1, 2
),

payments as (
select distinct
p.payment_id,
u.user_id,
u.channel,
cast(p.payment_ts as timestamp) as payment_ts,
date_trunc(cast(p.payment_ts as date), month) as payment_month,
p.payment_type,
p.plan,
cast(p.amount_usd as numeric) as amount_usd
from `bigquerycourse-444500.WarpJump.payments` p
join users u
on p.user_id = u.user_id
where cast(p.payment_ts as timestamp) >= u.signup_ts
and cast(p.payment_ts as timestamp) < timestamp '2026-10-01 00:00:00+00'
),

first_purchase as (
select
user_id,
channel,
payment_ts,
payment_month,
plan
from payments
where payment_type = 'purchase'
and amount_usd > 0
qualify row_number() over (
partition by user_id
order by payment_ts, payment_id
) = 1
),

user_revenue as (
select
user_id,
sum(amount_usd) as net_revenue_usd
from payments
group by user_id
),

funnel as (
select
u.signup_month as month,
u.channel,
count(*) as signup_users,
count(e.install_ts) as install_users,
count(e.onboarding_ts) as onboarding_users,
count(e.paywall_ts) as paywall_users,
count(e.trial_ts) as trial_users,
count(p.user_id) as paying_users,
countif(e.paywall_ts >= e.onboarding_ts) as onboarding_to_paywall_users,
countif(e.trial_ts >= e.paywall_ts) as paywall_to_trial_users,
countif(p.payment_ts >= e.trial_ts) as trial_to_paid_users,
countif(p.payment_ts >= e.install_ts) as install_to_paid_users,
countif(p.plan = 'monthly') as monthly_payers,
countif(p.plan = 'annual') as annual_payers,
sum(coalesce(r.net_revenue_usd, 0)) as cohort_net_revenue_usd
from users u
left join events e
on u.user_id = e.user_id
left join first_purchase p
on u.user_id = p.user_id
left join user_revenue r
on u.user_id = r.user_id
group by 1, 2
),

new_payers as (
select
payment_month as month,
channel,
count(*) as new_payers
from first_purchase
group by 1, 2
),

monthly_payments as (
select
payment_month as month,
channel,
sum(if(payment_type in ('purchase', 'renewal'), amount_usd, 0)) as monthly_gross_revenue_usd,
sum(if(payment_type = 'refund', amount_usd, 0)) as monthly_refunds_usd,
sum(amount_usd) as monthly_net_revenue_usd,
sum(if(plan = 'monthly', amount_usd, 0)) as monthly_plan_net_revenue_usd,
sum(if(plan = 'annual', amount_usd, 0)) as annual_plan_net_revenue_usd,
countif(payment_type = 'renewal') as renewals,
countif(payment_type = 'refund') as refunds,
sum(
case plan when 'monthly' then 1 when 'annual' then 12 end
* case payment_type when 'purchase' then 1 when 'renewal' then 1 when 'refund' then -1 end
) as paid_subscription_months
from payments
group by 1, 2
),

spend as (
select
parse_date('%Y-%m', month) as month,
channel,
sum(cast(spend_usd as numeric)) as spend_usd
from `bigquerycourse-444500.WarpJump.marketing_spend`
group by 1, 2
),

month_channels as (
select month, channel from funnel
union distinct
select month, channel from monthly_activity
union distinct
select month, channel from monthly_payments
union distinct
select month, channel from spend
)

select
m.month,
m.channel,
coalesce(f.signup_users, 0) as signup_users,
coalesce(f.install_users, 0) as install_users,
coalesce(f.onboarding_users, 0) as onboarding_users,
coalesce(f.paywall_users, 0) as paywall_users,
coalesce(f.trial_users, 0) as trial_users,
coalesce(f.paying_users, 0) as paying_users,
coalesce(f.onboarding_to_paywall_users, 0) as onboarding_to_paywall_users,
coalesce(f.paywall_to_trial_users, 0) as paywall_to_trial_users,
coalesce(f.trial_to_paid_users, 0) as trial_to_paid_users,
coalesce(f.install_to_paid_users, 0) as install_to_paid_users,
coalesce(f.monthly_payers, 0) as monthly_payers,
coalesce(f.annual_payers, 0) as annual_payers,
coalesce(f.cohort_net_revenue_usd, 0) as cohort_net_revenue_usd,
coalesce(a.active_users, 0) as active_users,
coalesce(n.new_payers, 0) as new_payers,
coalesce(p.monthly_gross_revenue_usd, 0) as monthly_gross_revenue_usd,
coalesce(p.monthly_refunds_usd, 0) as monthly_refunds_usd,
coalesce(p.monthly_net_revenue_usd, 0) as monthly_net_revenue_usd,
coalesce(p.monthly_plan_net_revenue_usd, 0) as monthly_plan_net_revenue_usd,
coalesce(p.annual_plan_net_revenue_usd, 0) as annual_plan_net_revenue_usd,
coalesce(p.renewals, 0) as renewals,
coalesce(p.refunds, 0) as refunds,
coalesce(p.paid_subscription_months, 0) as paid_subscription_months,
s.spend_usd
from month_channels m
left join funnel f
using (month, channel)
left join monthly_activity a
using (month, channel)
left join new_payers n
using (month, channel)
left join monthly_payments p
using (month, channel)
left join spend s
using (month, channel);
