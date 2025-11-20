# Pull Request - ATP Data Platform

## PR Type
<!-- Check the type that applies to this PR -->
- [ ]  Bug fix (non-breaking change that fixes an issue)
- [ ]  New feature (non-breaking change that adds functionality)
- [ ]  Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ]  Documentation update
- [ ]  Infrastructure/Configuration change
- [ ]  Refactoring (no functional changes)

---

## Description
<!-- Provide a clear and concise description of what this PR does -->

**What does this PR do?**


**Why is this change needed?**


**Related Issue/Ticket:** # ---

## Testing & Validation

### Pre-Submission Checklist
<!-- ALL items must be checked before submitting -->

#### Code Quality
- [ ] Code follows project style guidelines
- [ ] No hardcoded credentials or secrets
- [ ] Comments added for complex logic
- [ ] Removed debug/console logs

#### dbt Models (if applicable)
- [ ] `dbt run` completes successfully (no errors)
- [ ] `dbt test` passes all tests
- [ ] `dbt compile` validates SQL syntax
- [ ] New models have proper documentation in `schema.yml`
- [ ] New models follow naming conventions (domain/layer structure)
- [ ] Incremental models have proper `unique_key` defined

#### Data Quality Tests (if applicable)
- [ ] Primary keys tested for uniqueness
- [ ] Required columns tested for `not_null`
- [ ] Foreign keys have `relationships` tests
- [ ] Enum columns have `accepted_values` tests
- [ ] Custom data quality tests added where appropriate

#### Infrastructure Changes (if applicable)
- [ ] Terraform plan reviewed (`terraform plan`)
- [ ] No unintended resource destruction
- [ ] Variables properly defined in `variables.tf`
- [ ] Changes tested in DEV environment first

#### Database Objects (if applicable)
- [ ] SQL scripts are idempotent (can run multiple times safely)
- [ ] Proper error handling included
- [ ] Permissions granted appropriately
- [ ] No drops of production objects

#### Documentation
- [ ] README updated (if applicable)
- [ ] CHANGELOG updated with changes
- [ ] dbt model documentation added/updated
- [ ] Schema changes documented

---

## Data Contract & Schema Changes

### Schema Modifications
<!-- Check all that apply -->
- [ ]  Non-breaking change (new nullable column, new table)
- [ ]  Breaking change (column rename, type change, column removal)
- [ ]  No schema changes

### If Breaking Change:
<!-- REQUIRED if breaking change checked above -->
**Downstream Impact Assessment:**
- Affected models:
- Affected reports/dashboards:
- Migration plan:
- Rollback plan:

---

## Performance Impact

<!-- Check one -->
- [ ]  Performance improvement
- [ ]  No performance impact
- [ ]  Potential performance degradation (explain below)

**Performance Notes:**


---

## Data Validation Results

### Test Results
```bash
## Paste output of dbt test here
$ dbt test --select <your_model>

```

### Row Counts (for new/modified models)
<!-- Provide before/after row counts if applicable -->
```sql
-- Model: <model_name>
-- Before: X rows
-- After: Y rows
-- Change: +/- Z rows (expected: yes/no)
```

---

## Deployment Notes

### Environment Promotion Plan
<!-- Check deployment path -->
- [ ] DEV only (not promoted)
- [ ] DEV → TEST
- [ ] DEV → TEST → PROD (requires approval)

### Rollback Plan
<!-- REQUIRED for production deployments -->


### Post-Deployment Validation
<!-- How will you verify this works in production? -->


---

## Screenshots (if applicable)
<!-- Add screenshots of lineage diagrams, test results, dbt docs, etc. -->


---

## Dependencies
<!-- List any dependencies this PR has -->
- [ ] Requires data to be loaded first
- [ ] Depends on PR # - [ ] Requires infrastructure changes to be deployed first
- [ ] Requires Snowflake objects to be created first

---

## Reviewers
<!-- Tag specific reviewers or teams -->
- **Data Engineering**: @team-data-engineering
- **Domain Expert**: @
- **Compliance** (if PII/sensitive data): @compliance-team

---

## Additional Notes
<!-- Any other information that reviewers should know -->


---

## Definition of Done
<!-- ALL must be checked before merge -->
- [ ] Code reviewed by at least one team member
- [ ] All CI/CD checks passing
- [ ] dbt tests passing (100% success rate)
- [ ] Documentation complete
- [ ] No merge conflicts
- [ ] Stakeholders notified (if applicable)
- [ ] Ready to merge

---

## Labels
<!-- Add appropriate labels: bug, enhancement, breaking-change, documentation, etc. -->

--- **By submitting this PR, I confirm that:**
-  I have tested these changes locally
-  I have followed the ATP Data Platform coding standards
-  I have not introduced any security vulnerabilities
-  I have documented all assumptions and limitations

