{{
  config(
    materialized='table',
    tags=['kpi', 'housing_analytics']
  )
}}

/*
  GOLD: Housing benefits summary analytics
  - Application metrics
  - Payment trends
  - Benefit utilization
*/

WITH applications AS (
    SELECT * FROM {{ ref('applications_enriched') }}
),

payments AS (
    SELECT * FROM {{ source('housing_raw', 'payments') }}
),

payment_summary AS (
    SELECT
        application_id,
        COUNT(*) AS total_payments,
        SUM(actual_amount) AS total_amount_paid,
        AVG(actual_amount) AS avg_monthly_benefit,
        MIN(payment_date) AS first_payment_date,
        MAX(payment_date) AS last_payment_date,
        SUM(CASE WHEN has_error THEN 1 ELSE 0 END) AS error_count
    FROM payments
    GROUP BY application_id
),

summary AS (
    SELECT
        a.application_id,
        a.cpr_number,
        a.applicant_name,
        a.applicant_age,
        a.status,
        a.application_date,
        a.approval_date,
        a.processing_days,
        
        -- Housing details
        a.dwelling_type,
        a.dwelling_size_m2,
        a.household_size,
        a.monthly_rent,
        a.annual_income,
        
        -- Benefit calculations
        a.calculated_benefit,
        p.avg_monthly_benefit AS actual_avg_monthly_benefit,
        p.total_amount_paid AS total_benefits_received,
        p.total_payments AS months_receiving_benefits,
        
        -- Utilization rate
        CASE 
            WHEN p.total_payments IS NOT NULL 
            THEN p.total_amount_paid / (a.calculated_benefit * p.total_payments)
            ELSE NULL
        END AS benefit_utilization_rate,
        
        -- Risk flags
        a.high_rent_burden,
        a.benefit_exceeds_limit,
        p.error_count,
        
        CURRENT_TIMESTAMP() AS report_generated_at
        
    FROM applications a
    LEFT JOIN payment_summary p ON a.application_id = p.application_id
    WHERE a.status = 'Approved'
)

SELECT * FROM summary

