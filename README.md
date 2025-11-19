# ATP Denmark - dbt Data Transformation Project

## 📋 Overview

This dbt project transforms raw ATP data into analytics-ready datasets for:
- **Pension administration** (5.2M members, 112M contributions)
- **Housing benefits** (400K applications)
- **External data integration** (SKAT, BBR, CPR)

## 🏗️ Architecture

```
RAW → SILVER → GOLD
```

- **RAW**: Source data from operational systems
- **SILVER**: Cleansed, validated, enriched data
- **GOLD**: Business KPIs and aggregated analytics

## 📊 Data Models

### Pension Domain

#### Silver Layer
- **`members_clean`**: Validated member records with CPR validation
- **`contributions_enriched`**: Contribution transactions with member/employer details

#### Gold Layer
- **`member_contribution_summary`**: Member-level contribution analytics and risk scores
- **`employer_contribution_analytics`**: Employer payment behavior and compliance metrics

### Housing Benefits Domain

#### Silver Layer
- **`applications_enriched`**: Housing benefit applications with member demographics

#### Gold Layer
- **`housing_benefits_summary`**: Member-level benefit history and approval rates

### Integration Domain

#### Silver Layer
- **`income_verification`**: Cross-system income validation (SKAT vs applications)

## 🧪 Data Quality Tests

All models include comprehensive tests:
- ✅ **Uniqueness**: Primary keys are unique
- ✅ **Not null**: Required fields always populated
- ✅ **Referential integrity**: Foreign keys are valid
- ✅ **Accepted values**: Enums match expected values
- ✅ **Range checks**: Numeric values within reasonable bounds

### Running Tests

```bash
# Run all tests
dbt test

# Test specific model
dbt test --models members_clean

# Test by tag
dbt test --models tag:pension
```

## 🚀 Quick Start

### Prerequisites
- Snowflake account with ATP databases
- ATP_ADMIN role granted to your user
- dbt installed (via Snowflake Workspaces or locally)

### Running Models

```bash
# Run all models
dbt run

# Run specific domain
dbt run --models pension
dbt run --models housing
dbt run --models integration

# Run specific layer
dbt run --models tag:silver
dbt run --models tag:gold

# Run single model
dbt run --models members_clean
```

### Incremental Refresh

Silver models are incremental for performance:

```bash
# Run incremental (default)
dbt run --models members_clean

# Full refresh
dbt run --models members_clean --full-refresh
```

## 📚 Documentation

### Generate Documentation

```bash
# Generate docs
dbt docs generate

# Serve docs locally
dbt docs serve
```

### View in Snowflake

Documentation is automatically available in Snowflake Workspaces under the "Documentation" tab.

## 🔐 Security & Compliance

- **GDPR Compliant**: All PII is masked via Snowflake masking policies
- **Role-Based Access**: ATP_ADMIN, ATP_ANALYST, ATP_COMPLIANCE_OFFICER
- **Audit Trail**: All model runs are logged with query tags
- **Data Classification**: Models tagged by sensitivity (PII, financial)

## 📈 Performance

- **Incremental Models**: Only process changed records
- **Partitioning**: Time-based partitioning on large tables
- **Warehouse Sizing**: 
  - ETL: MEDIUM (for transformations)
  - BI: SMALL (for analytics queries)

## 🔄 CI/CD

Models are version-controlled and deployed via:
1. GitHub repository: `UlasB44/atp-dbt-denmark`
2. Snowflake Workspaces for development
3. Automated testing on pull requests
4. Production deployment via main branch

## 📞 Support

- **Owner**: ATP Data Engineering Team
- **Slack**: #atp-data-engineering
- **Issues**: GitHub Issues in this repository

## 🎯 SLAs

| Layer | Refresh Frequency | SLA | Owner |
|-------|------------------|-----|-------|
| Silver | Real-time (incremental) | < 15 min latency | Data Engineering |
| Gold | Daily at 06:00 CET | < 1 hour | Analytics Team |

## 📝 Change Log

### Version 2.0.0 (Current)
- ✅ Comprehensive tests for all models
- ✅ Full documentation with business context
- ✅ Fixed CPR validation and schema alignment
- ✅ Added income verification model
- ✅ Performance optimizations (incremental models)

### Version 1.0.0
- Initial dbt project structure
- Basic pension and housing models
