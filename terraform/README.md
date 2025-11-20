# Terraform Infrastructure as Code - ATP Denmark

## Overview

This directory contains Terraform configurations for provisioning and managing ATP Denmark's Snowflake infrastructure.

## Infrastructure Components

### Warehouses (3)
- **ETL Warehouse**: Data loading and transformation workloads
- **BI Warehouse**: Analytics queries and dashboards
- **Compliance Warehouse**: Governance and audit queries

### Databases (4)
- **ATP_PENSION**: Pension administration data (RAW → SILVER → GOLD)
- **ATP_HOUSING_BENEFITS**: Housing benefits data (RAW → SILVER → GOLD)
- **ATP_INTEGRATION**: External system data (SKAT, BBR, CPR)
- **ATP_GOVERNANCE**: Metadata, catalog, and governance policies

### Schemas (10)
- Each database has appropriate schemas for data layers (RAW, SILVER, GOLD, METADATA, etc.)

### Resource Monitor
- Monthly credit quota with alerts at 50%, 75%, 90%
- Auto-suspend at 100% to prevent overruns

---

## Quick Start

### Prerequisites

1. **Install Terraform** (>= 1.6.0)
 ```bash
 # macOS
 brew install terraform
 
 # Or download from: https://www.terraform.io/downloads
 ```

2. **Snowflake Credentials**
 - Account: `UTYEYAD-XT83149`
 - User: `admin` (or your user with ACCOUNTADMIN role)
 - Password: Set via environment variable

### Set Credentials

```bash
## Option 1: Environment variable (recommended)
export TF_VAR_snowflake_password="your-password-here"

## Option 2: Create terraform.tfvars (DO NOT commit this file!)
echo 'snowflake_password = "your-password-here"' > terraform.tfvars
```

---

## Deployment

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan Deployment (Review Changes)

```bash
## DEV environment
terraform plan -var-file="environments/dev.tfvars"

## TEST environment
terraform plan -var-file="environments/test.tfvars"
```

### 3. Apply Configuration

```bash
## Deploy to DEV
terraform apply -var-file="environments/dev.tfvars"

## Deploy to TEST
terraform apply -var-file="environments/test.tfvars"
```

### 4. View Outputs

```bash
terraform output
```

---

## Environment-Specific Configurations

### Development (`environments/dev.tfvars`)
- Small warehouses (X-SMALL)
- 50 credit monthly quota
- Suitable for individual developers

### Test (`environments/test.tfvars`)
- Slightly larger (SMALL for ETL)
- 100 credit monthly quota
- Pre-production testing

### Production (`environments/prod.tfvars`)
- Larger warehouses (MEDIUM for ETL)
- 500 credit monthly quota
- **Note**: PROD is out of scope for the demo

---

## File Structure

```
terraform/
 main.tf                    # Main infrastructure definitions
 variables.tf               # Variable declarations with validation
 outputs.tf                 # Output values after deployment
 environments/
   dev.tfvars            # DEV environment config
   test.tfvars           # TEST environment config
   prod.tfvars           # PROD environment config (future)
 .gitignore                # Ignore sensitive files
 README.md                 # This file
```

---

## Security Best Practices

### DO:
- Use environment variables for passwords (`TF_VAR_snowflake_password`)
- Store state files securely (consider remote state with S3/Azure Storage)
- Use `.gitignore` to exclude `*.tfvars`, `*.tfstate`, `.terraform/`
- Review `terraform plan` output before applying
- Use service accounts with minimal permissions (not ACCOUNTADMIN in production)

### DON'T:
- Commit passwords or sensitive data to Git
- Share state files publicly
- Run `terraform destroy` without careful review
- Use ACCOUNTADMIN role in production (use custom roles instead)

---

## Testing Changes

### Dry Run (No Changes Made)
```bash
terraform plan -var-file="environments/dev.tfvars"
```

### Apply with Auto-Approve (CI/CD Only)
```bash
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

### Destroy Infrastructure (Careful!)
```bash
## Only use in DEV/TEST environments
terraform destroy -var-file="environments/dev.tfvars"
```

---

## Resource Summary

After deployment, you'll have:

| Resource Type | Count | Naming Pattern |
|--------------|-------|----------------|
| Warehouses | 3 | `{ENV}_ATP_{TYPE}_WH` |
| Databases | 4 | `{ENV}_ATP_{DOMAIN}` |
| Schemas | 10 | `{DATABASE}.{LAYER}` |
| Resource Monitor | 1 | `{ENV}_ATP_MONTHLY_MONITOR` |

**Example (DEV):**
- `DEV_ATP_ETL_WH`
- `DEV_ATP_PENSION`
- `DEV_ATP_PENSION.SILVER`

---

## CI/CD Integration

### Azure DevOps Pipeline

This Terraform configuration is integrated with Azure DevOps:

1. **On PR**: `terraform plan` runs automatically
2. **On Merge to Main**: `terraform apply` deploys to DEV
3. **Manual Approval**: Required for TEST/PROD

See `../ci/azure-pipelines.yml` for pipeline configuration.

---

## Troubleshooting

### Error: Invalid Credentials
```bash
## Check credentials
echo $TF_VAR_snowflake_password

## Test Snowflake connection
snowsql -a UTYEYAD-XT83149 -u admin
```

### Error: Resource Already Exists
```bash
## Import existing resource
terraform import snowflake_database.atp_pension DEV_ATP_PENSION
```

### Error: State Lock
```bash
## If using remote state and lock is stuck
terraform force-unlock <LOCK_ID>
```

---

## Additional Resources

- [Terraform Snowflake Provider Docs](https://registry.terraform.io/providers/Snowflake-Labs/snowflake/latest/docs)
- [Snowflake Resource Management](https://docs.snowflake.com/en/user-guide/resource-monitors)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

## Support

- **Owner**: ATP Data Platform Team
- **Issues**: GitHub Issues in this repository
- **Documentation**: See `../docs/` for architecture diagrams

---

## Change Log

### Version 1.0.0 (Current)
-  Multi-environment support (DEV, TEST, PROD)
-  All 4 databases with appropriate schemas
-  3 warehouses (ETL, BI, Compliance)
-  Resource monitor with cost controls
-  Variable validation
-  Comprehensive outputs

