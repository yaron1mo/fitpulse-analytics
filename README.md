# FitPulse analytics

BigQuery SQL used to prepare the FitPulse test assignment for Tableau Public.

## Queries

### Task 1 — cohort retention

- [All users](sql/01_cohort_retention_all_users.sql) — weekly signup cohorts with `session_start` activity.
- [Subscribers](sql/02_cohort_retention_subscribers.sql) — users with a positive `purchase` in payments, grouped by **signup week**; activity is measured from that week. This is retention of users who subscribed at any point in the available data, not retention measured from their first purchase.

### Task 2 — Head of Marketing

- [Marketing funnel](sql/03_marketing_funnel.sql) — monthly channel funnel, payments, refunds, revenue, and spend.

The SQL uses project `bigquerycourse-444500`, dataset `WarpJump`, and BigQuery Standard SQL. The marketing view combines different month meanings: acquisition cohort for funnel and cohort revenue, calendar month for spend, activity, and payments. June, July, and August cohorts have different observation windows through 2026-09-30.

The final SQL definitions for the CEO views `ceo_onboarding` and `ceo_retention` have not yet been added.
