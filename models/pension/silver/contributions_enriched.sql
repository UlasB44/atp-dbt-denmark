{{
  config(
    materialized='incremental',
    unique_key='contribution_id',
    tags=['financial', 'contribution_data']
  )
}}

/*
  SILVER: Enriched contribution data
  - Joins with members and employers
  - Calculates payment metrics
  - Flags anomalies
*/

WITH source AS (
    SELECT * FROM {{ source('pension_raw', 'contributions') }}
    {% if is_incremental() %}
    WHERE created_at > (SELECT MAX(created_at) FROM {{ this }})
    {% endif %}
),

members AS (
    SELECT * FROM {{ ref('members_clean') }}
),

employers AS (
    SELECT * FROM {{ source('pension_raw', 'employers') }}
),

enriched AS (
    SELECT
        c.contribution_id,
        c.cpr_number,
        m.full_name AS member_name,
        m.age AS member_age,
        
        c.cvr_number,
        e.company_name AS employer_name,
        e.industry_name AS employer_industry,
        e.size_category AS employer_size,
        
        c.contribution_period,
        YEAR(TO_DATE(c.contribution_period || '-01', 'YYYY-MM-DD')) AS contribution_year,
        MONTH(TO_DATE(c.contribution_period || '-01', 'YYYY-MM-DD')) AS contribution_month,
        
        c.employer_amount,
        c.employee_amount,
        c.total_amount,
        c.payment_date,
        c.is_late,
        
        -- Calculate days late
        CASE 
            WHEN c.is_late THEN 
                DATEDIFF('day', 
                    TO_DATE(c.contribution_period || '-01', 'YYYY-MM-DD'),
                    c.payment_date
                )
            ELSE 0
        END AS days_late,
        
        -- Flag anomalies
        CASE
            WHEN c.total_amount < 100 OR c.total_amount > 500 THEN TRUE
            ELSE FALSE
        END AS is_anomaly,
        
        -- Expected amount (270 DKK standard)
        270.0 AS expected_amount,
        c.total_amount - 270.0 AS amount_variance,
        
        c.created_at,
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM source c
    LEFT JOIN members m ON c.cpr_number = m.cpr_number
    LEFT JOIN employers e ON c.cvr_number = e.cvr_number
)

SELECT * FROM enriched

