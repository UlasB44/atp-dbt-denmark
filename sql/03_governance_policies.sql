-- ============================================================================
-- ATP Denmark - Data Governance Policies
-- ============================================================================
-- Purpose: Implement masking policies, row access policies, and tags
-- Run As: ACCOUNTADMIN
-- GDPR Compliance: PII masking and data classification
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. MASKING POLICY FOR CPR NUMBERS (Danish Personal ID)
-- ============================================================================

USE DATABASE ATP_PENSION;
USE SCHEMA SILVER;

CREATE OR REPLACE MASKING POLICY cpr_mask AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ATP_ADMIN', 'ATP_COMPLIANCE_OFFICER') THEN val
    WHEN CURRENT_ROLE() = 'ATP_DATA_ENGINEER' THEN 
        -- Partial masking for engineers (show only birth date part)
        SUBSTRING(val, 1, 6) || '-****'
    ELSE '******-****'
  END
  COMMENT = 'GDPR: Mask CPR numbers except for authorized roles';

-- Apply to members table (if exists)
-- ALTER TABLE ATP_PENSION.SILVER.MEMBERS_CLEAN
--   MODIFY COLUMN cpr_number
--   SET MASKING POLICY cpr_mask;

-- ============================================================================
-- 2. MASKING POLICY FOR ADDRESSES
-- ============================================================================

CREATE OR REPLACE MASKING POLICY address_mask AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ATP_ADMIN', 'ATP_COMPLIANCE_OFFICER') THEN val
    ELSE '***MASKED***'
  END
  COMMENT = 'GDPR: Mask physical addresses';

-- ============================================================================
-- 3. DATA CLASSIFICATION TAGS
-- ============================================================================

USE DATABASE ATP_GOVERNANCE;
USE SCHEMA GOVERNANCE;

-- Create classification tags
CREATE TAG IF NOT EXISTS data_classification
    ALLOWED_VALUES 'PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'PII', 'SENSITIVE'
    COMMENT = 'GDPR data classification tag';

CREATE TAG IF NOT EXISTS data_domain
    ALLOWED_VALUES 'PENSION', 'HOUSING', 'INTEGRATION', 'GOVERNANCE'
    COMMENT = 'Business domain tag';

CREATE TAG IF NOT EXISTS cost_center
    COMMENT = 'Chargeback attribution for FinOps';

CREATE TAG IF NOT EXISTS data_owner
    COMMENT = 'Data product owner or steward';

-- ============================================================================
-- 4. APPLY TAGS TO DATABASES
-- ============================================================================

-- Tag databases
ALTER DATABASE ATP_PENSION SET TAG ATP_GOVERNANCE.GOVERNANCE.data_classification = 'PII';
ALTER DATABASE ATP_PENSION SET TAG ATP_GOVERNANCE.GOVERNANCE.data_domain = 'PENSION';

ALTER DATABASE ATP_HOUSING_BENEFITS SET TAG ATP_GOVERNANCE.GOVERNANCE.data_classification = 'PII';
ALTER DATABASE ATP_HOUSING_BENEFITS SET TAG ATP_GOVERNANCE.GOVERNANCE.data_domain = 'HOUSING';

ALTER DATABASE ATP_INTEGRATION SET TAG ATP_GOVERNANCE.GOVERNANCE.data_classification = 'CONFIDENTIAL';
ALTER DATABASE ATP_INTEGRATION SET TAG ATP_GOVERNANCE.GOVERNANCE.data_domain = 'INTEGRATION';

-- ============================================================================
-- 5. ROW ACCESS POLICY (Example - Department-based access)
-- ============================================================================

-- Create row access policy (commented - requires metadata table)
-- CREATE OR REPLACE ROW ACCESS POLICY department_access AS (department_id STRING) RETURNS BOOLEAN ->
--   CURRENT_ROLE() = 'ATP_ADMIN'
--   OR EXISTS (
--     SELECT 1
--     FROM ATP_GOVERNANCE.METADATA.USER_DEPARTMENT_ACCESS
--     WHERE user_name = CURRENT_USER()
--       AND department_id = ATP_PENSION.SILVER.MEMBERS_CLEAN.department_id
--   );

-- ============================================================================
-- 6. QUERY TAGS FOR OBSERVABILITY
-- ============================================================================

-- Set default query tags for session
ALTER SESSION SET QUERY_TAG = 'project=atp_denmark;environment=dev';

-- ============================================================================
-- 7. GOVERNANCE METADATA TABLES
-- ============================================================================

USE SCHEMA ATP_GOVERNANCE.METADATA;

-- Data product catalog
CREATE TABLE IF NOT EXISTS data_products (
    product_id STRING PRIMARY KEY,
    product_name STRING NOT NULL,
    product_description STRING,
    domain STRING,
    owner STRING,
    status STRING,  -- 'draft', 'validated', 'published', 'deprecated'
    validation_date TIMESTAMP_NTZ,
    dq_score FLOAT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Data lineage tracking
CREATE TABLE IF NOT EXISTS data_lineage (
    lineage_id STRING PRIMARY KEY,
    source_product_id STRING,
    target_product_id STRING,
    transformation_type STRING,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Access requests and approvals
CREATE TABLE IF NOT EXISTS access_requests (
    request_id STRING PRIMARY KEY,
    user_name STRING,
    product_id STRING,
    access_level STRING,  -- 'read', 'write', 'admin'
    business_justification STRING,
    requested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    approved_by STRING,
    approved_at TIMESTAMP_NTZ,
    status STRING  -- 'pending', 'approved', 'rejected'
);

-- ============================================================================
-- 8. AUDIT LOGGING
-- ============================================================================

USE SCHEMA ATP_GOVERNANCE.GOVERNANCE;

-- Create view for sensitive data access audit
CREATE OR REPLACE VIEW sensitive_data_access_log AS
SELECT
    query_id,
    query_text,
    user_name,
    role_name,
    database_name,
    schema_name,
    start_time,
    end_time,
    total_elapsed_time,
    rows_produced,
    execution_status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE database_name IN ('ATP_PENSION', 'ATP_HOUSING_BENEFITS', 'ATP_INTEGRATION')
    AND query_text ILIKE '%cpr_number%'
    AND start_time >= DATEADD('day', -90, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 'Governance Policies Applied' AS status,
       'Masking, tags, and audit logging configured' AS configuration;

-- View applied tags
SHOW TAGS IN DATABASE ATP_GOVERNANCE;

-- View masking policies
SHOW MASKING POLICIES IN DATABASE ATP_PENSION;

