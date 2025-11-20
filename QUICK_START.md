# ATP Denmark - Quick Start Guide

## Choose Your Path

### I'm a **Developer** (VS Code)

```bash
# 1. Clone & Setup
git clone https://github.com/UlasB44/atp-dbt-denmark.git
cd atp-dbt-denmark/dbt
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# 2. Configure
cp profiles_template.yml ~/.dbt/profiles.yml
## Edit ~/.dbt/profiles.yml with credentials

# 3. Run
dbt deps
dbt debug
dbt run
dbt test
dbt docs serve
```

**Next:** Read `dbt/README.md`

---

### I'm an **Infrastructure Engineer** (Terraform)

```bash
# 1. Navigate
cd terraform

# 2. Set Credentials
export TF_VAR_snowflake_password="your-password"

# 3. Deploy
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

**Next:** Read `terraform/README.md`

---

### I'm a **Database Admin** (SQL)

```sql
-- 1. Connect to Snowflake as ACCOUNTADMIN

-- 2. Run setup scripts in order:
-- Execute: sql/00_setup_databases.sql
-- Execute: sql/01_setup_roles.sql
-- Execute: sql/02_setup_git_integration.sql
-- Execute: sql/03_governance_policies.sql

-- 3. Verify
SHOW DATABASES LIKE 'ATP_%';
SHOW WAREHOUSES LIKE 'ATP_%';
SHOW ROLES LIKE 'ATP_%';
```

**Next:** Read `sql/README.md`

---

### I'm using **Snowflake Workspaces**

```sql
-- 1. Setup (one-time)
-- Run sql/02_setup_git_integration.sql

-- 2. Sync & Run
ALTER GIT REPOSITORY atp_dbt_repo FETCH;

EXECUTE DBT PROJECT atp_dbt_project 
COMMAND = 'run';

EXECUTE DBT PROJECT atp_dbt_project 
COMMAND = 'test';

-- 3. View Results
SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- 4. View Documentation
-- Navigate: Projects → dbt Projects → ATP_DBT_PROJECT → Documentation
```

**Next:** Read `docs/SNOWFLAKE_WORKSPACE_PR_CHECKLIST.md`

---

### I'm setting up **CI/CD** (DevOps)

1. **Azure DevOps:**
 - Import repo: `https://github.com/UlasB44/atp-dbt-denmark.git`
 - Create Variable Group: `snowflake-credentials`
 - Add secrets: `SNOWFLAKE_PASSWORD`
 - Create pipeline from: `ci/azure-pipelines.yml`
 - Run pipeline

2. **GitHub Actions:**
 - Add secrets to repo settings
 - Create workflow in `.github/workflows/`
 - Use template from `ci/azure-pipelines.yml` as reference

**Next:** Read `ci/README.md`

---

## Most Common Commands

### dbt (Local)
```bash
dbt run                          # Run all models
dbt run --models pension         # Run pension domain
dbt test                         # Run all tests
dbt test --models members_clean  # Test specific model
dbt docs generate && dbt docs serve  # Documentation
```

### dbt (Snowflake)
```sql
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test';
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run --select member_contribution_summary';
```

### Terraform
```bash
terraform init                                    # Initialize
terraform plan -var-file="environments/dev.tfvars"   # Plan
terraform apply -var-file="environments/dev.tfvars"  # Apply
terraform output                                  # View outputs
```

### Git
```bash
git checkout -b feature/my-feature  # Create branch
git add .                          # Stage changes
git commit -m "feat: description"  # Commit
git push origin feature/my-feature # Push
## Create PR on GitHub using template
```

---

## Documentation Map

| What I Need | Go To |
|-------------|-------|
| **Overview of everything** | `README.md` (root) |
| **dbt development** | `dbt/README.md` |
| **Infrastructure setup** | `terraform/README.md` |
| **Database objects** | `sql/README.md` |
| **CI/CD pipelines** | `ci/README.md` |
| **System architecture** | `docs/ARCHITECTURE.md` |
| **PR checklist (GitHub)** | `.github/pull_request_template.md` |
| **PR checklist (Snowflake)** | `docs/SNOWFLAKE_WORKSPACE_PR_CHECKLIST.md` |
| **Complete summary** | `REPO_SUMMARY.md` |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **dbt won't connect** | Check `~/.dbt/profiles.yml`, run `dbt debug` |
| **Terraform fails** | Verify Snowflake permissions, check `TF_VAR_snowflake_password` |
| **Permission denied** | Check your Snowflake role: `USE ROLE ATP_ADMIN;` |
| **Tests failing** | Review test output: `dbt test --models <model>` |
| **Git sync issues** | `ALTER GIT REPOSITORY atp_dbt_repo FETCH;` |

---

## Demo Preparation

### Quick Demo Setup (5 minutes)

```bash
# 1. Deploy infrastructure
cd terraform
terraform apply -var-file="environments/dev.tfvars" -auto-approve

# 2. Run dbt models
cd ../dbt
dbt run
dbt test

# 3. Generate docs
dbt docs generate
dbt docs serve  # Opens browser

# 4. Show in Snowflake
## Navigate to Projects → dbt Projects → ATP_DBT_PROJECT → Lineage
```

### Demo Talking Points
1. **GitOps**: Show Git integration
2. **Data Quality**: Show 100+ tests passing
3. **Lineage**: Show dbt DAG
4. **Infrastructure**: Show Terraform outputs
5. **PR Process**: Show PR template

---

## Verification Checklist

After setup, verify:

```sql
--  Databases exist
SHOW DATABASES LIKE 'ATP_%';  -- Should show 4 databases

--  Warehouses exist
SHOW WAREHOUSES LIKE 'ATP_%';  -- Should show 3 warehouses

--  Roles exist
SHOW ROLES LIKE 'ATP_%';  -- Should show 4 roles

--  dbt models exist
SELECT * FROM ATP_PENSION.GOLD.MEMBER_CONTRIBUTION_SUMMARY LIMIT 5;

--  Git integration works
LS @atp_dbt_repo/branches/main/;
```

---

## Next Steps After Setup

1. **Explore the data:**
 ```sql
 SELECT * FROM ATP_PENSION.GOLD.MEMBER_CONTRIBUTION_SUMMARY LIMIT 10;
 ```

2. **Make a change:**
 - Modify a dbt model
 - Run `dbt run --models <your_model>`
 - Create PR using template

3. **View lineage:**
 - Run `dbt docs serve` locally
 - OR navigate to Snowflake Projects → dbt Projects

4. **Set up CI/CD:**
 - Follow `ci/README.md`
 - Connect Azure DevOps
 - Test automated pipeline

---

## Get Help

- **Documentation**: Check README files in each folder
- **Issues**: [GitHub Issues](https://github.com/UlasB44/atp-dbt-denmark/issues)
- **Slack**: # atp-data-engineering

--- ** That's it! You're ready to go! **

For detailed information, start with the main `README.md` in the root directory.

