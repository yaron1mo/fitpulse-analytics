create or replace view `bigquerycourse-444500.WarpJump.paywall_ab` as

with cohort as (
select
user_id,
cast(signup_ts as timestamp) as signup_ts,
date(cast(signup_ts as timestamp)) as signup_day,
ab_group,
platform,
country,
channel
from `bigquerycourse-444500.WarpJump.users`
where date(cast(signup_ts as timestamp)) between date '2026-08-01' and date '2026-08-31'
and ab_group in ('A', 'B')
),

activity as (
select
c.user_id,
countif(e.event_name = 'trial_start') > 0 as trial,
countif(e.event_name = 'session_start' and date_diff(date(cast(e.event_ts as timestamp)), c.signup_day, day) = 30) > 0 as d30
from cohort c
join `bigquerycourse-444500.WarpJump.events` e
on c.user_id = e.user_id
where cast(e.event_ts as timestamp) >= c.signup_ts
and cast(e.event_ts as timestamp) < timestamp '2026-10-01 00:00:00+00'
and e.event_name in ('trial_start', 'session_start')
group by c.user_id
),

payments as (
select distinct
p.payment_id,
c.user_id,
p.payment_type,
cast(p.amount_usd as numeric) as amount_usd
from cohort c
join `bigquerycourse-444500.WarpJump.payments` p
on c.user_id = p.user_id
where cast(p.payment_ts as timestamp) >= c.signup_ts
and cast(p.payment_ts as timestamp) < timestamp '2026-10-01 00:00:00+00'
),

user_payments as (
select
user_id,
countif(payment_type = 'purchase' and amount_usd > 0) > 0 as payer,
sum(if(payment_type = 'refund', -abs(amount_usd), amount_usd)) as revenue
from payments
group by user_id
)

select
c.user_id,
c.ab_group,
c.signup_ts,
c.signup_day,
c.platform,
c.country,
c.channel,
timestamp_diff(timestamp '2026-10-01 00:00:00+00', c.signup_ts, second) / 86400 as days_observed,
coalesce(a.trial, false) as trial,
coalesce(p.payer, false) as payer,
coalesce(p.revenue, 0) as revenue,
date_diff(date '2026-10-01', c.signup_day, day) >= 31 as d30_mature,
if(date_diff(date '2026-10-01', c.signup_day, day) >= 31, coalesce(a.d30, false), null) as d30
from cohort c
left join activity a
using (user_id)
left join user_payments p
using (user_id);
