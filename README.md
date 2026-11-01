# FitPulse analytics

BigQuery SQL used to prepare the FitPulse test assignment for Tableau Public.

## Queries

### Task 1 — cohort retention

- [All users](sql/01_cohort_retention_all_users.sql) — weekly signup cohorts with `session_start` activity.
- [Subscribers](sql/02_cohort_retention_subscribers.sql) — users with a positive `purchase` in payments, grouped by **signup week**; activity is measured from that week. This is retention of users who subscribed at any point in the available data, not retention measured from their first purchase.

### Task 2 — Head of Marketing

- [Marketing funnel](sql/03_marketing_funnel.sql) — monthly channel funnel, payments, refunds, revenue, and spend.

The SQL uses project `bigquerycourse-444500`, dataset `WarpJump`, and BigQuery Standard SQL. The marketing view combines different month meanings: acquisition cohort for funnel and cohort revenue, calendar month for spend, activity, and payments. June, July, and August cohorts have different observation windows through 2026-09-30.

### Task 2 — CEO

- [Onboarding](sql/04_ceo_onboarding.sql) includes all signups and the first onboarding completion after signup. The completion rate is the share of users with a completion timestamp.
- [Retention](sql/05_ceo_retention.sql) includes one row per user and week since signup. W1 covers UTC calendar days 7 through 13. Average `is_active` for retention. Incomplete weeks have a null value. The observation end timestamp is exclusive.

### Task 2 — Product Manager

- [Paywall A/B input](sql/06_paywall_ab.sql) includes one row per assigned August user, including those without activity or payments. It prepares the paid conversion, trial, net revenue and D30 session indicators used in the submitted notebook. Events and payments are observed through September 30 UTC.
