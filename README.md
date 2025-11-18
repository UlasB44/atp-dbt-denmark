# ATP Denmark - dbt Data Transformation Project

## Overview
Production-ready dbt project for ATP Denmark pension administration data transformation on Snowflake.

## Project Structure
```
models/
├── sources.yml              # Source definitions for RAW tables
├── pension/
│   ├── silver/             # Cleansed, enriched pension data
│   │   ├── members_clean.sql
│   │   └── contributions_enriched.sql
│   └── gold/               # Business KPIs and aggregates
│       ├── member_contribution_summary.sql
│       └── employer_contribution_analytics.sql
├── housing/
│   ├── silver/             # Housing benefits data
│   │   └── applications_enriched.sql
│   └── gold/
│       └── housing_benefits_summary.sql
└── integration/
    └── silver/             # External system integrations
        └── income_verification.sql
```

## Data Pipeline
```
RAW (Ingestion)
  ↓ dbt models
SILVER (Cleansed, enriched, validated)
  ↓ dbt models
GOLD (Business KPIs, aggregates, analytics-ready)
```

## Models

### SILVER Layer
- **members_clean**: Enriched member data with age calculation, gender parsing, data quality flags
- **contributions_enriched**: Contributions joined with member/employer details, payment analytics, anomaly detection
- **applications_enriched**: Housing benefit applications with processing times, eligibility checks
- **income_verification**: Cross-reference housing applications with SKAT tax authority data

### GOLD Layer
- **member_contribution_summary**: Per-member lifetime value, payment behavior, risk scoring
- **employer_contribution_analytics**: Compliance metrics, industry benchmarks, high-risk employer flagging
- **housing_benefits_summary**: Benefit utilization rates, error tracking, approval metrics

## Key Features
- ✅ **Data Quality**: Validation flags, anomaly detection, cross-system reconciliation
- ✅ **Risk Scoring**: Payment risk categorization (Low/Medium/High)
- ✅ **Compliance**: Fraud detection via income verification with external systems
- ✅ **Performance**: Optimized SQL, incremental materialization where applicable
- ✅ **Documentation**: Inline comments explaining business logic

## Setup

### Prerequisites
- Snowflake account with ATP databases (ATP_PENSION, ATP_HOUSING_BENEFITS, ATP_INTEGRATION)
- dbt-snowflake installed (`pip install dbt-snowflake`)
- Python 3.10+

### Configuration
1. Create `profiles.yml`:
```yaml
atp_denmark:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_ACCOUNT
      user: YOUR_USER
      password: YOUR_PASSWORD
      role: SYSADMIN
      warehouse: ATP_ETL_WH
      database: ATP_PENSION
      schema: SILVER
      threads: 4
      client_session_keep_alive: True
```

2. Set environment variables (optional):
```bash
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export SNOWFLAKE_PASSWORD=your_password
```

### Run dbt
```bash
# Install dependencies
pip install dbt-snowflake

# Test connection
dbt debug

# Run all models
dbt run

# Run specific model
dbt run --select member_contribution_summary

# Run with full refresh
dbt run --full-refresh

# Generate documentation
dbt docs generate
dbt docs serve
```

## Data Volumes
- **SILVER Layer**: ~160M rows (enriched contributions)
- **GOLD Layer**: ~5M rows (aggregated metrics)
- **Build Time**: ~3-5 minutes for full refresh

## Business Logic Examples

### Risk Scoring
```sql
-- Payment risk categorization
CASE
    WHEN late_payment_rate > 0.10 THEN 'High Risk'
    WHEN late_payment_rate > 0.05 THEN 'Medium Risk'
    ELSE 'Low Risk'
END AS payment_risk_category
```

### Anomaly Detection
```sql
-- Flag unusual contribution amounts
CASE
    WHEN total_amount < 100 OR total_amount > 500 THEN TRUE
    ELSE FALSE
END AS is_anomaly
```

### Income Verification
```sql
-- Cross-reference declared vs verified income
CASE
    WHEN ABS(declared_income - verified_income) / verified_income < 0.05 THEN 'Verified'
    WHEN ABS(declared_income - verified_income) / verified_income < 0.10 THEN 'Minor Discrepancy'
    ELSE 'Major Discrepancy'
END AS verification_status
```

## Testing
```bash
# Run dbt tests
dbt test

# Test specific model
dbt test --select member_contribution_summary
```

## Deployment
This project is designed for CI/CD deployment via:
- Azure DevOps
- GitHub Actions
- dbt Cloud

## License
Proprietary - ATP Denmark

## Contact
Project Owner: UlasB44

