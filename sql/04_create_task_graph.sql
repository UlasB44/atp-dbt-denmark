-- ============================================================================
-- Snowflake Tasks - Alternative to dbt for Orchestration Demo
-- ============================================================================
-- This creates a TASK GRAPH that replicates the dbt pension pipeline:
--   1. TASK_MEMBERS_CLEAN (SILVER)
--   2. TASK_CONTRIBUTIONS_ENRICHED (SILVER) - depends on #1
--   3. TASK_MEMBER_CONTRIBUTION_SUMMARY (GOLD) - depends on #2
--
-- Use this to demonstrate:
-- - Native Snowflake orchestration (vs dbt)
-- - Task dependencies (DAG)
-- - Scheduling options (time-based, event-based)
-- - Observability via TASK_HISTORY
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ATP_ETL_WH;
USE DATABASE ATP_PENSION;

-- ============================================================================
-- STEP 1: Create SILVER Tables (if not exist via dbt)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SILVER;

CREATE TABLE IF NOT EXISTS SILVER.MEMBERS_CLEAN (
    cpr_number VARCHAR(12),
    full_name VARCHAR(200),
    gender VARCHAR(1),
    birth_date DATE,
    age NUMBER,
    age_group VARCHAR(20),
    civil_status VARCHAR(20),
    street_address VARCHAR(200),
    postal_code VARCHAR(10),
    city VARCHAR(100),
    region VARCHAR(50),
    is_active BOOLEAN,
    registration_date TIMESTAMP_LTZ,
    last_updated TIMESTAMP_LTZ,
    data_quality_score FLOAT,
    processed_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS SILVER.CONTRIBUTIONS_ENRICHED (
    contribution_id NUMBER,
    cpr_number VARCHAR(12),
    employer_cvr VARCHAR(10),
    employer_name VARCHAR(200),
    contribution_date DATE,
    contribution_year NUMBER,
    contribution_month NUMBER,
    contribution_quarter NUMBER,
    employee_contribution_dkk FLOAT,
    employer_contribution_dkk FLOAT,
    total_contribution_dkk FLOAT,
    hours_worked FLOAT,
    employment_type VARCHAR(20),
    member_age NUMBER,
    member_gender VARCHAR(1),
    processed_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- STEP 2: Create GOLD Table (if not exist via dbt)
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS GOLD;

CREATE TABLE IF NOT EXISTS GOLD.MEMBER_CONTRIBUTION_SUMMARY (
    cpr_number VARCHAR(12),
    full_name VARCHAR(200),
    age NUMBER,
    gender VARCHAR(1),
    total_contributions_dkk FLOAT,
    total_employee_contributions_dkk FLOAT,
    total_employer_contributions_dkk FLOAT,
    avg_monthly_contribution_dkk FLOAT,
    first_contribution_date DATE,
    last_contribution_date DATE,
    months_with_contributions NUMBER,
    years_active NUMBER,
    total_hours_worked FLOAT,
    number_of_employers NUMBER,
    current_employer VARCHAR(200),
    last_contribution_amount_dkk FLOAT,
    contribution_trend VARCHAR(20),
    processed_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- STEP 3: Create Task 1 - MEMBERS_CLEAN (SILVER)
-- ============================================================================

CREATE OR REPLACE TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN
    WAREHOUSE = ATP_ETL_WH
    SCHEDULE = 'USING CRON 0 2 * * * UTC'  -- Run daily at 2 AM UTC
    COMMENT = 'Task to populate SILVER.MEMBERS_CLEAN from RAW.MEMBERS'
AS
BEGIN
    -- Truncate and reload (full refresh like dbt)
    TRUNCATE TABLE SILVER.MEMBERS_CLEAN;
    
    -- Insert cleaned and enriched member data
    INSERT INTO SILVER.MEMBERS_CLEAN (
        cpr_number,
        full_name,
        gender,
        birth_date,
        age,
        age_group,
        civil_status,
        street_address,
        postal_code,
        city,
        region,
        is_active,
        registration_date,
        last_updated,
        data_quality_score
    )
    SELECT 
        cpr_number,
        CONCAT(first_name, ' ', last_name) AS full_name,
        gender,
        birth_date,
        YEAR(CURRENT_DATE()) - YEAR(birth_date) AS age,
        CASE 
            WHEN YEAR(CURRENT_DATE()) - YEAR(birth_date) < 30 THEN '18-29'
            WHEN YEAR(CURRENT_DATE()) - YEAR(birth_date) < 50 THEN '30-49'
            WHEN YEAR(CURRENT_DATE()) - YEAR(birth_date) < 65 THEN '50-64'
            ELSE '65+'
        END AS age_group,
        civil_status,
        street_address,
        postal_code,
        city,
        CASE 
            WHEN postal_code LIKE '1%' OR postal_code LIKE '2%' THEN 'Capital Region'
            WHEN postal_code LIKE '3%' OR postal_code LIKE '4%' THEN 'Zealand'
            WHEN postal_code LIKE '5%' THEN 'Southern Denmark'
            WHEN postal_code LIKE '6%' OR postal_code LIKE '7%' THEN 'Central Denmark'
            WHEN postal_code LIKE '8%' OR postal_code LIKE '9%' THEN 'North Denmark'
            ELSE 'Unknown'
        END AS region,
        TRUE AS is_active,
        registration_date,
        last_updated,
        -- Data quality score based on completeness
        (
            CASE WHEN cpr_number IS NOT NULL THEN 0.25 ELSE 0 END +
            CASE WHEN first_name IS NOT NULL THEN 0.15 ELSE 0 END +
            CASE WHEN last_name IS NOT NULL THEN 0.15 ELSE 0 END +
            CASE WHEN birth_date IS NOT NULL THEN 0.20 ELSE 0 END +
            CASE WHEN postal_code IS NOT NULL THEN 0.15 ELSE 0 END +
            CASE WHEN city IS NOT NULL THEN 0.10 ELSE 0 END
        ) AS data_quality_score
    FROM ATP_PENSION.RAW.MEMBERS
    WHERE cpr_number IS NOT NULL;
    
    -- Log execution
    INSERT INTO ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG (
        task_name, 
        rows_processed, 
        execution_time
    )
    SELECT 
        'TASK_MEMBERS_CLEAN',
        COUNT(*),
        CURRENT_TIMESTAMP()
    FROM SILVER.MEMBERS_CLEAN;
END;

-- ============================================================================
-- STEP 4: Create Task 2 - CONTRIBUTIONS_ENRICHED (SILVER)
-- Depends on TASK_MEMBERS_CLEAN
-- ============================================================================

CREATE OR REPLACE TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED
    WAREHOUSE = ATP_ETL_WH
    AFTER ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN
AS
    -- Task to enrich contributions with member and employer data
BEGIN
    -- Truncate and reload
    TRUNCATE TABLE SILVER.CONTRIBUTIONS_ENRICHED;
    
    -- Enrich contributions with member and employer data
    INSERT INTO SILVER.CONTRIBUTIONS_ENRICHED (
        contribution_id,
        cpr_number,
        employer_cvr,
        employer_name,
        contribution_date,
        contribution_year,
        contribution_month,
        contribution_quarter,
        employee_contribution_dkk,
        employer_contribution_dkk,
        total_contribution_dkk,
        hours_worked,
        employment_type,
        member_age,
        member_gender
    )
    SELECT 
        c.contribution_id,
        c.cpr_number,
        c.employer_cvr,
        e.company_name AS employer_name,
        c.contribution_date,
        YEAR(c.contribution_date) AS contribution_year,
        MONTH(c.contribution_date) AS contribution_month,
        QUARTER(c.contribution_date) AS contribution_quarter,
        c.employee_contribution_dkk,
        c.employer_contribution_dkk,
        c.employee_contribution_dkk + c.employer_contribution_dkk AS total_contribution_dkk,
        c.hours_worked,
        CASE 
            WHEN c.hours_worked >= 37 THEN 'Full-time'
            WHEN c.hours_worked >= 20 THEN 'Part-time'
            ELSE 'Minimal'
        END AS employment_type,
        m.age AS member_age,
        m.gender AS member_gender
    FROM ATP_PENSION.RAW.CONTRIBUTIONS c
    LEFT JOIN SILVER.MEMBERS_CLEAN m ON c.cpr_number = m.cpr_number
    LEFT JOIN ATP_PENSION.RAW.EMPLOYERS e ON c.employer_cvr = e.cvr_number
    WHERE c.contribution_date IS NOT NULL;
    
    -- Log execution
    INSERT INTO ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG (
        task_name, 
        rows_processed, 
        execution_time
    )
    SELECT 
        'TASK_CONTRIBUTIONS_ENRICHED',
        COUNT(*),
        CURRENT_TIMESTAMP()
    FROM SILVER.CONTRIBUTIONS_ENRICHED;
END;

-- ============================================================================
-- STEP 5: Create Task 3 - MEMBER_CONTRIBUTION_SUMMARY (GOLD)
-- Depends on TASK_CONTRIBUTIONS_ENRICHED
-- ============================================================================

CREATE OR REPLACE TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY
    WAREHOUSE = ATP_ETL_WH
    AFTER ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED
AS
    -- Task to create member contribution summary analytics
BEGIN
    -- Truncate and reload
    TRUNCATE TABLE GOLD.MEMBER_CONTRIBUTION_SUMMARY;
    
    -- Create summary analytics
    INSERT INTO GOLD.MEMBER_CONTRIBUTION_SUMMARY (
        cpr_number,
        full_name,
        age,
        gender,
        total_contributions_dkk,
        total_employee_contributions_dkk,
        total_employer_contributions_dkk,
        avg_monthly_contribution_dkk,
        first_contribution_date,
        last_contribution_date,
        months_with_contributions,
        years_active,
        total_hours_worked,
        number_of_employers,
        current_employer,
        last_contribution_amount_dkk,
        contribution_trend
    )
    SELECT 
        m.cpr_number,
        m.full_name,
        m.age,
        m.gender,
        SUM(c.total_contribution_dkk) AS total_contributions_dkk,
        SUM(c.employee_contribution_dkk) AS total_employee_contributions_dkk,
        SUM(c.employer_contribution_dkk) AS total_employer_contributions_dkk,
        AVG(c.total_contribution_dkk) AS avg_monthly_contribution_dkk,
        MIN(c.contribution_date) AS first_contribution_date,
        MAX(c.contribution_date) AS last_contribution_date,
        COUNT(DISTINCT TO_VARCHAR(c.contribution_date, 'YYYY-MM')) AS months_with_contributions,
        DATEDIFF('year', MIN(c.contribution_date), MAX(c.contribution_date)) AS years_active,
        SUM(c.hours_worked) AS total_hours_worked,
        COUNT(DISTINCT c.employer_cvr) AS number_of_employers,
        MAX_BY(c.employer_name, c.contribution_date) AS current_employer,
        MAX_BY(c.total_contribution_dkk, c.contribution_date) AS last_contribution_amount_dkk,
        CASE 
            WHEN AVG(CASE WHEN c.contribution_date >= DATEADD('month', -6, CURRENT_DATE()) 
                          THEN c.total_contribution_dkk END) > 
                 AVG(CASE WHEN c.contribution_date < DATEADD('month', -6, CURRENT_DATE()) 
                          THEN c.total_contribution_dkk END) 
            THEN 'Increasing'
            WHEN AVG(CASE WHEN c.contribution_date >= DATEADD('month', -6, CURRENT_DATE()) 
                          THEN c.total_contribution_dkk END) < 
                 AVG(CASE WHEN c.contribution_date < DATEADD('month', -6, CURRENT_DATE()) 
                          THEN c.total_contribution_dkk END) 
            THEN 'Decreasing'
            ELSE 'Stable'
        END AS contribution_trend
    FROM SILVER.MEMBERS_CLEAN m
    LEFT JOIN SILVER.CONTRIBUTIONS_ENRICHED c ON m.cpr_number = c.cpr_number
    GROUP BY m.cpr_number, m.full_name, m.age, m.gender;
    
    -- Log execution
    INSERT INTO ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG (
        task_name, 
        rows_processed, 
        execution_time
    )
    SELECT 
        'TASK_MEMBER_CONTRIBUTION_SUMMARY',
        COUNT(*),
        CURRENT_TIMESTAMP()
    FROM GOLD.MEMBER_CONTRIBUTION_SUMMARY;
END;

-- ============================================================================
-- STEP 6: Create Task Execution Log Table
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS ATP_GOVERNANCE.METADATA;

CREATE TABLE IF NOT EXISTS ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG (
    log_id NUMBER AUTOINCREMENT PRIMARY KEY,
    task_name VARCHAR(200),
    rows_processed NUMBER,
    execution_time TIMESTAMP_LTZ,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- STEP 7: Add Comments to Tasks
-- ============================================================================

ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN 
SET COMMENT = 'Task to populate SILVER.MEMBERS_CLEAN from RAW.MEMBERS';

ALTER TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED 
SET COMMENT = 'Task to enrich contributions with member and employer data';

ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY 
SET COMMENT = 'Task to create member contribution summary analytics';

-- ============================================================================
-- STEP 8: Resume Tasks (Start the Task Graph)
-- ============================================================================

-- Tasks are created in SUSPENDED state by default
-- Resume them to activate the task graph

ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY RESUME;
ALTER TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED RESUME;
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN RESUME;

-- ============================================================================
-- MONITORING QUERIES
-- ============================================================================

-- View task graph (dependencies)
SELECT 
    name AS task_name,
    state AS task_state,
    schedule AS schedule_info,
    predecessors AS depends_on,
    warehouse AS warehouse_used,
    comment AS description
FROM TABLE(INFORMATION_SCHEMA.TASK_DEPENDENTS(
    TASK_NAME => 'ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN',
    RECURSIVE => TRUE
))
ORDER BY name;

-- View task execution history
SELECT 
    name AS task_name,
    state AS execution_state,
    scheduled_time,
    query_start_time,
    completed_time,
    DATEDIFF('second', query_start_time, completed_time) AS duration_seconds,
    error_code,
    error_message
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -7, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 100
))
WHERE database_name = 'ATP_PENSION'
ORDER BY scheduled_time DESC;

-- View custom execution log
SELECT 
    task_name,
    rows_processed,
    execution_time,
    DATEDIFF('second', LAG(execution_time) OVER (PARTITION BY task_name ORDER BY execution_time), execution_time) AS seconds_since_last_run
FROM ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG
ORDER BY execution_time DESC
LIMIT 50;

-- ============================================================================
-- MANUAL EXECUTION (For Testing)
-- ============================================================================

-- ⚠️ IMPORTANT: You can only execute the ROOT task manually!
-- Dependent tasks (with AFTER clause) will run automatically after their predecessor.

-- Execute ONLY the root task (Task 1)
-- This will trigger Task 2 and Task 3 automatically
EXECUTE TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN;

-- ❌ DO NOT execute dependent tasks manually - they will fail!
-- Tasks 2 and 3 will run automatically when Task 1 completes

-- Monitor execution to see the chain reaction:
SELECT 
    name,
    state,
    scheduled_time,
    query_start_time,
    completed_time,
    DATEDIFF('second', query_start_time, completed_time) AS duration_seconds
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('minute', -10, CURRENT_TIMESTAMP())
))
WHERE database_name = 'ATP_PENSION'
ORDER BY scheduled_time DESC;

-- ============================================================================
-- SUSPEND TASKS (When Not Needed)
-- ============================================================================

-- Suspend tasks to stop automatic execution (and save credits)
-- ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN SUSPEND;
-- ALTER TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED SUSPEND;
-- ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY SUSPEND;

-- ============================================================================
-- COMPARISON: dbt vs Snowflake Tasks
-- ============================================================================

/*
┌─────────────────────────────────────────────────────────────────────────┐
│                    dbt vs Snowflake Tasks                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Aspect           │ dbt                    │ Snowflake Tasks            │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Orchestration    │ External (dbt Cloud,   │ Native Snowflake          │
│                  │ Airflow, GitHub        │ (serverless)              │
│                  │ Actions)               │                           │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Scheduling       │ Requires external tool │ Built-in CRON or AFTER    │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Dependencies     │ Via {{ ref() }}        │ Via AFTER clause          │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Testing          │ Built-in tests         │ Manual SQL                │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Documentation    │ Auto-generated docs    │ Manual comments           │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Incremental      │ Easy (incremental      │ Manual logic              │
│ Updates          │ materialization)       │                           │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Version Control  │ Git-native             │ Store SQL in Git          │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Observability    │ dbt Cloud UI or logs   │ TASK_HISTORY()            │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Cost             │ dbt Cloud license or   │ Serverless compute        │
│                  │ self-hosted            │ (pay per second)          │
├──────────────────┼────────────────────────┼────────────────────────────┤
│ Best For         │ Complex transformations│ Simple, scheduled ETL     │
│                  │ Dev/test/prod workflow │ Native Snowflake ops      │
│                  │ Team collaboration     │ Minimal external tools    │
└──────────────────┴────────────────────────┴────────────────────────────┘

RECOMMENDATION for ATP:
- Use dbt for development, testing, and complex transformations
- Use Snowflake Tasks for production scheduling (if no Airflow/dbt Cloud)
- Best: dbt + dbt Cloud or GitHub Actions for full DevOps workflow
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT '✅ Snowflake Task Graph Created!' AS status,
       'View task dependencies in Snowflake UI → Data → Databases → ATP_PENSION → Tasks' AS next_step,
       'Tasks will run daily at 2 AM UTC (or execute manually for testing)' AS scheduling;

