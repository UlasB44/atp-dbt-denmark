# ATP Denmark - Data Platform Architecture

## System Overview

The ATP Denmark Data Platform is a modern, cloud-native data architecture built on Snowflake, leveraging dbt for transformations, Terraform for infrastructure provisioning, and Azure DevOps for CI/CD automation.

---

## Architecture Diagram

```

                        CONSUMPTION LAYER                                
       
  Power BI        Excel        SAP SAC      Streamlit   
  Dashboards     Reports       Analytics       App      
       
                                                                

                                                        

                      GOLD LAYER (Analytics Ready)                       
     
  PENSION.GOLD                HOUSING_BENEFITS.GOLD               
   member_contribution_      housing_benefits_summary         
   summary                   application_analytics            
   employer_contribution_                                      
    analytics                                                   
     
       ↑                                        ↑                        
                                                                     
   [dbt GOLD Models]                      [dbt GOLD Models]             

                                              

                   SILVER LAYER (Cleansed & Enriched)                    
     
  PENSION.SILVER              HOUSING_BENEFITS.SILVER             
   members_clean             applications_enriched            
   contributions_enriched    ...                              
     
   
  INTEGRATION.SILVER                                                 
   income_verification                                             
   ...                                                             
   
       ↑                                        ↑                        
                                                                     
   [dbt SILVER Models - Incremental]   [dbt SILVER Models]              

                                              

                    RAW LAYER (Source Data Landing)                      
     
  PENSION.RAW                 HOUSING_BENEFITS.RAW                
   members                   applications                     
   employers                 payments                         
   contributions             ...                              
   employment_relations                                        
     
   
  INTEGRATION.RAW                                                    
   skat_income_data (Danish Tax Authority)                        
   bbr_dwelling_data (Building Registry)                          
   cpr_registry_updates (Civil Registration)                      
   
       ↑                                        ↑                        

                                              

                        SOURCE SYSTEMS                                    
       
   Pension       Housing         SKAT          BBR      
  Admin Sys     Benefits      (Tax Auth)    (Building)  
       



                     GOVERNANCE & METADATA LAYER                          
  
  ATP_GOVERNANCE                                                       
   METADATA (Data Catalog, Lineage, Access Requests)                
   GOVERNANCE (Policies, Tags, Audit Logs)                          
  

```

---

## Key Design Principles

### 1. Medallion Architecture (RAW → SILVER → GOLD)

**RAW Layer:**
- Source data as-is (no transformations)
- Audit trail for source changes
- Snapshot of operational systems

**SILVER Layer:**
- Cleansed and validated data
- Business logic applied
- PII masked (GDPR compliance)
- Incremental refresh for performance

**GOLD Layer:**
- Business KPIs and aggregates
- Analytics-ready datasets
- Optimized for BI tools
- Full refresh daily

### 2. Domain-Driven Design

Data organized by business domains:
- **Pension**: Core ATP business (5.2M members)
- **Housing Benefits**: Government welfare administration
- **Integration**: External system data
- **Governance**: Metadata and audit

### 3. Infrastructure as Code

All infrastructure defined in code:
- **Terraform**: Warehouses, databases, schemas
- **dbt**: Data transformations
- **SQL**: Roles, permissions, policies
- **Version Controlled**: Full audit trail

### 4. GitOps Workflow

```
Developer → Git Commit → PR → CI/CD Tests → Review → Merge → Auto-Deploy
```

---

## Database Architecture

### Databases (4)

| Database | Purpose | Schemas | Size |
|----------|---------|---------|------|
| **ATP_PENSION** | Pension administration | RAW, SILVER, GOLD | 112M+ records |
| **ATP_HOUSING_BENEFITS** | Housing benefits | RAW, SILVER, GOLD | 400K+ records |
| **ATP_INTEGRATION** | External systems | RAW, SILVER | Varies |
| **ATP_GOVERNANCE** | Metadata & policies | METADATA, GOVERNANCE | Metadata |

### Warehouses (3)

| Warehouse | Size | Purpose | Auto-Suspend |
|-----------|------|---------|--------------|
| **ATP_ETL_WH** | MEDIUM | dbt transformations, data loading | 60s |
| **ATP_BI_WH** | SMALL | Analytics queries, dashboards | 60s |
| **ATP_COMPLIANCE_WH** | X-SMALL | Audit queries, governance | 60s |

---

## Security Architecture

### Role-Based Access Control (RBAC)

```

                   ACCOUNTADMIN (Root)                       

                        
      
                                      
  
 ATP_ADMIN      ATP_DATA_        ATP_COMPLIANCE_     
                ENGINEER         OFFICER             
 Full Access                                        
 All Databases   Read/Write       Audit & Governance  
 All Warehouses  SILVER + GOLD    Read-Only All       
  
                                      
                      
               ATP_ANALYST          
                                    
               Read-Only            
               SILVER + GOLD        
                      
                                        
      
                      
      
                Database & Schema Access                
            
        ATP_PENSION   ATP_HOUSING    ATP_     
                     _BENEFITS      GOV      
            
      
```

### GDPR Compliance

**PII Masking:**
```sql
-- CPR numbers masked for non-privileged roles
CREATE MASKING POLICY cpr_mask AS (val STRING) RETURNS STRING ->
CASE
  WHEN CURRENT_ROLE() IN ('ATP_ADMIN', 'ATP_COMPLIANCE_OFFICER') 
    THEN val
  WHEN CURRENT_ROLE() = 'ATP_DATA_ENGINEER' 
    THEN SUBSTRING(val, 1, 6) || '-****'  -- Partial masking
  ELSE '******-****'                       -- Full masking
END;
```

**Data Classification:**
- `data_classification`: PUBLIC, INTERNAL, CONFIDENTIAL, PII, SENSITIVE
- `data_domain`: PENSION, HOUSING, INTEGRATION, GOVERNANCE
- `cost_center`: FinOps chargeback attribution

---

## Data Flow & Lineage

### Example: Member Contribution Summary

```

 MEMBERS (RAW)       
 - cpr_number        
 - name, address     
 - birth_date        

         
         
     
 EMPLOYERS (RAW)          CONTRIBUTIONS (RAW) 
 - cvr_number             - contribution_id   
 - company_name           - cpr_number        
 - industry               - cvr_number        
      - amount, date      
                        
                                   
         
                   
                   
         
          members_clean       
          (SILVER)            
          + age calculation   
          + validation flags  
         
                    
                    
         
          contributions_enriched      
          (SILVER)                    
          + member demographics       
          + employer details          
          + payment timing            
          + anomaly detection         
         
                    
                    
         
          member_contribution_summary 
          (GOLD)                      
          + lifetime value            
          + payment behavior          
          + risk scores               
         
                    
                    
         
          Power BI Dashboard          
          - Member Risk Analysis      
          - Contribution Trends       
         
```

**Tracked via dbt:**
- Automatic lineage in dbt docs
- Visual DAG in Snowflake Native dbt
- Column-level lineage

---

## CI/CD Pipeline Architecture

```

                    DEVELOPER EXPERIENCE                         
                                                                 
                               
   VS Code                        Snowflake            
  (Local Dev)                     Workspaces           
                               
                                                            
                          
                                                            
                                                              
                            
                   Git Repository                          
              (GitHub: atp-dbt-denmark)                    
                            

                           
                           

                        PULL REQUEST                             
   
  PR Template Auto-Applied                                  
  - Code quality checklist                                  
  - dbt test results                                        
  - Schema change impact                                    
  - Reviewers assigned                                      
   
                                                               
                                                                
   
         Azure DevOps Pipeline                             
               
   dbt compile  dbt run     dbt test          
   (validate) →  (build DEV)→  (100+ tests)       
               
                                                         
                                   PASS  FAIL       
                                                         
   
                                                               
                                              
                                      Block Merge            
                                      (if tests fail)        
                                              

                                     
                            All tests pass
                                     
                                     

                     MERGE TO MAIN BRANCH                        

                        
                        

                   AUTOMATED DEPLOYMENT                          
              
  Deploy DEV  →  Deploy TEST  →  Deploy PROD          
  (automatic)   (approval)     (out of scope)        
              
                                                                 
   
  Snowflake Native dbt Execution:                           
  ALTER GIT REPOSITORY atp_dbt_repo FETCH;                  
  EXECUTE DBT PROJECT atp_dbt_project COMMAND = 'run';      
   

```

---

## Performance Optimization

### Incremental Models (SILVER Layer)

```sql
-- Example: contributions_enriched
{{ config(
  materialized='incremental',
  unique_key='contribution_id',
  on_schema_change='append_new_columns'
) }}

SELECT ...
FROM {{ source('pension_raw', 'contributions') }}

{% if is_incremental() %}
WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
```

**Benefits:**
- Only processes new/changed records
- < 15 min refresh time (vs hours for full refresh)
- Reduced warehouse credits

### Clustering Strategy

```sql
-- Large tables clustered by date and key columns
ALTER TABLE ATP_PENSION.SILVER.CONTRIBUTIONS_ENRICHED
CLUSTER BY (contribution_period, cpr_number);
```

**Benefits:**
- Faster query performance on filtered columns
- Automatic micro-partition pruning
- Reduced data scanning

---

## Monitoring & Observability

### dbt Execution History

```sql
SELECT 
  execution_id,
  project_name,
  command,
  status,
  start_time,
  end_time,
  DATEDIFF('second', start_time, end_time) AS duration_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.DBT_PROJECT_EXECUTION_HISTORY
WHERE project_name = 'ATP_DBT_PROJECT'
ORDER BY start_time DESC;
```

### Warehouse Credit Usage

```sql
SELECT 
  warehouse_name,
  DATE_TRUNC('day', start_time) AS usage_date,
  SUM(credits_used) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name LIKE 'ATP_%'
GROUP BY 1, 2
ORDER BY usage_date DESC;
```

### Data Quality Monitoring

```sql
-- Test failure tracking
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%dbt test%'
AND execution_status = 'FAILED'
ORDER BY start_time DESC;
```

---

## Future Enhancements

### Phase 2: Marketplace & Semantic Layer
- **Data Marketplace**: Streamlit app for data product discovery
- **dbt Semantic Layer**: Centralized metrics definitions
- **Self-Service Analytics**: No-code data exploration

### Phase 3: ML/AI Integration
- **MLflow Integration**: Model registry and experiment tracking
- **Feature Store**: Reusable features for ML
- **ML Lineage**: Track data → features → models → predictions

### Phase 4: Real-Time Streaming
- **Kafka Integration**: Event-driven data ingestion
- **Snowpipe**: Continuous data loading
- **Real-Time Dashboards**: Sub-second latency

---

## Related Documentation

- **dbt Documentation**: See `../dbt/README.md`
- **Terraform Documentation**: See `../terraform/README.md`
- **SQL Setup**: See `../sql/README.md`
- **CI/CD Guide**: See `../ci/README.md`

--- **Document Version:** 1.0.0  
**Last Updated:** November 2024  
**Maintained By:** ATP Data Platform Team

