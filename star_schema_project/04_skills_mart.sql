--Skills Mart
DROP SCHEMA IF EXISTS skills_mart;
CREATE SCHEMA skills_mart;


CREATE TABLE skills_mart.dim_skills(
    skill_id INTEGER PRIMARY KEY,
    skills VARCHAR,
    type VARCHAR
);
INSERT INTO skills_mart.dim_skills(
    skill_id,
    skills,
    type
)
SELECT 
    skill_id,
    skills,
    type
FROM skills_dim;

CREATE OR REPLACE TABLE skills_mart.dim_date_month(
    month_start_date DATE PRIMARY KEY,
    year INT,
    month INT,
    quarter INT,
    quarter_name VARCHAR,
    year_quarter VARCHAR
);


INSERT INTO skills_mart.dim_date_month(
    month_start_date,
    year,
    month,
    quarter,
    quarter_name,
    year_quarter
)
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date)::DATE as month_start_date,
    EXTRACT(YEAR FROM job_posted_date) as year,
    EXTRACT(MONTH FROM job_posted_date) as month,
    EXTRACT(QUARTER FROM job_posted_date) as quarter,
    'Q-' || EXTRACT(QUARTER FROM job_posted_date)::VARCHAR AS quarter_name,
    EXTRACT(YEAR FROM job_posted_date)::VARCHAR || '-Q' ||
    EXTRACT(QUARTER FROM job_posted_date) AS year_quarter
FROM job_postings_fact
ORDER BY month_start_date;


CREATE OR REPLACE TABLE skills_mart.fact_skill_demand_monthly(
    skill_id INT,
    month_start_date DATE,
    job_title_short VARCHAR,
    postings_count INT,
    remote_postings_count INTEGER,
    health_insurance_postings_count INT,
    no_degree_mention_postings_count INT,
    PRIMARY KEY ( skill_id,month_start_date,job_title_short),
    FOREIGN KEY (skill_id) REFERENCES skills_mart.dim_skills(skill_id),
    FOREIGN KEY (month_start_date) REFERENCES skills_mart.dim_date_month(month_start_date)
);

INSERT INTO skills_mart.fact_skill_demand_monthly (
    skill_id,
    month_start_date,
    job_title_short,
    postings_count,
    remote_postings_count,
    health_insurance_postings_count,
    no_degree_mention_postings_count
)
WITH jp_prep as (
SELECT
    sjd.skill_id,
    DATE_TRUNC('month', job_posted_date)::DATE as month_start_date,
    jpf.job_title_short,
    CASE WHEN jpf.job_work_from_home = TRUE THEN 1 ELSE 0 END AS is_remote,
    CASE WHEN jpf.job_health_insurance = TRUE THEN 1 ELSE 0 END AS has_health_insurance,
    CASE WHEN jpf.job_no_degree_mention = TRUE THEN 1 ELSE 0 END AS no_degree_mentioned

FROM job_postings_fact as jpf
INNER JOIN skills_job_dim as sjd on jpf.job_id = sjd.job_id
)
SELECT
    skill_id,
    month_start_date,
    job_title_short,
    COUNT(*) as postings_count,
    SUM(is_remote) AS remote_postings_count,
    SUM(has_health_insurance) AS health_insurance_postings_count,
    SUM(no_degree_mentioned) AS no_degree_mention_postings_count
FROM jp_prep
GROUP BY ALL
ORDER BY skill_id,month_start_date,job_title_short;


SELECT 'Skills Dimension' as table_name, COUNT(*) as record_count FROM skills_mart.dim_skills
UNION ALL
SELECT 'Date Month Dimension' as table_name, COUNT(*) as record_count FROM skills_mart.dim_date_month
UNION ALL
SELECT 'Skill Demand Fact' as table_name, COUNT(*) as record_count FROM skills_mart.fact_skill_demand_monthly;
