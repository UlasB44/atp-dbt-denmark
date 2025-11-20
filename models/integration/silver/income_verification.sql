{{
  config(
    materialized='table',
    tags=['integration', 'verification']
  )
}}

/*
  SILVER: Income verification from SKAT
  - Cross-reference with housing applications
  - Income validation
*/

WITH skat_data AS (
    SELECT * FROM {{ source('integration_raw', 'skat_income_data') }}
),

housing_apps AS (
    SELECT * FROM {{ ref('applications_enriched') }}
),

verification AS (
    SELECT
        h.application_id,
        h.cpr_number,
        h.applicant_name,
        h.application_date,
        
        -- Declared income from application
        h.annual_income AS declared_income,
        
        -- Verified income from SKAT
        s.annual_income AS verified_income,
        s.tax_year,
        s.tax_paid,
        
        -- Variance analysis
        ABS(h.annual_income - s.annual_income) AS income_variance,
        ABS(h.annual_income - s.annual_income) / s.annual_income AS income_variance_pct,
        
        -- Verification status
        CASE
            WHEN s.annual_income IS NULL THEN 'No SKAT Data'
            WHEN ABS(h.annual_income - s.annual_income) / s.annual_income < 0.05 THEN 'Verified'
            WHEN ABS(h.annual_income - s.annual_income) / s.annual_income < 0.10 THEN 'Minor Discrepancy'
            ELSE 'Major Discrepancy'
        END AS verification_status,
        
        -- Risk flag
        CASE
            WHEN ABS(h.annual_income - s.annual_income) / s.annual_income > 0.20 THEN TRUE
            ELSE FALSE
        END AS requires_manual_review,
        
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM housing_apps h
    LEFT JOIN skat_data s 
        ON h.cpr_number = s.cpr_number 
        AND s.tax_year = YEAR(h.application_date)
)

SELECT * FROM verification

