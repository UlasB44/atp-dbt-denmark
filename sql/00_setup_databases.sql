-- ============================================================================
-- ATP Denmark - Database Architecture Setup
-- ============================================================================
-- Purpose: Create core databases, schemas, and warehouses
-- Run As: ACCOUNTADMIN
-- Idempotent: Yes (safe to run multiple times)
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- WAREHOUSES: Performance-optimized for different workloads
-- ============================================================================

-- ETL warehouse for data loading and transformations
CREATE WAREHOUSE IF NOT EXISTS ATP_ETL_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'ETL workload - data loading and transformations';

-- BI warehouse for analytics queries
CREATE WAREHOUSE IF NOT EXISTS ATP_BI_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'BI workload - dashboards and reporting';

-- Compliance warehouse for governance queries
CREATE WAREHOUSE IF NOT EXISTS ATP_COMPLIANCE_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compliance workload - audit queries and governance';

-- ============================================================================
-- DATABASE 1: ATP_PENSION (Core Pension Administration)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ATP_PENSION
    COMMENT = 'ATP Livslang Pension - Core pension administration for ~5.2M Danish workers';

-- RAW schema: Landing zone for source data
CREATE SCHEMA IF NOT EXISTS ATP_PENSION.RAW
    COMMENT = 'Raw data from source systems - members, employers, contributions';

-- SILVER schema: Cleansed and enriched data
CREATE SCHEMA IF NOT EXISTS ATP_PENSION.SILVER
    COMMENT = 'Cleansed pension data with business logic applied';

-- GOLD schema: Analytics-ready aggregates
CREATE SCHEMA IF NOT EXISTS ATP_PENSION.GOLD
    COMMENT = 'Analytics layer - KPIs, projections, compliance metrics';

-- ============================================================================
-- DATABASE 2: ATP_HOUSING_BENEFITS (Welfare Administration)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ATP_HOUSING_BENEFITS
    COMMENT = 'Housing benefits (boligstøtte) administration on behalf of Danish government';

CREATE SCHEMA IF NOT EXISTS ATP_HOUSING_BENEFITS.RAW
    COMMENT = 'Raw housing benefit applications and assessments';

CREATE SCHEMA IF NOT EXISTS ATP_HOUSING_BENEFITS.SILVER
    COMMENT = 'Calculated housing benefits with eligibility checks';

CREATE SCHEMA IF NOT EXISTS ATP_HOUSING_BENEFITS.GOLD
    COMMENT = 'Payment accuracy and compliance metrics';

-- ============================================================================
-- DATABASE 3: ATP_INTEGRATION (External Systems)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ATP_INTEGRATION
    COMMENT = 'External system integrations - SKAT, BBR, CPR registry';

CREATE SCHEMA IF NOT EXISTS ATP_INTEGRATION.RAW
    COMMENT = 'Raw data from external Danish government systems';

CREATE SCHEMA IF NOT EXISTS ATP_INTEGRATION.SILVER
    COMMENT = 'Integrated and reconciled external data';

-- ============================================================================
-- DATABASE 4: ATP_GOVERNANCE (Data Catalog & Compliance)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS ATP_GOVERNANCE
    COMMENT = 'Data governance, catalog, and compliance';

CREATE SCHEMA IF NOT EXISTS ATP_GOVERNANCE.METADATA
    COMMENT = 'Data catalog, products, and access requests';

CREATE SCHEMA IF NOT EXISTS ATP_GOVERNANCE.GOVERNANCE
    COMMENT = 'Governance policies, tags, audit trails';

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 'Database Architecture Created' AS status,
       '4 databases, 10 schemas, 3 warehouses' AS configuration;

-- View created objects
SHOW DATABASES LIKE 'ATP_%';
SHOW WAREHOUSES LIKE 'ATP_%';

