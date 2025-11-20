"""
Snowpark Python version of member_contribution_summary
Runs natively in Snowflake Workspaces
"""
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, sum as sum_, count, min as min_, max as max_, round as round_, when, lit, current_timestamp
from snowflake.snowpark.types import *
import sys

def create_member_contribution_summary(session: Session):
    """
    GOLD: Member-level contribution summary
    Equivalent to: models/pension/gold/member_contribution_summary.sql
    """
    
    print("=" * 80)
    print("Creating GOLD.member_contribution_summary (Snowpark Python)")
    print("=" * 80)
    
    # Read source tables
    contributions = session.table("ATP_PENSION.SILVER.contributions_enriched")
    members = session.table("ATP_PENSION.SILVER.members_clean")
    
    # Calculate summary
    summary_df = members.join(
        contributions,
        members["cpr_number"] == contributions["cpr_number"],
        "left"
    ).group_by(
        members["cpr_number"],
        members["full_name"],
        members["age"],
        members["city"],
        members["civil_status"]
    ).agg(
        sum_(contributions["total_amount"]).alias("total_contributed_amount"),
        count(contributions["contribution_id"]).alias("total_contributions"),
        count(when(contributions["is_late"], lit(1))).alias("late_contributions_count"),
        min_(contributions["contribution_period"]).alias("first_contribution_period"),
        max_(contributions["contribution_period"]).alias("last_contribution_period")
    ).select(
        col("cpr_number"),
        col("full_name"),
        col("age"),
        col("city"),
        col("civil_status"),
        col("total_contributed_amount"),
        col("total_contributions"),
        col("late_contributions_count"),
        
        # Late payment rate
        round_(
            (col("late_contributions_count") * 100.0) / 
            when(col("total_contributions") == 0, lit(1)).otherwise(col("total_contributions")),
            2
        ).alias("late_payment_rate"),
        
        col("first_contribution_period"),
        col("last_contribution_period"),
        
        # Risk categorization
        when(
            ((col("late_contributions_count") * 100.0) / 
             when(col("total_contributions") == 0, lit(1)).otherwise(col("total_contributions"))) < 5,
            lit("Low Risk")
        ).when(
            ((col("late_contributions_count") * 100.0) /
             when(col("total_contributions") == 0, lit(1)).otherwise(col("total_contributions"))) < 20,
            lit("Medium Risk")
        ).otherwise(lit("High Risk")).alias("payment_risk_category"),
        
        current_timestamp().alias("dbt_updated_at")
    )
    
    # Write to table
    summary_df.write.mode("overwrite").save_as_table(
        "ATP_PENSION.GOLD.member_contribution_summary"
    )
    
    # Get row count
    count_result = session.table("ATP_PENSION.GOLD.member_contribution_summary").count()
    print(f"\n✓ Created member_contribution_summary with {count_result:,} rows")
    
    # Show summary statistics
    print("\nSummary Statistics:")
    stats = session.table("ATP_PENSION.GOLD.member_contribution_summary").group_by(
        "payment_risk_category"
    ).agg(
        count("*").alias("member_count"),
        round_(sum_("total_contributed_amount") / count("*"), 2).alias("avg_total_contribution"),
        round_(sum_("late_payment_rate") / count("*"), 2).alias("avg_late_payment_rate")
    ).sort("payment_risk_category")
    
    print(f"{'Risk Category':<20} {'Members':>10} {'Avg Total':>15} {'Avg Late %':>12}")
    print("-" * 60)
    for row in stats.collect():
        print(f"{row['PAYMENT_RISK_CATEGORY']:<20} {row['MEMBER_COUNT']:>10,} {row['AVG_TOTAL_CONTRIBUTION']:>15,.2f} {row['AVG_LATE_PAYMENT_RATE']:>12,.2f}%")
    
    print("\n" + "=" * 80)
    return count_result

def main():
    session = Session.builder.getOrCreate()
    
    try:
        row_count = create_member_contribution_summary(session)
        print(f"\n✅ SUCCESS: member_contribution_summary created with {row_count:,} rows\n")
        return 0
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())

