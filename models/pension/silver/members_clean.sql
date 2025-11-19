{{
  config(
    materialized='incremental',
    unique_key='cpr_number',
    tags=['pii', 'member_data']
  )
}}

/*
  SILVER: Clean and validated member data
  - Validates CPR number format
  - Calculates age from CPR
  - Adds data quality flags
*/

WITH source AS (
    SELECT * FROM {{ source('pension_raw', 'members') }}
    {% if is_incremental() %}
    WHERE last_updated > (SELECT MAX(last_updated) FROM {{ this }})
    {% endif %}
),

cleaned AS (
    SELECT
        cpr_number,
        first_name,
        last_name,
        CONCAT(first_name, ' ', last_name) AS full_name,
        gender,
        birth_date,
        
        -- Calculate age
        DATEDIFF('year', birth_date, CURRENT_DATE()) AS age,
        
        civil_status,
        street_address,
        postal_code,
        city,
        is_active,
        registration_date,
        last_updated,
        
        -- Data quality flags
        CASE
            WHEN LENGTH(cpr_number) <> 11 THEN FALSE
            WHEN cpr_number NOT LIKE '%-%' THEN FALSE
            WHEN first_name IS NULL OR last_name IS NULL THEN FALSE
            ELSE TRUE
        END AS is_valid_record,
        
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM source
)

SELECT * FROM cleaned

