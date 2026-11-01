create or replace view `bigquerycourse-444500.WarpJump.ceo_retention` as

with users as (
select
user_id,
cast(signup_ts as timestamp) as signup_ts,
date(cast(signup_ts as timestamp)) as signup_date,
platform,
country,
channel,
ab_group
from `bigquerycourse-444500.WarpJump.users`
),

activity as (
select distinct
u.user_id,
div(date_diff(date(cast(e.event_ts as timestamp)), u.signup_date, day), 7) as week_number
from users u
join `bigquerycourse-444500.WarpJump.events` e
on u.user_id = e.user_id
where e.event_name = 'session_start'
and cast(e.event_ts as timestamp) >= u.signup_ts
and cast(e.event_ts as timestamp) < timestamp '2026-10-01 00:00:00+00'
),

weeks as (
select
u.*,
week_number,
7 * (week_number + 1) <= date_diff(date '2026-10-01', u.signup_date, day) as full_week
from users u
cross join unnest(generate_array(0, div(date_diff(date '2026-09-30', u.signup_date, day), 7))) as week_number
)

select
w.user_id,
w.signup_ts,
date_trunc(w.signup_date, month) as cohort_month,
w.platform,
w.country,
w.channel,
w.ab_group,
w.week_number,
cast(w.full_week as int64) as is_observable,
if(w.full_week, cast(a.user_id is not null as int64), null) as is_active,
timestamp '2026-10-01 00:00:00+00' as observation_end_ts
from weeks w
left join activity a
using (user_id, week_number);
