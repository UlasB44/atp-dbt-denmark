"""
Snowpark Python version of members_clean
Runs natively in Snowflake Workspaces
"""
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, concat, datediff, current_date, current_timestamp, length, when, lit
from snowflake.snowpark.types import *
import sys

def create_members_clean(session: Session):
    """
    SILVER: Clean and validated member data
    Equivalent to: models/pension/silver/members_clean.sql
    """
    
    print("=" * 80)
    print("Creating SILVER.members_clean (Snowpark Python)")
    print("=" * 80)
    
    # Read source data
    source_df = session.table("ATP_PENSION.RAW.MEMBERS")
    
    # Apply transformations
    cleaned_df = source_df.select(
        col("cpr_number"),
        col("first_name"),
        col("last_name"),
        concat(col("first_name"), lit(" "), col("last_name")).alias("full_name"),
        col("gender"),
        col("birth_date"),
        
        # Calculate age
        datediff("year", col("birth_date"), current_date()).alias("age"),
        
        col("civil_status"),
        col("street_address"),
        col("postal_code"),
        col("city"),
        col("is_active"),
        col("registration_date"),
        col("last_updated"),
        
        # Data quality flags
        when(
            (length(col("cpr_number")) != 11) |
            (~col("cpr_number").like("%-%")) |
            (col("first_name").isNull()) |
            (col("last_name").isNull()),
            lit(False)
        ).otherwise(lit(True)).alias("is_valid_record"),
        
        current_timestamp().alias("dbt_updated_at")
    )
    
    # Write to table
    cleaned_df.write.mode("overwrite").save_as_table(
        "ATP_PENSION.SILVER.members_clean"
    )
    
    # Get row count
    count = session.table("ATP_PENSION.SILVER.members_clean").count()
    print(f"\n✓ Created members_clean with {count:,} rows")
    
    # Run tests
    print("\nRunning data quality tests...")
    
    # Test 1: Uniqueness
    total = session.table("ATP_PENSION.SILVER.members_clean").count()
    distinct = session.table("ATP_PENSION.SILVER.members_clean").select("cpr_number").distinct().count()
    if total != distinct:
        print(f"⚠ WARNING: Found {total - distinct} duplicate CPR numbers")
    else:
        print("✓ PASS: CPR numbers are unique")
    
    # Test 2: No nulls
    null_count = session.table("ATP_PENSION.SILVER.members_clean").filter(
        col("first_name").isNull() | col("last_name").isNull()
    ).count()
    if null_count > 0:
        print(f"✗ FAIL: Found {null_count} records with null names")
    else:
        print("✓ PASS: No null names")
    
    # Test 3: Age range
    invalid_age = session.table("ATP_PENSION.SILVER.members_clean").filter(
        (col("age") < 18) | (col("age") > 100)
    ).count()
    if invalid_age > 0:
        print(f"⚠ WARNING: Found {invalid_age} records with age outside 18-100")
    else:
        print("✓ PASS: All ages within valid range")
    
    print("\n" + "=" * 80)
    return count

def main():
    # Get session from Snowflake Workspace context
    session = Session.builder.getOrCreate()
    
    try:
        row_count = create_members_clean(session)
        print(f"\n✅ SUCCESS: members_clean created with {row_count:,} rows\n")
        return 0
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())

