{{
  config(
    materialized='table',
    tags=['kpi', 'employer_analytics']
  )
}}

/*
  GOLD: Employer contribution analytics
  - Aggregate metrics per employer
  - Industry benchmarking
  - Compliance monitoring
*/

WITH contributions AS (
    SELECT * FROM {{ ref('contributions_enriched') }}
),

employers AS (
    SELECT * FROM {{ source('pension_raw', 'employers') }}
),

employer_analytics AS (
    SELECT
        c.cvr_number,
        c.employer_name,
        c.employer_industry,
        c.employer_size,
        e.num_employees,
        
        -- Contribution metrics
        COUNT(DISTINCT c.cpr_number) AS unique_members,
        COUNT(*) AS total_contributions,
        SUM(c.total_amount) AS total_contribution_value,
        SUM(c.employer_amount) AS total_employer_contribution,
        SUM(c.employee_amount) AS total_employee_contribution,
        AVG(c.total_amount) AS avg_contribution_per_payment,
        
        -- Monthly metrics
        SUM(c.total_amount) / COUNT(DISTINCT c.contribution_period) AS avg_monthly_contribution,
        
        -- Compliance metrics
        SUM(CASE WHEN c.is_late THEN 1 ELSE 0 END) AS late_payment_count,
        SUM(CASE WHEN c.is_late THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT AS late_payment_rate,
        AVG(c.days_late) AS avg_days_late,
        
        -- Risk flags
        CASE
            WHEN SUM(CASE WHEN c.is_late THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT > 0.15 THEN TRUE
            ELSE FALSE
        END AS is_high_risk_employer,
        
        -- Period coverage
        MIN(c.contribution_period) AS first_contribution_period,
        MAX(c.contribution_period) AS last_contribution_period,
        COUNT(DISTINCT c.contribution_period) AS periods_with_contributions,
        
        CURRENT_TIMESTAMP() AS report_generated_at
        
    FROM contributions c
    LEFT JOIN employers e ON c.cvr_number = e.cvr_number
    GROUP BY 
        c.cvr_number,
        c.employer_name,
        c.employer_industry,
        c.employer_size,
        e.num_employees
)

SELECT * FROM employer_analytics

