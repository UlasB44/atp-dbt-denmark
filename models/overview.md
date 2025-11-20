{% docs __overview__ %}

# ATP Denmark Data Warehouse

## Business Context

ATP (Arbejdsmarkedets Tillægspension) is Denmark's statutory supplementary pension scheme. This data warehouse supports:

1. **Pension Administration**
   - Managing 5.2M active members
   - Processing 112M contribution records
   - Tracking 100K+ employer relationships

2. **Housing Benefits Administration**
   - Processing 400K benefit applications
   - Monthly payment distribution
   - Annual recalculations

3. **External System Integration**
   - SKAT (Danish Tax Authority) income verification
   - BBR (Building and Dwelling Register) property data
   - CPR (Civil Registration System) demographic updates

## Data Architecture

### Bronze Layer (RAW)
Unchanged data from source systems, loaded via:
- Batch ETL from operational databases
- API integrations (SKAT, BBR, CPR)
- Streaming pipelines (real-time contributions)

### Silver Layer
Cleansed, validated, and enriched data:
- CPR number validation
- Data quality flags
- Business rule enforcement
- Relationship enrichment

### Gold Layer
Business-ready analytics and KPIs:
- Member contribution summaries
- Employer compliance metrics
- Benefit approval analytics
- Income verification reports

## Key Concepts

### CPR Number
Danish personal identification number (format: DDMMYY-XXXX)
- First 6 digits: Birth date
- Last 4 digits: Unique identifier (last digit indicates gender)

### CVR Number
Danish company registration number with Modulus-11 checksum validation

### Contribution Periods
- Format: YYYY-MM (e.g., "2024-01")
- Payments due by 10th of following month
- Late payment flags for compliance monitoring

### Housing Benefit Calculation
Based on:
- Annual income (verified via SKAT)
- Monthly rent
- Household size
- Dwelling size (from BBR)

## Data Quality Framework

### Validation Rules
1. **CPR Validation**: Format check, date validity, gender consistency
2. **Amount Ranges**: Min/max checks on all financial amounts
3. **Referential Integrity**: All foreign keys validated
4. **Temporal Logic**: Start dates before end dates, reasonable date ranges

### Quality Metrics
- Data completeness (target: 99%+)
- Validation pass rate (target: 95%+)
- Record freshness (target: < 1 hour for silver)
- Test pass rate (target: 100%)

## Governance & Compliance

### Data Classification
- **Highly Sensitive (Red)**: CPR numbers, income data
- **Sensitive (Amber)**: Names, addresses, benefit amounts
- **Public (Green)**: Aggregated statistics, industry codes

### GDPR Compliance
- Purpose limitation: Data used only for statutory obligations
- Data minimization: Only required fields collected
- Right to access: Member data queryable via ATP_ANALYST role
- Data masking: PII masked for non-compliance roles

### Audit & Monitoring
- All queries tagged with user and purpose
- Audit logs retained for 7 years
- Access reviewed quarterly
- Anomaly detection on all financial transactions

## Performance Optimization

### Incremental Models
Silver models process only changed records:
- `members_clean`: Updated when source records change
- `contributions_enriched`: New contributions only

### Partitioning Strategy
- Contributions: Partitioned by `contribution_period` (monthly)
- Payments: Partitioned by `payment_date` (daily)
- Applications: Partitioned by `application_date` (monthly)

### Warehouse Sizing
- **ATP_ETL_WH (MEDIUM)**: For dbt transformations
- **ATP_BI_WH (SMALL)**: For analyst queries
- **ATP_COMPLIANCE_WH (XSMALL)**: For compliance reports

## Use Cases

### Pension Administration
- Calculate member pension entitlements
- Track employer contribution compliance
- Identify late payments for follow-up

### Housing Benefits
- Verify application eligibility
- Calculate monthly benefit amounts
- Detect fraudulent applications

### Analytics & Reporting
- Industry benchmarking
- Contribution trend analysis
- Member demographic insights
- Employer risk assessment

### Compliance & Risk
- Income verification across systems
- Anomaly detection in contributions
- Payment pattern analysis
- GDPR access request fulfillment

## Support & Contact

For questions or issues:
- **Data Engineering**: atp-data-eng@atp.dk
- **Analytics**: atp-analytics@atp.dk
- **Compliance**: atp-compliance@atp.dk

{% enddocs %}

