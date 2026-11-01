create or replace view `bigquerycourse-444500.WarpJump.ceo_onboarding` as

with users as (
select
user_id,
cast(signup_ts as timestamp) as signup_ts,
platform,
country,
channel,
ab_group
from `bigquerycourse-444500.WarpJump.users`
),

onboarding as (
select
u.user_id,
min(cast(e.event_ts as timestamp)) as onboarding_complete_ts
from users u
join `bigquerycourse-444500.WarpJump.events` e
on u.user_id = e.user_id
where e.event_name = 'onboarding_complete'
and cast(e.event_ts as timestamp) >= u.signup_ts
and cast(e.event_ts as timestamp) < timestamp '2026-10-01 00:00:00+00'
group by u.user_id
)

select
u.user_id,
u.signup_ts,
date_trunc(date(u.signup_ts), month) as cohort_month,
u.platform,
u.country,
u.channel,
u.ab_group,
o.onboarding_complete_ts,
timestamp_diff(o.onboarding_complete_ts, u.signup_ts, microsecond) / 3600000000 as hours_to_onboarding,
timestamp '2026-10-01 00:00:00+00' as observation_end_ts
from users u
left join onboarding o
using (user_id);
