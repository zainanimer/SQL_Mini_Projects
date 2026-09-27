# SQL Portfolio

Three PostgreSQL mini projects, ordered by difficulty, each covering a
different set of skills. Each project lives in its own folder with two files:
a **README** explaining the project, and a single **.sql file** containing
the full schema, seed data, and queries — with each query's real,
verified output included as a comment block right underneath it. Nothing
in the output was invented; every result was produced by actually running
the code against the seed data.

## Projects

| # | Project | Level | Focus |
|---|---|---|---|
| 1 | [HR Employee Management](./01-hr-employee-management) | Beginner | `SELECT`, filtering, `JOIN` (inner/left/self), `GROUP BY`/`HAVING`, aggregates, basic subqueries |
| 2 | [E-Commerce Sales Analytics](./02-ecommerce-sales-analytics) | Intermediate | CTEs, window functions (`LAG`, `RANK`, `SUM OVER`, `AVG OVER`), month-over-month growth, running totals |
| 3 | [Subscription Churn Analysis](./03-subscription-churn-analysis) | Advanced | Data cleaning (messy raw data), cohort retention analysis, churn metrics, indexing & `EXPLAIN ANALYZE` |

## Why these three

Each project builds on the last:

1. **HR Employee Management** proves out the fundamentals — relational
   schema design, joins, and aggregation. This is the "can you write
   correct SQL" project.
2. **E-Commerce Sales Analytics** moves into the tools used for real
   analytics work: CTEs to structure multi-step logic, and window
   functions for growth rates, rankings, and running totals.
3. **Subscription Churn Analysis** is the closest to real-world data work:
   it starts from messy, duplicated, inconsistently formatted data,
   cleans it, then answers an actual business question (retention and
   churn) and considers query performance at scale.

## Tech stack

- **PostgreSQL 13+** for all three projects
- Plain `.sql` files — no ORM, no external dependencies — so anyone can
  clone the repo and run each project with `psql`

## How to run any project

Each project is one file, so setup is always the same shape:

```bash
cd <project-folder>
createdb <database_name>
psql -d <database_name> -f <project_file>.sql
```

Each project's own README has the exact database name and file name to use.

## What this portfolio demonstrates

- Relational schema design (1-to-many, many-to-many, self-referencing keys)
- Core SQL: filtering, sorting, joins, grouping, aggregates
- Intermediate SQL: CTEs, window functions, time-series analysis
- Advanced SQL: data cleaning, cohort analysis, indexing, query performance
- Writing SQL that's commented and organized well enough for someone else
  to read and run

