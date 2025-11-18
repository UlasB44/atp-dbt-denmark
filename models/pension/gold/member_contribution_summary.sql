{{
  config(
    materialized='table',
    tags=['kpi', 'member_analytics']
  )
}}

/*
  GOLD: Member contribution summary
  - Aggregate contribution metrics per member
  - Calculate lifetime value
  - Payment behavior analysis
*/

WITH contributions AS (
    SELECT * FROM {{ ref('contributions_enriched') }}
),

member_summary AS (
    SELECT
        cpr_number,
        member_name,
        member_age,
        
        -- Contribution metrics
        COUNT(*) AS total_contributions,
        SUM(total_amount) AS lifetime_contribution_value,
        AVG(total_amount) AS avg_contribution_amount,
        MIN(contribution_period) AS first_contribution_period,
        MAX(contribution_period) AS last_contribution_period,
        
        -- Payment behavior
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END) AS late_payment_count,
        AVG(CASE WHEN is_late THEN days_late ELSE 0 END) AS avg_days_late,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT AS late_payment_rate,
        
        -- Anomalies
        SUM(CASE WHEN is_anomaly THEN 1 ELSE 0 END) AS anomaly_count,
        
        -- Recent activity (last 6 months)
        SUM(CASE 
            WHEN TO_DATE(contribution_period || '-01', 'YYYY-MM-DD') >= DATEADD('month', -6, CURRENT_DATE())
            THEN total_amount 
            ELSE 0 
        END) AS recent_6m_contributions,
        
        -- Risk scoring
        CASE
            WHEN SUM(CASE WHEN is_late THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT > 0.10 THEN 'High Risk'
            WHEN SUM(CASE WHEN is_late THEN 1 ELSE 0 END)::FLOAT / COUNT(*)::FLOAT > 0.05 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS payment_risk_category,
        
        CURRENT_TIMESTAMP() AS report_generated_at
        
    FROM contributions
    GROUP BY cpr_number, member_name, member_age
)

SELECT * FROM member_summary

