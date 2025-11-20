# ATP Denmark - dbt Data Transformation Project

## Overview

This dbt project transforms raw ATP Denmark data into analytics-ready datasets for:
- **Pension Administration**: 5.2M members, 112M+ contributions
- **Housing Benefits**: 400K+ applications
- **External Integrations**: SKAT (Tax), BBR (Building Registry), CPR (Civil Registration)

## Architecture

```
RAW → SILVER → GOLD
```

### Data Layers

| Layer | Purpose | Refresh | Materialization |
|-------|---------|---------|-----------------|
| **RAW** | Source data landing zone | Batch load | Tables |
| **SILVER** | Cleansed, validated, enriched | Real-time incremental | Incremental tables |
| **GOLD** | Business KPIs and aggregates | Daily | Tables/Views |

---

## Data Models

### Pension Domain (`models/pension/`)

#### Silver Layer
- **`members_clean`**: Validated member records with CPR validation, age calculation, and DQ flags
- **`contributions_enriched`**: Contribution transactions enriched with member/employer details, payment timing, anomaly detection

#### Gold Layer
- **`member_contribution_summary`**: Member-level contribution analytics, payment behavior, risk scoring
- **`employer_contribution_analytics`**: Employer payment compliance, late payment metrics, industry analysis

### Housing Benefits Domain (`models/housing/`)

#### Silver Layer
- **`applications_enriched`**: Housing benefit applications with member demographics, rent burden calculations

#### Gold Layer
- **`housing_benefits_summary`**: Member-level benefit history, approval rates, payment accuracy

### Integration Domain (`models/integration/`)

#### Silver Layer
- **`income_verification`**: Cross-system income validation (SKAT vs application data), variance analysis

---

## Data Quality Tests

All models include comprehensive tests enforced via dbt:

### Test Types
- **Uniqueness**: Primary keys are unique across records
- **Not Null**: Required fields always populated
- **Referential Integrity**: Foreign keys reference valid parent records
- **Accepted Values**: Enums match expected values (e.g., gender: M/F)
- **Range Checks**: Numeric values within reasonable bounds
- **Custom Tests**: Domain-specific business rules

### Running Tests

```bash
## Run all tests
dbt test

## Test specific model
dbt test --models members_clean

## Test by domain
dbt test --models pension
dbt test --models housing

## Test by layer
dbt test --models tag:silver
dbt test --models tag:gold

## Run tests in Snowflake Workspace
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';
```

---

## Quick Start

### Prerequisites

**Option 1: Local Development (VS Code)**
- Python 3.9+
- dbt-core >= 1.7.0
- dbt-snowflake >= 1.7.0

**Option 2: Snowflake Workspaces**
- Snowflake account with ATP databases
- ATP_ADMIN or ATP_DATA_ENGINEER role
- Git integration configured (see `../sql/02_setup_git_integration.sql`)

---

### Local Setup (VS Code)

#### 1. Install dbt

```bash
## Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

## Install requirements
pip install -r requirements.txt

## Verify installation
dbt --version
```

#### 2. Configure Profiles

Copy `profiles_template.yml` to `~/.dbt/profiles.yml` and fill in credentials:

```bash
cp profiles_template.yml ~/.dbt/profiles.yml
## Edit ~/.dbt/profiles.yml with your credentials
```

**Or** use environment variables:

```bash
export SNOWFLAKE_ACCOUNT="UTYEYAD-XT83149"
export SNOWFLAKE_USER="your_username"
export SNOWFLAKE_PASSWORD="your_password"
```

#### 3. Install dbt Packages

```bash
dbt deps
```

#### 4. Test Connection

```bash
dbt debug
```

---

### Running Models

#### Local (dbt CLI)

```bash
## Run all models
dbt run

## Run specific domain
dbt run --models pension
dbt run --models housing
dbt run --models integration

## Run specific layer
dbt run --models tag:silver
dbt run --models tag:gold

## Run single model
dbt run --models members_clean

## Run with dependencies
dbt run --models +member_contribution_summary  # Includes upstream deps
dbt run --models member_contribution_summary+  # Includes downstream deps

## Full refresh (rebuild from scratch)
dbt run --full-refresh

## Run and test
dbt build  # Runs models + tests + snapshots
```

#### Snowflake Workspace

```sql
-- Sync latest code from Git
ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- Run all models
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';

-- Run specific model
EXECUTE DBT PROJECT atp_dbt_project 
COMMAND = 'run --select member_contribution_summary';

-- Run tests
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';

-- Compile (dry-run)
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'compile';

-- View results
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
```

---

## Documentation

### Generate Documentation

**Local:**
```bash
## Generate docs
dbt docs generate

## Serve docs locally (opens browser)
dbt docs serve --port 8080
```

**Snowflake Workspace:**
```sql
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'docs generate';
```

Then navigate to: **Projects → dbt Projects → ATP_DBT_PROJECT → Documentation**

### View Lineage

**Local:** Open `dbt docs serve` → Click "Lineage Graph"

**Snowflake:** Navigate to **Projects → dbt Projects → ATP_DBT_PROJECT → Lineage**

---

## Python Models (Snowpark)

Alternative Python-based transformations using Snowpark:

- `python_models/members_clean_snowpark.py`
- `python_models/contributions_enriched_snowpark.py`
- `python_models/member_contribution_summary_snowpark.py`

**Run Python models:**
```bash
## Requires Snowpark session
dbt run --models python_models
```

**Note:** SQL models are preferred for performance and maintainability.

---

## Security & Compliance

### GDPR Compliance
- All PII (CPR numbers, addresses) masked via Snowflake policies
- Data classification tags applied
- Audit trail for sensitive data access

### Role-Based Access Control
- **ATP_ADMIN**: Full access
- **ATP_DATA_ENGINEER**: Read/write SILVER and GOLD
- **ATP_ANALYST**: Read-only SILVER and GOLD
- **ATP_COMPLIANCE_OFFICER**: Audit and governance

### Data Contracts
- Schema contracts defined in `schema.yml` files
- Breaking changes blocked by CI/CD tests
- Column-level documentation required

---

## Performance

### Optimization Strategies
- **Incremental Models**: Silver layer processes only changed records
- **Clustering**: Large tables clustered by date/CPR
- **Materialization**: 
- Silver: Incremental (fast refresh)
- Gold: Table (full rebuild daily)

### Warehouse Sizing
- **ETL_WH** (MEDIUM): For `dbt run`
- **BI_WH** (SMALL): For analytics queries

### Performance Monitoring
```sql
-- View dbt execution history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.DBT_PROJECT_EXECUTION_HISTORY
WHERE PROJECT_NAME = 'ATP_DBT_PROJECT'
ORDER BY START_TIME DESC;
```

---

## CI/CD Integration

### Azure DevOps Pipeline

Automated CI/CD via Azure DevOps (see `../ci/azure-pipelines.yml`):

**On Pull Request:**
1. `dbt compile` - Validate SQL syntax
2. `dbt run` - Build models in DEV
3. `dbt test` - Run all tests
4. Block merge if tests fail

**On Merge to Main:**
1. Deploy to DEV environment
2. Run full test suite
3. Manual approval for TEST/PROD

### GitHub Actions (Alternative)

Workflow files can be added to `.github/workflows/` for GitHub-based CI/CD.

---

## File Structure

```
dbt/
 analyses/                  # Ad-hoc SQL queries (not materialized)
 macros/                    # Custom Jinja macros (currently empty)
 models/
   pension/
   silver/
     members_clean.sql
     contributions_enriched.sql
     schema.yml
   gold/
       member_contribution_summary.sql
       employer_contribution_analytics.sql
       schema.yml
   housing/
   silver/
     applications_enriched.sql
     schema.yml
   gold/
       housing_benefits_summary.sql
       schema.yml
   integration/
   silver/
       income_verification.sql
       schema.yml
   sources.yml            # Source table definitions
 python_models/             # Snowpark Python models (alternative)
 seeds/                     # CSV files loaded as tables
 snapshots/                 # Type 2 SCD tracking (future use)
 dbt_project.yml            # dbt project configuration
 packages.yml               # dbt package dependencies
 profiles_template.yml      # Connection profile template
 requirements.txt           # Python dependencies
 README.md                  # This file
```

---

## dbt Packages

This project uses:

- **dbt_utils** (v1.1.1): Common macros (generate_surrogate_key, star, etc.)
- **dbt_expectations** (v0.10.1): Advanced data quality tests
- **dbt_date** (v0.10.0): Date/time utility macros

**Install packages:**
```bash
dbt deps
```

---

## Troubleshooting

### Error: Compilation Error
```
Compilation Error in model members_clean
```
**Solution:** Run `dbt compile` to see detailed SQL errors.

### Error: Database Does Not Exist
```
Database 'ATP_PENSION' does not exist
```
**Solution:** Run infrastructure setup first:
- **Terraform**: `cd ../terraform && terraform apply`
- **SQL**: Run `../sql/00_setup_databases.sql`

### Error: Connection Failed
```
Could not connect to Snowflake
```
**Solution:** 
1. Check `profiles.yml` credentials
2. Test with `dbt debug`
3. Verify network access to Snowflake

### Error: Tests Failing
```
Completed with 5 errors and 0 warnings
```
**Solution:**
1. Run `dbt test --select <failing_model>` to see details
2. Check source data quality
3. Review test definitions in `schema.yml`

---

## Support

- **Owner**: ATP Data Engineering Team
- **Slack**: # atp-data-engineering
- **Issues**: [GitHub Issues](https://github.com/UlasB44/atp-dbt-denmark/issues)
- **Documentation**: See `../docs/` for architecture diagrams

---

## SLAs

| Layer | Refresh Frequency | Latency SLA | Owner |
|-------|------------------|-------------|-------|
| SILVER | Real-time (incremental) | < 15 min | Data Engineering |
| GOLD | Daily at 06:00 CET | < 1 hour | Analytics Team |

---

## Change Log

### Version 2.0.0 (Current)
-  Comprehensive tests for all models (100+ tests)
-  Full documentation with business context
-  Fixed CPR validation and schema alignment
-  Added income verification model
-  Performance optimizations (incremental models)
-  Python models (Snowpark) added
-  Reorganized into clean folder structure

### Version 1.0.0
- Initial dbt project structure
- Basic pension and housing models
- Source definitions

---

## Next Steps

1. **Run Initial Setup:**
 ```bash
 dbt deps
 dbt debug
 dbt run
 dbt test
 ```

2. **View Documentation:**
 ```bash
 dbt docs generate
 dbt docs serve
 ```

3. **Explore Models:**
 - Start with `models/sources.yml` to understand sources
 - Review `schema.yml` files for model documentation
 - Check `dbt_project.yml` for project configuration

4. **Make Changes:**
 - Follow branching strategy (feature branches)
 - Create PR using template in `.github/pull_request_template.md`
 - Ensure all tests pass before merge

--- **Happy Transforming! **

