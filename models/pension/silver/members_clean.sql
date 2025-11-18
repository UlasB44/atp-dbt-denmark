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
        
        -- Parse birth date from CPR (DDMMYY-XXXX)
        TO_DATE(LEFT(cpr_number, 6), 'DDMMYY') AS birth_date,
        
        -- Calculate age
        DATEDIFF('year', TO_DATE(LEFT(cpr_number, 6), 'DDMMYY'), CURRENT_DATE()) AS age,
        
        -- Gender from CPR (last digit: odd=male, even=female)
        CASE 
            WHEN MOD(CAST(RIGHT(cpr_number, 1) AS INTEGER), 2) = 0 THEN 'Female'
            ELSE 'Male'
        END AS gender,
        
        civil_status,
        street_address,
        postal_code,
        city,
        email,
        phone_number,
        is_active,
        registration_date,
        last_updated,
        
        -- Data quality flags
        CASE
            WHEN LENGTH(cpr_number) <> 11 THEN FALSE
            WHEN cpr_number NOT LIKE '%-%' THEN FALSE
            WHEN email IS NULL THEN FALSE
            ELSE TRUE
        END AS is_valid_record,
        
        CURRENT_TIMESTAMP() AS dbt_updated_at
        
    FROM source
)

SELECT * FROM cleaned

