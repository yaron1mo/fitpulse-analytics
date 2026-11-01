# FitPulse analytics

BigQuery SQL used to prepare the FitPulse test assignment for Tableau Public.

## Queries

- [Cohort retention: all users](sql/01_cohort_retention_all_users.sql) — weekly signup cohorts and `session_start` activity.
- [Marketing funnel](sql/02_marketing_funnel.sql) — monthly channel funnel, payments, refunds, revenue, and spend.

The SQL uses project `bigquerycourse-444500`, dataset `WarpJump`, and BigQuery Standard SQL. The marketing view combines different month meanings: acquisition cohort for funnel and cohort revenue, calendar month for spend, activity, and payments. June, July, and August cohorts have different observation windows through 2026-09-30.

Other BigQuery views used in Tableau (`ceo_onboarding`, `ceo_retention`, and paid subscriber cohort retention) are not included yet because their final SQL definitions have not been provided here.