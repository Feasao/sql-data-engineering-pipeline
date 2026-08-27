--Unified build file
-- RUN: duckdb dw_marts.duckdb -c ".read build.sql"


.read "01_create_tables.sql"

.read "02_load_data.sql"

.read "03_flat_mart.sql"

.read "04_skills_mart.sql"

.read "05_priority_mart.sql"

.read "06_update_priority_mart.sql"