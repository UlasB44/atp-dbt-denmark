-- ============================================================================
-- ATP Denmark - Git Integration Setup
-- ============================================================================
-- Purpose: Configure GitHub integration for Snowflake Native dbt
-- Run As: ACCOUNTADMIN
-- Prerequisites: GitHub repository https://github.com/UlasB44/atp-dbt-denmark
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE ATP_GOVERNANCE;
USE SCHEMA METADATA;

-- ============================================================================
-- 1. CREATE API INTEGRATION FOR GITHUB
-- ============================================================================

CREATE OR REPLACE API INTEGRATION atp_github_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/UlasB44/')
    ENABLED = TRUE
    COMMENT = 'API integration for UlasB44 GitHub repositories';

-- ============================================================================
-- 2. CREATE GIT REPOSITORY STAGE
-- ============================================================================

CREATE OR REPLACE GIT REPOSITORY atp_dbt_repo
    API_INTEGRATION = atp_github_integration
    ORIGIN = 'https://github.com/UlasB44/atp-dbt-denmark'
    COMMENT = 'ATP Denmark dbt project repository';

-- ============================================================================
-- 3. FETCH LATEST FROM GIT
-- ============================================================================

ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- ============================================================================
-- 4. VERIFY REPOSITORY CONTENTS
-- ============================================================================

-- List files in repository
LS @atp_dbt_repo/branches/main/;

-- Check dbt project structure (NOW IN dbt/ FOLDER!)
LS @atp_dbt_repo/branches/main/dbt/;

-- ============================================================================
-- 5. DROP OLD DBT PROJECT (if exists)
-- ============================================================================

DROP DBT PROJECT IF EXISTS atp_dbt_project;

-- ============================================================================
-- 6. CREATE DBT PROJECT OBJECT (UPDATED PATH!)
-- ============================================================================

-- IMPORTANT: GIT_PATH now points to 'dbt' folder where dbt_project.yml lives
CREATE OR REPLACE DBT PROJECT atp_dbt_project
    GIT_REPOSITORY = atp_dbt_repo
    GIT_BRANCH = 'main'
    GIT_PATH = 'dbt'  -- THIS IS THE KEY CHANGE!
    DBT_VERSION = 'v1.7'
    PROFILE_NAME = 'atp_denmark'
    TARGET = 'dev'
    COMMENT = 'ATP Denmark native dbt project - Pension & Housing Benefits Analytics';

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Grant to ATP roles
GRANT USAGE ON GIT REPOSITORY atp_dbt_repo TO ROLE ATP_ADMIN;
GRANT USAGE ON GIT REPOSITORY atp_dbt_repo TO ROLE ATP_DATA_ENGINEER;

GRANT OPERATE ON DBT PROJECT atp_dbt_project TO ROLE ATP_ADMIN;
GRANT OPERATE ON DBT PROJECT atp_dbt_project TO ROLE ATP_DATA_ENGINEER;

-- ============================================================================
-- 8. TEST DBT PROJECT (compile only)
-- ============================================================================

EXECUTE DBT PROJECT atp_dbt_project
    COMMAND = 'compile';

-- View results
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 'Git Integration Complete' AS status,
       'GitHub connected, dbt project ready with GIT_PATH=dbt' AS configuration;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

-- Sync latest code from Git
-- ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- Run dbt models
-- EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';

-- Run dbt tests
-- EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';

-- Run specific model
-- EXECUTE DBT PROJECT atp_dbt_project 
-- COMMAND = 'run --select member_contribution_summary';

-- View execution history
-- SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.DBT_PROJECT_EXECUTION_HISTORY
-- WHERE PROJECT_NAME = 'ATP_DBT_PROJECT'
-- ORDER BY START_TIME DESC;
