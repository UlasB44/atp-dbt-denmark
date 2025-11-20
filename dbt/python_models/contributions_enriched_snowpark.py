"""
Snowpark Python version of contributions_enriched
Runs natively in Snowflake Workspaces
"""
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, when, lit, year, month, to_date, dateadd, datediff, current_timestamp
from snowflake.snowpark.types import *
import sys

def create_contributions_enriched(session: Session):
    """
    SILVER: Enriched contribution data
    Equivalent to: models/pension/silver/contributions_enriched.sql
    """
    
    print("=" * 80)
    print("Creating SILVER.contributions_enriched (Snowpark Python)")
    print("=" * 80)
    
    # Read source tables
    contributions = session.table("ATP_PENSION.RAW.CONTRIBUTIONS")
    members = session.table("ATP_PENSION.SILVER.members_clean")
    employers = session.table("ATP_PENSION.RAW.EMPLOYERS")
    
    # Join and enrich
    enriched_df = contributions.join(
        members,
        contributions["cpr_number"] == members["cpr_number"],
        "left"
    ).join(
        employers,
        contributions["cvr_number"] == employers["cvr_number"],
        "left"
    ).select(
        contributions["contribution_id"],
        contributions["cpr_number"],
        contributions["cvr_number"],
        
        # Member details
        members["full_name"].alias("member_name"),
        members["age"].alias("member_age"),
        
        # Employer details
        employers["company_name"].alias("employer_name"),
        employers["industry_name"].alias("employer_industry"),
        employers["size_category"].alias("employer_size"),
        
        # Contribution details
        contributions["contribution_period"],
        year(to_date(contributions["contribution_period"], "YYYY-MM")).alias("contribution_year"),
        month(to_date(contributions["contribution_period"], "YYYY-MM")).alias("contribution_month"),
        contributions["employer_amount"],
        contributions["employee_amount"],
        (contributions["employer_amount"] + contributions["employee_amount"]).alias("total_amount"),
        contributions["payment_date"],
        
        # Payment timing
        when(
            contributions["payment_date"] > dateadd("day", lit(10), 
                dateadd("month", lit(1), to_date(contributions["contribution_period"], "YYYY-MM"))),
            lit(True)
        ).otherwise(lit(False)).alias("is_late"),
        
        when(
            contributions["payment_date"] > dateadd("day", lit(10),
                dateadd("month", lit(1), to_date(contributions["contribution_period"], "YYYY-MM"))),
            datediff("day",
                dateadd("day", lit(10), dateadd("month", lit(1), to_date(contributions["contribution_period"], "YYYY-MM"))),
                contributions["payment_date"])
        ).otherwise(lit(0)).alias("days_late"),
        
        # Anomaly detection
        when(
            ((contributions["employer_amount"] + contributions["employee_amount"]) > 500) |
            ((contributions["employer_amount"] + contributions["employee_amount"]) < 100),
            lit(True)
        ).otherwise(lit(False)).alias("is_anomaly"),
        
        lit(270).alias("expected_amount"),
        ((contributions["employer_amount"] + contributions["employee_amount"]) - 270).alias("amount_variance"),
        
        contributions["created_at"],
        current_timestamp().alias("dbt_updated_at")
    )
    
    # Write to table
    enriched_df.write.mode("overwrite").save_as_table(
        "ATP_PENSION.SILVER.contributions_enriched"
    )
    
    # Get row count
    count = session.table("ATP_PENSION.SILVER.contributions_enriched").count()
    print(f"\n✓ Created contributions_enriched with {count:,} rows")
    
    # Run tests
    print("\nRunning data quality tests...")
    
    # Test: Valid amounts
    invalid_amounts = session.table("ATP_PENSION.SILVER.contributions_enriched").filter(
        (col("employer_amount") < 0) | (col("employer_amount") > 10000)
    ).count()
    if invalid_amounts > 0:
        print(f"⚠ WARNING: Found {invalid_amounts} contributions with amounts outside 0-10,000 DKK")
    else:
        print("✓ PASS: All amounts within valid range")
    
    print("\n" + "=" * 80)
    return count

def main():
    session = Session.builder.getOrCreate()
    
    try:
        row_count = create_contributions_enriched(session)
        print(f"\n✅ SUCCESS: contributions_enriched created with {row_count:,} rows\n")
        return 0
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())

