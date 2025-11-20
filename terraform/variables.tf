variable "snowflake_account" {
  description = "Snowflake account identifier"
  type        = string
  default     = "UTYEYAD-XT83149"
}

variable "snowflake_user" {
  description = "Snowflake username"
  type        = string
  default     = "admin"
}

variable "snowflake_password" {
  description = "Snowflake password (use TF_VAR_snowflake_password or .tfvars file)"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "etl_warehouse_size" {
  description = "Size of ETL warehouse"
  type        = string
  default     = "X-SMALL"
  
  validation {
    condition     = contains(["X-SMALL", "SMALL", "MEDIUM", "LARGE", "X-LARGE"], upper(var.etl_warehouse_size))
    error_message = "Warehouse size must be a valid Snowflake size."
  }
}

variable "bi_warehouse_size" {
  description = "Size of BI warehouse"
  type        = string
  default     = "X-SMALL"
}

variable "compliance_warehouse_size" {
  description = "Size of Compliance warehouse"
  type        = string
  default     = "X-SMALL"
}

variable "monthly_credit_quota" {
  description = "Monthly credit quota for resource monitor"
  type        = number
  default     = 100
  
  validation {
    condition     = var.monthly_credit_quota > 0 && var.monthly_credit_quota <= 10000
    error_message = "Credit quota must be between 1 and 10000."
  }
}

