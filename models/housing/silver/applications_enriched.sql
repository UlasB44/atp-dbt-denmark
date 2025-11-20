{{
  config(
    materialized='incremental',
    unique_key='application_id',
    tags=['housing', 'applications']
  )
}}

/*
  SILVER: Enriched housing benefit applications
  - Links to member data
  - Calculates processing time
  - Eligibility validation
*/

WITH source AS (
    SELECT * FROM {{ source('housing_raw', 'applications') }}
    {% if is_incremental() %}
    WHERE last_updated > (SELECT MAX(last_updated) FROM {{ this }})
    {% endif %}
),

members AS (
    SELECT * FROM {{ ref('members_clean') }}
),

enriched AS (
    SELECT
        a.application_id,
        a.cpr_number,
        m.full_name AS applicant_name,
        m.age AS applicant_age,
        m.civil_status,
        
        a.application_date,
        a.status,
        a.approval_date,
        DATEDIFF('day', a.application_date, a.approval_date) AS processing_days,
        
        -- Financial details
        a.annual_income,
        a.monthly_rent,
        a.household_size,
        a.dwelling_type,
        a.dwelling_size_m2,
        a.calculated_benefit,
        
        -- Eligibility checks
        CASE
            WHEN a.monthly_rent / a.annual_income * 12 > 0.40 THEN TRUE
            ELSE FALSE
        END AS high_rent_burden,
        
        CASE
            WHEN a.calculated_benefit > a.monthly_rent * 0.80 THEN TRUE
            ELSE FALSE
        END AS benefit_exceeds_limit,
        
        a.last_updated,
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM source a
    LEFT JOIN members m ON a.cpr_number = m.cpr_number
)

SELECT * FROM enriched

