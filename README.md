# ATP Denmark - Data Platform & Analytics

> **Modern data platform for ATP Denmark pension and housing benefits administration**

[![dbt](https://img.shields.io/badge/dbt-1.7-orange)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-Native-blue)](https://www.snowflake.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple)](https://www.terraform.io/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Overview

Complete data platform codebase for ATP Denmark, featuring:

- **Infrastructure as Code**: Terraform for Snowflake provisioning
- **Data Transformations**: dbt models (SQL + Python/Snowpark)
- **Database Objects**: Roles, permissions, governance policies
- **Quality Gates**: Automated testing and validation
- **CI/CD Pipelines**: Azure DevOps integration
- **Documentation**: Comprehensive guides for dev experience

---

## Repository Structure

```
atp-dbt-denmark/

 dbt/                          # DATA TRANSFORMATIONS
   models/                   # SQL transformations (RAW → SILVER → GOLD)
   pension/             # Pension domain models
   housing/             # Housing benefits models
   integration/         # External system integrations
   python_models/           # Snowpark Python models (alternative)
   tests/                   # Data quality tests
   macros/                  # Reusable Jinja macros
   dbt_project.yml          # dbt configuration
   packages.yml             # dbt package dependencies
   README.md                # START HERE for dbt development

 terraform/                    # INFRASTRUCTURE AS CODE
   main.tf                  # Core infrastructure definitions
   variables.tf             # Input variables
   outputs.tf               # Output values
   environments/            # Environment-specific configs
   dev.tfvars          # DEV environment
   test.tfvars         # TEST environment
   prod.tfvars         # PROD environment (future)
   README.md                # Terraform deployment guide

 sql/                          # DATABASE OBJECTS
   00_setup_databases.sql   # Create databases & schemas
   01_setup_roles.sql       # RBAC permissions
   02_setup_git_integration.sql  # Git + Snowflake Native dbt
   03_governance_policies.sql    # Masking, tags, audit
   README.md                # SQL setup guide

 ci/                           # CI/CD PIPELINES
   azure-pipelines.yml      # Main pipeline (build + deploy)
   azure-pipelines-dev.yml  # DEV environment pipeline
   README.md                # CI/CD setup guide

 docs/                         # DOCUMENTATION
   SNOWFLAKE_WORKSPACE_PR_CHECKLIST.md  # PR checklist for Snowflake
   architecture.md          # System architecture (to be added)
   demo-scenarios.md        # Demo walkthroughs (to be added)

 .github/                      # GITHUB CONFIGURATION
   pull_request_template.md # PR template with quality gates
   workflows/               # GitHub Actions (future)

 .gitignore                    # Ignore patterns
 README.md                     # THIS FILE - Start here!
 LICENSE                       # Project license

```

---

## Quick Start

### For Developers (VS Code)

```bash
# 1. Clone repository
git clone https://github.com/UlasB44/atp-dbt-denmark.git
cd atp-dbt-denmark

# 2. Set up dbt locally
cd dbt
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Configure credentials
cp profiles_template.yml ~/.dbt/profiles.yml
## Edit ~/.dbt/profiles.yml with your credentials

# 4. Install dbt packages
dbt deps

# 5. Test connection
dbt debug

# 6. Run models
dbt run
dbt test
```

### For Snowflake Workspace Users

```sql
-- 1. Set up infrastructure (run once)
-- Execute: sql/00_setup_databases.sql
-- Execute: sql/01_setup_roles.sql
-- Execute: sql/02_setup_git_integration.sql

-- 2. Sync latest code from Git
ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- 3. Run dbt models
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';

-- 4. Run tests
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';

-- 5. View documentation
-- Navigate to: Projects → dbt Projects → ATP_DBT_PROJECT → Documentation
```

### For Infrastructure Engineers

```bash
# 1. Deploy infrastructure with Terraform
cd terraform

# 2. Set credentials
export TF_VAR_snowflake_password="your-password"

# 3. Initialize Terraform
terraform init

# 4. Deploy to DEV
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

---

## What This Repository Contains

### 1⃣ Data Transformations (`dbt/`)

**7 Production Models** across 3 domains:

| Domain | Layer | Model | Purpose |
|--------|-------|-------|---------|
|  **Pension** | SILVER | `members_clean` | Validated member records (5.2M members) |
|  **Pension** | SILVER | `contributions_enriched` | Contribution transactions (112M+ records) |
|  **Pension** | GOLD | `member_contribution_summary` | Member-level analytics & risk scores |
|  **Pension** | GOLD | `employer_contribution_analytics` | Employer compliance metrics |
|  **Housing** | SILVER | `applications_enriched` | Housing benefit applications |
|  **Housing** | GOLD | `housing_benefits_summary` | Benefit payment analytics |
|  **Integration** | SILVER | `income_verification` | Cross-system income validation (SKAT) |

**100+ Data Quality Tests** enforcing:
- Primary key uniqueness
- Foreign key relationships
- Not-null constraints
- Accepted values (enums)
- Custom business rules

---

### 2⃣ Infrastructure as Code (`terraform/`)

**Managed Resources:**
- 3 Warehouses (ETL, BI, Compliance)
- 4 Databases (PENSION, HOUSING_BENEFITS, INTEGRATION, GOVERNANCE)
- 10 Schemas (RAW, SILVER, GOLD layers)
- Resource monitors for cost control
- Multi-environment support (DEV, TEST, PROD)

**Features:**
- Environment-specific configurations
- Variable validation
- Comprehensive outputs
- State management

---

### 3⃣ Database Objects (`sql/`)

**Security & Governance:**
- Role-based access control (4 roles)
- CPR number masking (GDPR compliance)
- Data classification tags
- Audit logging
- Git integration for Snowflake Native dbt

**Roles:**
- `ATP_ADMIN`: Full access
- `ATP_DATA_ENGINEER`: Read/write transformations
- `ATP_ANALYST`: Read-only analytics
- `ATP_COMPLIANCE_OFFICER`: Audit access

---

### 4⃣ CI/CD Pipelines (`ci/`)

**Automated Quality Gates:**

 **On Pull Request:**
1. dbt compile (SQL validation)
2. dbt run (build models in DEV)
3. dbt test (run all 100+ tests)
4. Block merge if failures

 **On Merge to Main:**
1. Auto-deploy to DEV
2. Manual approval for TEST/PROD
3. Full test suite execution
4. Documentation generation

**Supported Platforms:**
- Azure DevOps (configured)
- GitHub Actions (ready to add)

---

## Developer Experience

### VS Code Development

1. **Local Development**: Full dbt CLI experience
2. **Git Flow**: Feature branches → PR → Review → Merge
3. **Testing**: Run `dbt test` before commit
4. **Documentation**: Auto-generated with `dbt docs generate`
5. **Lineage**: Visual DAG in dbt docs

### Snowflake Workspaces

1. **Native dbt**: Run dbt directly in Snowflake
2. **Git Sync**: Automatic sync with GitHub
3. **Visual Lineage**: Built-in DAG viewer
4. **Execution History**: Query-level monitoring
5. **No Local Setup**: Browser-based development

### Pull Request Workflow

#### For GitHub (VS Code):
1. Create feature branch
2. Make changes, test locally (`dbt run`, `dbt test`)
3. Push to GitHub
4. Create PR using **template** (auto-populated)
5. CI/CD runs automatically
6. Review, approve, merge

#### For Snowflake Workspaces:
1. Make changes in Snowflake
2. Commit via Git integration
3. Create PR on GitHub
4. Use **checklist**: `docs/SNOWFLAKE_WORKSPACE_PR_CHECKLIST.md`
5. Copy checklist into PR description
6. Review, approve, merge

---

## Security & Compliance

### GDPR Compliance
-  PII masking (CPR numbers, addresses)
-  Data classification tags
-  Audit trail for sensitive data access
-  Row-level security (configurable)

### Data Contracts
-  Schema contracts in `schema.yml`
-  Breaking change detection via tests
-  Automatic validation in CI/CD

### Secrets Management
-  No hardcoded credentials
-  Azure DevOps variable groups
-  Terraform sensitive variables
-  Git ignored profiles.yml

---

## Data Architecture

### Medallion Architecture (RAW → SILVER → GOLD)

```

                       GOLD LAYER                                
         Business KPIs  Aggregates  Reports                    
    
  Member Summary     Employer Analytics  Housing Summary   
    

                              

                      SILVER LAYER                               
       Cleansed  Validated  Enriched  Business Logic         
       
  Members Clean  Contributions      Applications        
                Enriched           Enriched            
       

                              

                       RAW LAYER                                 
             Source Systems  External APIs                      
           
  Members        Contributions  SKAT Income Data        
  Employers      Applications   BBR Dwelling Data       
           

```

---

## Testing Strategy

### Automated Tests (100+ tests)

| Test Type | Count | Example |
|-----------|-------|---------|
| **Uniqueness** | 15+ | `cpr_number` is unique |
| **Not Null** | 40+ | Required fields populated |
| **Relationships** | 20+ | Foreign keys valid |
| **Accepted Values** | 10+ | Gender in ('M', 'F') |
| **Custom Business Rules** | 15+ | Contribution amount > 0 |

### Test Execution

```bash
## Local
dbt test                           # All tests
dbt test --models members_clean    # Specific model
dbt test --select source:*         # Source freshness

## Snowflake
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';
```

### CI/CD Enforcement
- **PR blocked** if tests fail
- **Merge allowed** only with 100% test pass rate

---

## Documentation

### Auto-Generated Documentation

- **dbt Docs**: Model descriptions, column definitions, lineage DAG
- **Terraform Docs**: Resource specifications, variable descriptions
- **SQL Docs**: Inline comments, setup guides

### Access Documentation

**Local:**
```bash
cd dbt
dbt docs generate
dbt docs serve  # Opens browser at localhost:8080
```

**Snowflake:**
Navigate to: **Projects → dbt Projects → ATP_DBT_PROJECT → Documentation**

---

## GitOps Workflow

### Branching Strategy

```
main (protected)
 develop (integration)
     feature/add-new-kpi
     feature/fix-pension-calc
     bugfix/address-masking
```

### Commit Message Convention

```
<type>(<scope>): <subject>

Examples:
feat(pension): Add employer risk scoring model
fix(housing): Correct rent burden calculation
docs(readme): Update setup instructions
test(integration): Add income verification tests
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **dbt connection fails** | Check `profiles.yml` credentials, run `dbt debug` |
| **Terraform apply fails** | Verify Snowflake permissions, check state lock |
| **Tests failing** | Review source data quality, check test definitions |
| **Git sync issues** | Run `ALTER GIT REPOSITORY atp_dbt_repo FETCH;` |
| **Permission denied** | Verify role has required grants, check RBAC |

### Getting Help

1. **Check README** in relevant folder (`dbt/`, `terraform/`, `sql/`)
2. **Search Issues**: [GitHub Issues](https://github.com/UlasB44/atp-dbt-denmark/issues)
3. **Slack**: # atp-data-engineering
4. **Email**: data-platform-team@atp.dk

---

## Performance & Costs

### Optimization

- **Incremental Models**: SILVER layer (< 15 min refresh)
- **Clustered Tables**: Date/CPR clustering on large tables
- **Warehouse Auto-Suspend**: 60 seconds (cost optimization)
- **Resource Monitors**: Alert at 50%, 75%, 90% credit usage

### Monitoring

```sql
-- View dbt execution history
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.DBT_PROJECT_EXECUTION_HISTORY
WHERE PROJECT_NAME = 'ATP_DBT_PROJECT'
ORDER BY START_TIME DESC;

-- Check warehouse credit usage
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME LIKE 'ATP_%'
ORDER BY START_TIME DESC;
```

---

## Demo Scenarios

This codebase supports the following demo scenarios:

### **Supported**
1. **B.1 Developer Experience** (GitOps, CI/CD, dbt)
2. **B.2 Business User Reporting** (Connect Power BI to GOLD tables)
3. **Partial B.4 Data Analyst** (dbt semantic models)

### **Partially Supported**
- **B.3 Citizen Analyst**: Manual KPI creation (no marketplace)
- **B.5 Data Scientist ML**: Data access via API (no ML ops)

### **Not Implemented**
- Marketplace UI
- Validation workflows
- Event-driven orchestration

See `docs/demo-scenarios.md` for detailed walkthrough (coming soon).

---

## Roadmap

### Q1 2025
- [ ] Add GitHub Actions CI/CD
- [ ] Implement data marketplace (Streamlit app)
- [ ] Add semantic layer (dbt Semantic Layer or Cube.js)
- [ ] ML model lineage tracking

### Q2 2025
- [ ] Event-driven orchestration (Kafka + dbt)
- [ ] Advanced FinOps dashboards
- [ ] Data product validation workflows
- [ ] Cross-environment promotion automation

---

## Contributors

- **ATP Data Platform Team**
- **Data Engineering**: dbt transformations, CI/CD
- **Infrastructure**: Terraform, Snowflake administration
- **Governance**: Security policies, compliance

---

## License

MIT License - See [LICENSE](LICENSE) file for details

---

## Getting Started

**New to the project?**

1.  **Read this README** (you are here!)
2.  **Choose your path:**
 - **Developer**: Start with `dbt/README.md`
 - **Infrastructure Engineer**: Start with `terraform/README.md`
 - **DBA**: Start with `sql/README.md`
 - **DevOps**: Start with `ci/README.md`
3.  **Run Quick Start** for your role (see above)
4.  **Create your first PR** using templates
5.  **Deploy to DEV** and see it work!

--- **Questions? Issues? Feedback?**

 [Open an Issue](https://github.com/UlasB44/atp-dbt-denmark/issues/new)

--- **Built with  by ATP Data Platform Team**
