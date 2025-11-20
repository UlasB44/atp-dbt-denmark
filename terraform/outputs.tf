output "environment" {
  description = "Deployed environment"
  value       = var.environment
}

output "warehouses" {
  description = "Created Snowflake warehouses"
  value = {
    etl        = snowflake_warehouse.atp_etl_wh.name
    bi         = snowflake_warehouse.atp_bi_wh.name
    compliance = snowflake_warehouse.atp_compliance_wh.name
  }
}

output "warehouse_sizes" {
  description = "Warehouse sizes"
  value = {
    etl        = snowflake_warehouse.atp_etl_wh.warehouse_size
    bi         = snowflake_warehouse.atp_bi_wh.warehouse_size
    compliance = snowflake_warehouse.atp_compliance_wh.warehouse_size
  }
}

output "databases" {
  description = "Created Snowflake databases"
  value = {
    pension     = snowflake_database.atp_pension.name
    housing     = snowflake_database.atp_housing_benefits.name
    integration = snowflake_database.atp_integration.name
    governance  = snowflake_database.atp_governance.name
  }
}

output "schemas" {
  description = "Created schemas by database"
  value = {
    pension = {
      raw    = snowflake_schema.pension_raw.name
      silver = snowflake_schema.pension_silver.name
      gold   = snowflake_schema.pension_gold.name
    }
    housing = {
      raw    = snowflake_schema.housing_raw.name
      silver = snowflake_schema.housing_silver.name
      gold   = snowflake_schema.housing_gold.name
    }
    integration = {
      raw    = snowflake_schema.integration_raw.name
      silver = snowflake_schema.integration_silver.name
    }
    governance = {
      metadata   = snowflake_schema.governance_metadata.name
      governance = snowflake_schema.governance_governance.name
    }
  }
}

output "resource_monitor" {
  description = "Resource monitor for cost control"
  value = {
    name         = snowflake_resource_monitor.atp_monthly_monitor.name
    credit_quota = snowflake_resource_monitor.atp_monthly_monitor.credit_quota
  }
}

output "summary" {
  description = "Infrastructure summary"
  value = {
    environment          = var.environment
    warehouses           = 3
    databases            = 4
    schemas              = 10
    monitor_credit_quota = var.monthly_credit_quota
  }
}

