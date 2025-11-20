# Snowflake Workspace - Pull Request Checklist

> **For developers using Snowflake Workspaces**: Use this checklist before creating your pull request.  
> Copy this template into your PR description when creating PRs from Snowflake Workspaces.

---

## PR Information

**PR Title:** [Concise description of changes]

**PR Type:** [Bug Fix / Feature / Breaking Change / Documentation / Config]

**Description:**
<!-- What does this PR do and why? -->


**Related Ticket/Issue:** # ---

## Pre-Submission Checklist

### 1⃣ Code Execution & Testing

```sql
-- Run these commands in your Snowflake Worksheet and paste results below:

-- Test 1: Compile dbt models
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'compile';

-- Test 2: Run your models
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run --select <your_model>';

-- Test 3: Run tests
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'test --select <your_model>';

-- Test 4: Generate documentation
EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'docs generate';
```

**Results:**
- [ ]  Compile: SUCCESS
- [ ]  Run: SUCCESS (X models built)
- [ ]  Test: SUCCESS (Y tests passed)
- [ ]  Docs: SUCCESS

**Paste execution query ID:**
```
Query ID: <paste-query-id-here>
```

---

### 2⃣ Data Quality Checks

```sql
-- Verify row counts for modified tables
SELECT 
  'members_clean' AS model,
  COUNT(*) AS row_count,
  COUNT(DISTINCT cpr_number) AS unique_keys
FROM ATP_PENSION.SILVER.MEMBERS_CLEAN;

-- Check for NULL values in critical columns
SELECT 
  COUNT(*) AS total_rows,
  COUNT(CASE WHEN <key_column> IS NULL THEN 1 END) AS null_keys
FROM <your_table>;
```

**Results:**
- [ ] Row counts match expectations
- [ ] No unexpected NULL values
- [ ] Data types correct
- [ ] Primary keys unique

---

### 3⃣ Schema Changes

**Schema Impact:**
- [ ]  Non-breaking (new column, new table)
- [ ]  Breaking (rename, type change, drop column)
- [ ]  No schema changes

**If Breaking:**
- Downstream models affected: 
- Migration plan: 
- Stakeholders notified: Yes/No

---

### 4⃣ Documentation

- [ ] Model documented in `schema.yml`
- [ ] Column descriptions added
- [ ] Business logic explained in comments
- [ ] Tests documented

**View your documentation:**
```sql
-- Navigate to: Projects → dbt Projects → ATP_DBT_PROJECT → Documentation
-- Verify your model appears with full documentation
```

---

### 5⃣ Lineage Verification

**Check lineage in Snowsight:**
1. Navigate to: **Projects** → **dbt Projects** → **ATP_DBT_PROJECT**
2. Click **Lineage** tab
3. Find your model in the DAG

- [ ] Lineage diagram shows correct upstream dependencies
- [ ] Lineage diagram shows correct downstream dependencies
- [ ] No orphaned models

**Screenshot:** (Optional - paste Snowsight lineage screenshot URL)

---

### 6⃣ Performance Check

```sql
-- Check query execution time
SELECT 
  query_id,
  query_text,
  execution_status,
  total_elapsed_time / 1000 AS execution_time_seconds,
  bytes_scanned,
  credits_used_cloud_services
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_text ILIKE '%<your_model_name>%'
  AND start_time >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
ORDER BY start_time DESC
LIMIT 10;
```

**Performance Impact:**
- [ ]  Improved performance
- [ ]  No significant change
- [ ]  Performance degradation (explain below)

**Notes:**


---

### 7⃣ Git Sync Verification

**Before creating PR:**

```sql
-- 1. Verify latest code is in Git repository
ALTER GIT REPOSITORY atp_dbt_repo FETCH;

-- 2. Check repository status
LS @atp_dbt_repo/branches/main/;

-- 3. Verify your files are present
LS @atp_dbt_repo/branches/main/dbt/models/<your_path>/;
```

- [ ] Latest code fetched from Git
- [ ] My changes are in the repository
- [ ] No merge conflicts

---

## Security & Compliance

- [ ] No hardcoded credentials
- [ ] No PII exposed in logs/documentation
- [ ] Appropriate masking policies applied (if PII)
- [ ] Row-level security considered (if sensitive data)

**PII Fields (if applicable):**
- Column: `<column_name>` - Masking: Yes/No

---

## Data Validation

**Test Data Sample:**
```sql
-- Paste a sample query showing your transformed data
SELECT TOP 5 * FROM <your_table>;
```

**Expected vs Actual:**
- Expected rows: 
- Actual rows: 
- Match: Yes/No

---

## Deployment Plan

**Target Environment:**
- [ ] DEV only
- [ ] DEV → TEST
- [ ] DEV → TEST → PROD (requires approval)

**Deployment Steps:**
1. Merge PR to `main` branch
2. Azure DevOps pipeline auto-deploys to DEV
3. Verify in DEV environment
4. (If PROD) Manual approval required
5. Deploy to PROD

**Rollback Plan:**


---

## Reviewers Needed

**Tag reviewers:**
- Data Engineering: @
- Domain Expert: @
- Compliance (if PII): @

---

## Additional Notes




---

## Final Checks Before Creating PR

- [ ] All commands executed successfully in Snowflake
- [ ] Test results pasted above
- [ ] Documentation updated
- [ ] Lineage verified
- [ ] Git repo synced
- [ ] Performance acceptable
- [ ] Security reviewed
- [ ] Ready for review

---

## Helpful Links

- **Snowsight dbt Project**: [View in Snowflake](https://app.snowflake.com/UTYEYAD/XT83149/#/projects/dbt/ATP_DBT_PROJECT)
- **dbt Documentation**: Navigate to Projects → dbt Projects → ATP_DBT_PROJECT → Documentation
- **Lineage Viewer**: Navigate to Projects → dbt Projects → ATP_DBT_PROJECT → Lineage
- **Execution History**: 
```sql
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.DBT_PROJECT_EXECUTION_HISTORY
WHERE PROJECT_NAME = 'ATP_DBT_PROJECT'
ORDER BY START_TIME DESC;
```

---

## Creating the PR

**From Snowflake Workspace:**

1. **Commit your changes** in Snowflake Workspaces Git integration
2. **Push to branch** (or commit directly to main if preferred)
3. **Go to GitHub**: https://github.com/UlasB44/atp-dbt-denmark
4. **Create Pull Request**
5. **Copy this checklist** into the PR description
6. **Tag reviewers**
7. **Submit for review**

--- **By submitting, I confirm:**
-  All tests passing
-  Documentation complete
-  No security issues
-  Performance validated

