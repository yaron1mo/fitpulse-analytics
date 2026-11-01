with subscribers as (
select distinct
user_id
from `bigquerycourse-444500.WarpJump.payments`
where payment_type = 'purchase'
and amount_usd > 0
),

users as (
select
u.user_id,
date_trunc(cast(u.signup_ts as date), week(monday)) as cohort_week
from `bigquerycourse-444500.WarpJump.users` u
join subscribers s
on u.user_id = s.user_id
),

cohort_sizes as (
select
cohort_week,
count(distinct user_id) as cohort_size
from users
group by cohort_week
),

events as (
select
user_id,
cast(event_ts as date) as event_date,
event_name
from `bigquerycourse-444500.WarpJump.events`
),

activity as (
select distinct
user_id,
date_trunc(event_date, week(monday)) as activity_week
from events
where event_name = 'session_start'
and event_date >= date '2026-06-01'
),

retention as (
select
u.cohort_week,
date_diff(a.activity_week, u.cohort_week, week(monday)) as week_number,
count(distinct u.user_id) as active_users
from users u
join activity a
on u.user_id = a.user_id
group by 1, 2
)

select
r.cohort_week,
r.week_number,
c.cohort_size,
r.active_users,
safe_divide(r.active_users, c.cohort_size) as retention_rate
from retention r
join cohort_sizes c
on r.cohort_week = c.cohort_week
order by 1, 2
