# SQL-Native ELT Pipeline & Dimensional Data Warehouse

A robust SQL-based data pipeline designed to analyze global tech job market trends, remote work opportunities and in-demand skills. Designed to showcase efficient backend data workflows, this project uses DuckDB to ingest raw job posting data from cloud storage and transforms it into a highly optimized star schema to power advanced data analysis.

## Summary

- **Built a full ELT pipeline** — raw CSVs (GCS) → normalized star schema → three purpose-built analytical marts, orchestrated end-to-end via a single SQL entrypoint
- **Modeled a star schema** with fact, dimension, and bridge tables (`job_postings_fact`, `company_dim`, `skills_dim`, `skills_job_dim`), enforcing referential integrity via primary/foreign keys
- **Implemented incremental upserts** using SQL `MERGE` (insert/update/delete in a single statement) to keep a snapshot mart in sync with changing source data — a production-style SCD Type 1 pattern
- **Delivered three specialized marts** (flat, skills-demand, priority-role), each modeled for a different analytical use case, with monthly aggregate facts and idempotent safely re-runnable builds and data validation.

## Pipeline Architecture

The workflow is orchestrated via a central build script (`build.sql`) and broken down into modular SQL transformations:

1. **Initialization (`01_create_tables.sql`):** Sets up the foundational database schema with idempotent table structures for companies, skills, and job postings.
2. **Data Ingestion (`02_load_data.sql`):** Extracts raw job market CSV data directly from Google Cloud Storage into the DuckDB staging tables.
3. **Denormalization (`03_flat_mart.sql`):** Flattens transactional data and utilizes array aggregation to structure nested skill sets for efficient analytical querying.
4. **Skills Dimensional Model (`04_skills_mart.sql`):** Creates targeted data marts to compute monthly demand metrics, remote work availability, and benefit offerings (e.g., no degree mentions, health insurance).
5. **Priority Role Tracking (`05_priority_mart.sql`):** Isolates targeted, high-priority job roles (such as Data Engineer, Software Engineer, and Data Scientist) into a dedicated snapshot table.
6. **UPSERT/MERGE Logic (`06_update_priority_mart.sql`):** Implements `MERGE` logic to handle changing priorities, insert new records, and safely update existing priority job snapshots.

## How to Run

```bash
duckdb dw_marts.duckdb -c ".read build.sql"
```

This single command rebuilds the entire warehouse, raw tables, all three marts, and the incremental update from scratch in one DuckDB database file. The build file can be found [**here**](star_schema_project/build.sql).

## Data Engineering / Analytics Engineering Skills Demonstrated

- **Dimensional modeling** — classic star schema with fact/dimension/bridge tables, explicit primary and foreign keys.
- **Idempotent pipelines** — `DROP TABLE/SCHEMA IF EXISTS` + `CREATE OR REPLACE` throughout, so the build is safely re-runnable from a clean or existing state.
- **ELT from cloud storage** — `read_csv(..., AUTO_DETECT = true)` pulling directly from GCS-hosted CSVs into typed tables.
- **Pipeline orchestration** — a single `build.sql` entrypoint chaining modular, numbered SQL scripts via `.read`, mirroring how orchestrators (dbt, Airflow) sequence a DAG.
- **Multiple purpose-built data marts** — a denormalized flat mart for BI/ad-hoc analysis, a monthly aggregate fact table for skill-demand trend reporting, and a business-priority snapshot mart, each modeled for a different consumption pattern.
- **Semi-structured / nested data modeling** — `ARRAY_AGG` + `STRUCT_PACK` to flatten a many-to-many bridge into a single nested column, a common pattern in modern columnar warehouses (BigQuery, Snowflake, DuckDB).
- **Incremental loading & upserts** — `06_update_priority_mart.sql` implements a full `MERGE` (`WHEN MATCHED` / `WHEN NOT MATCHED BY TARGET` / `WHEN NOT MATCHED BY SOURCE THEN DELETE`), the standard pattern for keeping a snapshot table in sync with a changing source.
- **Slowly Changing Dimension (SCD Type 1) logic** — priority levels are updated in place with an `updated_at` audit column tracking the most recent change.
- **Data quality / validation checks** — row-count reconciliation queries after each load step to confirm expected volumes landed correctly.
- **Date dimension design** — a conformed `dim_date_month` table (year, month, quarter, year-quarter) built for consistent time-based rollups across marts.

## Tech Stack

- **DuckDB** — embedded OLAP SQL engine
- **SQL** — DDL, DML, window/aggregate functions, `MERGE`, semi-structured types (`STRUCT`, `ARRAY_AGG`)
- **CSV / GCS** — source data ingestion

## Data

Job postings dataset created and maintained by [Luke Barousse](https://www.lukebarousse.com/), used here for portfolio purposes.
