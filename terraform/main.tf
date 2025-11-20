terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.94"
    }
  }
}

provider "snowflake" {
  account  = var.snowflake_account
  user     = var.snowflake_user
  password = var.snowflake_password
  role     = "ACCOUNTADMIN"
}

# ===========================================================================
# WAREHOUSES
# ===========================================================================

resource "snowflake_warehouse" "atp_etl_wh" {
  name           = "${upper(var.environment)}_ATP_ETL_WH"
  warehouse_size = upper(var.etl_warehouse_size)
  auto_suspend   = 60
  auto_resume    = true
  comment        = "[${var.environment}] Warehouse for ETL and data transformation workloads"
}

resource "snowflake_warehouse" "atp_bi_wh" {
  name           = "${upper(var.environment)}_ATP_BI_WH"
  warehouse_size = upper(var.bi_warehouse_size)
  auto_suspend   = 60
  auto_resume    = true
  comment        = "[${var.environment}] Warehouse for BI and analytics queries"
}

resource "snowflake_warehouse" "atp_compliance_wh" {
  name           = "${upper(var.environment)}_ATP_COMPLIANCE_WH"
  warehouse_size = upper(var.compliance_warehouse_size)
  auto_suspend   = 60
  auto_resume    = true
  comment        = "[${var.environment}] Warehouse for compliance and audit workloads"
}

# ===========================================================================
# DATABASES
# ===========================================================================

resource "snowflake_database" "atp_pension" {
  name    = "${upper(var.environment)}_ATP_PENSION"
  comment = "[${var.environment}] ATP pension administration data"
}

resource "snowflake_database" "atp_housing_benefits" {
  name    = "${upper(var.environment)}_ATP_HOUSING_BENEFITS"
  comment = "[${var.environment}] ATP housing benefits data"
}

resource "snowflake_database" "atp_integration" {
  name    = "${upper(var.environment)}_ATP_INTEGRATION"
  comment = "[${var.environment}] External system integration data (SKAT, BBR, CPR)"
}

resource "snowflake_database" "atp_governance" {
  name    = "${upper(var.environment)}_ATP_GOVERNANCE"
  comment = "[${var.environment}] Governance, metadata, and audit data"
}

# ===========================================================================
# SCHEMAS - PENSION
# ===========================================================================

resource "snowflake_schema" "pension_raw" {
  database = snowflake_database.atp_pension.name
  name     = "RAW"
  comment  = "Raw pension data"
}

resource "snowflake_schema" "pension_silver" {
  database = snowflake_database.atp_pension.name
  name     = "SILVER"
  comment  = "Cleansed and enriched pension data"
}

resource "snowflake_schema" "pension_gold" {
  database = snowflake_database.atp_pension.name
  name     = "GOLD"
  comment  = "Business KPIs and aggregates"
}

# ===========================================================================
# SCHEMAS - HOUSING BENEFITS
# ===========================================================================

resource "snowflake_schema" "housing_raw" {
  database = snowflake_database.atp_housing_benefits.name
  name     = "RAW"
  comment  = "Raw housing benefits data"
}

resource "snowflake_schema" "housing_silver" {
  database = snowflake_database.atp_housing_benefits.name
  name     = "SILVER"
  comment  = "Cleansed housing benefits data"
}

resource "snowflake_schema" "housing_gold" {
  database = snowflake_database.atp_housing_benefits.name
  name     = "GOLD"
  comment  = "Housing benefits analytics"
}

# ===========================================================================
# SCHEMAS - INTEGRATION
# ===========================================================================

resource "snowflake_schema" "integration_raw" {
  database = snowflake_database.atp_integration.name
  name     = "RAW"
  comment  = "Raw external system data"
}

resource "snowflake_schema" "integration_silver" {
  database = snowflake_database.atp_integration.name
  name     = "SILVER"
  comment  = "Cleansed integration data"
}

# ===========================================================================
# SCHEMAS - GOVERNANCE
# ===========================================================================

resource "snowflake_schema" "governance_metadata" {
  database = snowflake_database.atp_governance.name
  name     = "METADATA"
  comment  = "Metadata and documentation"
}

resource "snowflake_schema" "governance_governance" {
  database = snowflake_database.atp_governance.name
  name     = "GOVERNANCE"
  comment  = "Governance policies and controls"
}

# ===========================================================================
# RESOURCE MONITOR
# ===========================================================================

resource "snowflake_resource_monitor" "atp_monthly_monitor" {
  name            = "${upper(var.environment)}_ATP_MONTHLY_MONITOR"
  credit_quota    = var.monthly_credit_quota
  frequency       = "MONTHLY"
  start_timestamp = "IMMEDIATELY"
  
  notify_triggers = [50, 75, 90]
  suspend_trigger = 100
}

