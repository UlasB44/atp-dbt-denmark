# SQL Database Setup Scripts - ATP Denmark

## Overview

This directory contains SQL scripts for setting up the ATP Denmark Snowflake infrastructure manually (without Terraform). These scripts are idempotent and safe to run multiple times.

---

## Execution Order

Run these scripts **in order** as the `ACCOUNTADMIN` role:

| Order | Script | Purpose | Time |
|-------|--------|---------|------|
| 1 | `00_setup_databases.sql` | Create databases, schemas, warehouses | ~30 sec |
| 2 | `01_setup_roles.sql` | Create roles and grant permissions | ~20 sec |
| 3 | `02_setup_git_integration.sql` | Configure GitHub + dbt integration | ~60 sec |
| 4 | `03_governance_policies.sql` | Apply masking, tags, audit logging | ~30 sec |

**Total Setup Time:** ~2-3 minutes

---

## Script Details

### `00_setup_databases.sql`
**Creates:**
- 3 Warehouses (ETL, BI, Compliance)
- 4 Databases (PENSION, HOUSING_BENEFITS, INTEGRATION, GOVERNANCE)
- 10 Schemas (RAW, SILVER, GOLD across domains)

**Run:**
```sql
-- In Snowsight or snowsql
USE ROLE ACCOUNTADMIN;
-- Copy/paste entire script
```

---

### `01_setup_roles.sql`
**Creates:**
- `ATP_ADMIN`: Full access to all ATP resources
- `ATP_DATA_ENGINEER`: Read/write access to transformation layers
- `ATP_ANALYST`: Read-only access to SILVER and GOLD
- `ATP_COMPLIANCE_OFFICER`: Audit and governance access

**Permissions:**
- Warehouse usage grants
- Database/schema access
- Table-level permissions (current and future)

---

### `02_setup_git_integration.sql`
**Configures:**
- GitHub API integration
- Git repository stage pointing to `atp-dbt-denmark`
- Snowflake Native dbt project
- Permissions for ATP roles

**Prerequisites:**
- GitHub repository: `https://github.com/UlasB44/atp-dbt-denmark`
- Repository must be public or you need a Git secret

**Usage After Setup:**
```sql
-- Sync latest code
ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- Run dbt models
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';

-- Run dbt tests
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';
```

---

### `03_governance_policies.sql`
**Implements:**
- **Masking Policies**: CPR numbers (Danish PII), addresses
- **Data Classification Tags**: PUBLIC, INTERNAL, CONFIDENTIAL, PII
- **Domain Tags**: PENSION, HOUSING, INTEGRATION
- **Audit Logging**: Sensitive data access tracking
- **Metadata Tables**: Data products, lineage, access requests

**GDPR Compliance:**
- PII masked for non-privileged roles
- Audit trail for sensitive data access
- Data classification for all databases

---

## Security Best Practices

### Before Running Scripts:
1.  Review scripts to understand changes
2.  Ensure you have `ACCOUNTADMIN` role
3.  Backup any existing objects (if applicable)
4.  Run in **DEV/TEST** environment first

### After Running Scripts:
1.  Verify objects created: `SHOW DATABASES LIKE 'ATP_%';`
2.  Test role permissions: `USE ROLE ATP_ANALYST; SELECT * FROM ATP_PENSION.GOLD.<table>;`
3.  Grant roles to actual users: `GRANT ROLE ATP_ANALYST TO USER <username>;`

---

## Verification

### 1. Check Databases
```sql
SHOW DATABASES LIKE 'ATP_%';
-- Should show: ATP_PENSION, ATP_HOUSING_BENEFITS, ATP_INTEGRATION, ATP_GOVERNANCE
```

### 2. Check Warehouses
```sql
SHOW WAREHOUSES LIKE 'ATP_%';
-- Should show: ATP_ETL_WH, ATP_BI_WH, ATP_COMPLIANCE_WH
```

### 3. Check Roles
```sql
SHOW ROLES LIKE 'ATP_%';
-- Should show: ATP_ADMIN, ATP_DATA_ENGINEER, ATP_ANALYST, ATP_COMPLIANCE_OFFICER
```

### 4. Test Git Integration
```sql
USE ROLE ACCOUNTADMIN;
LS @atp_dbt_repo/branches/main/;
-- Should show dbt project files
```

### 5. Test dbt Project
```sql
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'compile';
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
-- Should show compiled models
```

---

## Terraform vs SQL Scripts

| Aspect | Terraform (Recommended) | SQL Scripts |
|--------|------------------------|-------------|
| **Idempotency** |  Guaranteed |  (with IF NOT EXISTS) |
| **State Management** |  Tracked |  Manual |
| **Version Control** |  Full history |  Manual commits |
| **Multi-Environment** |  Easy (tfvars) |  Manual editing |
| **Rollback** |  Automatic |  Manual |
| **CI/CD Integration** |  Native |  Custom scripts |
| **Documentation** |  Self-documenting |  External docs |
| **Use Case** | Production, automation | Quick setup, learning |

**Recommendation:** Use **Terraform** (`../terraform/`) for production deployments. Use **SQL scripts** for:
- Learning and exploration
- Quick manual setup
- Troubleshooting
- One-off changes

---

## Troubleshooting

### Error: Insufficient Privileges
```
SQL access control error: Insufficient privileges to operate on database
```
**Solution:** Ensure you're using `ACCOUNTADMIN` role:
```sql
USE ROLE ACCOUNTADMIN;
```

### Error: Object Already Exists
```
SQL compilation error: Object 'ATP_PENSION' already exists
```
**Solution:** This is normal! Scripts use `CREATE ... IF NOT EXISTS` so they're safe to re-run. Existing objects are preserved.

### Error: API Integration Not Allowed
```
API integration creation is restricted by policy
```
**Solution:** Your Snowflake account may have restrictions. Contact your Snowflake admin or use Terraform with appropriate permissions.

### Git Repository Fetch Fails
```
Git repository fetch failed: Repository not found
```
**Solution:**
1. Verify repository URL is correct
2. Ensure repository is public (or configure Git secret)
3. Check network connectivity

---

## Additional Resources

- **Terraform Alternative**: See `../terraform/README.md` for IaC approach
- **dbt Documentation**: See `../dbt/README.md` for transformation logic
- **Architecture Diagrams**: See `../docs/architecture.md`
- **Snowflake Docs**: [Access Control](https://docs.snowflake.com/en/user-guide/security-access-control)

---

## Support

- **Owner**: ATP Data Platform Team
- **Issues**: GitHub Issues
- **Slack**: # atp-data-engineering

---

## Change Log

### Version 1.0.0
-  Complete database architecture setup
-  Role-based access control
-  Git integration for dbt
-  GDPR-compliant governance policies
-  Audit logging and metadata tracking

