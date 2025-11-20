# 🔄 Snowflake Task Graph - Alternative Orchestration Demo

## 📋 Overview

This demonstrates **Snowflake Tasks** as an alternative to dbt for orchestration. The task graph replicates the pension data pipeline using native Snowflake features.

---

## 🎯 Task Graph Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TASK GRAPH DAG                           │
└─────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────┐
    │  TASK_MEMBERS_CLEAN          │
    │  (SILVER Layer)              │
    │                              │
    │  Schedule: Daily 2 AM UTC    │
    │  Warehouse: ATP_ETL_WH       │
    └──────────────┬───────────────┘
                   │
                   │ AFTER (Dependency)
                   ▼
    ┌──────────────────────────────┐
    │  TASK_CONTRIBUTIONS_ENRICHED │
    │  (SILVER Layer)              │
    │                              │
    │  Triggered after Task 1      │
    │  Warehouse: ATP_ETL_WH       │
    └──────────────┬───────────────┘
                   │
                   │ AFTER (Dependency)
                   ▼
    ┌──────────────────────────────┐
    │  TASK_MEMBER_CONTRIBUTION_   │
    │  SUMMARY (GOLD Layer)        │
    │                              │
    │  Triggered after Task 2      │
    │  Warehouse: ATP_ETL_WH       │
    └──────────────────────────────┘
```

---

## 🚀 Quick Start

### Step 1: Deploy Task Graph

```sql
-- In Snowflake, run:
USE ROLE ACCOUNTADMIN;
USE DATABASE ATP_PENSION;

-- Execute the entire script
@atp-dbt-github/sql/04_create_task_graph.sql
```

### Step 2: Verify Tasks Created

```sql
-- Show all tasks
SHOW TASKS IN SCHEMA ATP_PENSION.PUBLIC;

-- Show task graph
SELECT 
    name AS task_name,
    state AS task_state,
    schedule,
    predecessors AS depends_on
FROM TABLE(INFORMATION_SCHEMA.TASK_DEPENDENTS(
    TASK_NAME => 'ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN',
    RECURSIVE => TRUE
))
ORDER BY name;
```

### Step 3: Test Execution (Manual)

```sql
-- Execute tasks manually for testing
EXECUTE TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN;

-- Wait 30 seconds, then check if next tasks ran
SELECT * 
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
WHERE database_name = 'ATP_PENSION'
ORDER BY scheduled_time DESC;
```

---

## 📊 Task Details

### Task 1: MEMBERS_CLEAN
**Purpose**: Clean and enrich member data  
**Source**: `RAW.MEMBERS`  
**Target**: `SILVER.MEMBERS_CLEAN`  
**Schedule**: Daily at 2 AM UTC  
**Operations**:
- Calculate age from birth_date
- Categorize into age groups
- Map postal code to region
- Calculate data quality score

### Task 2: CONTRIBUTIONS_ENRICHED
**Purpose**: Enrich contributions with member + employer data  
**Source**: `RAW.CONTRIBUTIONS`  
**Target**: `SILVER.CONTRIBUTIONS_ENRICHED`  
**Dependency**: AFTER Task 1  
**Operations**:
- Join with members (age, gender)
- Join with employers (company name)
- Calculate total contributions
- Categorize employment type

### Task 3: MEMBER_CONTRIBUTION_SUMMARY
**Purpose**: Create member-level analytics  
**Source**: `SILVER.CONTRIBUTIONS_ENRICHED`  
**Target**: `GOLD.MEMBER_CONTRIBUTION_SUMMARY`  
**Dependency**: AFTER Task 2  
**Operations**:
- Aggregate contributions by member
- Calculate lifetime totals
- Identify contribution trends
- Determine current employer

---

## 🎨 Viewing the Task Graph in Snowflake UI

### Option 1: Task Dependents View

1. Go to Snowflake UI
2. Navigate: **Data** → **Databases** → **ATP_PENSION** → **PUBLIC** → **Tasks**
3. Click on `TASK_MEMBERS_CLEAN`
4. View **Graph** tab to see dependencies

### Option 2: SQL Query

```sql
-- Get task graph with metadata
SELECT 
    name AS task_name,
    state,
    schedule,
    predecessors,
    warehouse,
    comment
FROM TABLE(INFORMATION_SCHEMA.TASK_DEPENDENTS(
    TASK_NAME => 'ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN',
    RECURSIVE => TRUE
))
ORDER BY name;
```

---

## 📈 Monitoring & Observability

### View Task Execution History

```sql
-- Last 7 days of task runs
SELECT 
    name AS task_name,
    state AS execution_state,
    scheduled_time,
    query_start_time,
    completed_time,
    DATEDIFF('second', query_start_time, completed_time) AS duration_seconds,
    error_code,
    error_message
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -7, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 100
))
WHERE database_name = 'ATP_PENSION'
ORDER BY scheduled_time DESC;
```

### View Custom Execution Log

```sql
-- Custom log table with row counts
SELECT 
    task_name,
    rows_processed,
    execution_time,
    DATEDIFF('minute', LAG(execution_time) OVER (
        PARTITION BY task_name 
        ORDER BY execution_time
    ), execution_time) AS minutes_since_last_run
FROM ATP_GOVERNANCE.METADATA.TASK_EXECUTION_LOG
ORDER BY execution_time DESC
LIMIT 50;
```

---

## ⚙️ Task Management

### Resume Tasks (Start Execution)

```sql
-- Resume all tasks (in reverse order due to dependencies)
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY RESUME;
ALTER TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED RESUME;
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN RESUME;
```

### Suspend Tasks (Stop Execution)

```sql
-- Suspend to save compute credits
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN SUSPEND;
ALTER TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED SUSPEND;
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBER_CONTRIBUTION_SUMMARY SUSPEND;
```

### Modify Schedule

```sql
-- Change to run every 6 hours
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN 
SET SCHEDULE = 'USING CRON 0 */6 * * * UTC';

-- Change to run on weekdays only (Mon-Fri at 2 AM)
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN 
SET SCHEDULE = 'USING CRON 0 2 * * 1-5 UTC';
```

---

## 🆚 dbt vs Snowflake Tasks Comparison

| Aspect | dbt | Snowflake Tasks |
|--------|-----|-----------------|
| **Orchestration** | External (Airflow, dbt Cloud, GitHub Actions) | Native Snowflake (serverless) |
| **Scheduling** | Requires external scheduler | Built-in CRON or event-based |
| **Dependencies** | Via `{{ ref() }}` | Via `AFTER` clause |
| **Testing** | Built-in schema tests | Manual SQL checks |
| **Documentation** | Auto-generated docs + lineage | Manual comments |
| **Incremental Updates** | Easy (`incremental` materialization) | Manual logic required |
| **Version Control** | Git-native | SQL files in Git |
| **Dev/Test/Prod** | Built-in targets | Manual environment management |
| **Observability** | dbt logs + dbt Cloud UI | `TASK_HISTORY()` + custom logs |
| **Cost** | dbt Cloud license OR self-hosted | Serverless compute (pay per second) |
| **Learning Curve** | Moderate (Jinja + YAML) | Low (just SQL + task syntax) |
| **Best For** | Complex transformations, team collaboration, CI/CD | Simple ETL, minimal external dependencies |

---

## 💡 When to Use Each

### Use dbt When:
- ✅ You have a dev/test/prod workflow
- ✅ Team collaboration is important
- ✅ You need built-in testing and documentation
- ✅ Complex transformation logic
- ✅ CI/CD integration required
- ✅ Version control is critical

### Use Snowflake Tasks When:
- ✅ Simple, scheduled ETL jobs
- ✅ Minimal external dependencies
- ✅ Native Snowflake operations only
- ✅ Cost-conscious (serverless compute)
- ✅ Quick prototyping
- ✅ No access to external orchestration tools

### Use Both When:
- ✅ dbt for development + transformations
- ✅ Snowflake Tasks for production scheduling
- ✅ Best of both worlds!

---

## 🎯 Demo Script (5 Minutes)

### Slide 1: The Challenge
> "ATP needs to process pension data daily. We have two options: external orchestration (dbt + Airflow) or native Snowflake Tasks."

### Slide 2: Show the Task Graph
```sql
-- Show task dependencies
SELECT name, state, predecessors, schedule
FROM TABLE(INFORMATION_SCHEMA.TASK_DEPENDENTS(
    TASK_NAME => 'ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN',
    RECURSIVE => TRUE
));
```

> "This is a 3-task pipeline: clean members → enrich contributions → create summary. Tasks run sequentially with dependencies."

### Slide 3: Manual Execution
```sql
-- Execute first task
EXECUTE TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN;
```

> "I can trigger tasks manually for testing, or let them run on schedule."

### Slide 4: Monitor Execution
```sql
-- Show task history
SELECT name, state, scheduled_time, completed_time, 
       DATEDIFF('second', query_start_time, completed_time) AS duration
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
WHERE database_name = 'ATP_PENSION';
```

> "Full observability: execution times, success/failure, error messages."

### Slide 5: The Results
```sql
-- Show summary data
SELECT COUNT(*) AS members_processed,
       SUM(total_contributions_dkk) AS total_contributions
FROM GOLD.MEMBER_CONTRIBUTION_SUMMARY;
```

> "✅ Data processed  
> ✅ Zero external dependencies  
> ✅ Native Snowflake observability  
> ✅ Serverless compute (cost-efficient)"

---

## 🔧 Troubleshooting

### Task Not Running?

```sql
-- Check task state
SHOW TASKS LIKE 'TASK_%';

-- Resume if suspended
ALTER TASK ATP_PENSION.PUBLIC.TASK_MEMBERS_CLEAN RESUME;
```

### Task Failed?

```sql
-- Check error messages
SELECT name, error_code, error_message, query_text
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -1, CURRENT_TIMESTAMP())
))
WHERE state = 'FAILED'
ORDER BY scheduled_time DESC;
```

### Dependency Issues?

```sql
-- Verify dependencies are correct
DESCRIBE TASK ATP_PENSION.PUBLIC.TASK_CONTRIBUTIONS_ENRICHED;
```

---

## 📝 Summary

✅ **Created**: 3-task pipeline (SILVER → GOLD)  
✅ **Orchestration**: Native Snowflake (no external tools)  
✅ **Scheduling**: Daily at 2 AM UTC  
✅ **Dependencies**: Task 2 depends on Task 1, Task 3 depends on Task 2  
✅ **Observability**: `TASK_HISTORY()` + custom logs  
✅ **Demo-ready**: Can execute manually or show scheduled runs  

---

**Files Created:**
- `sql/04_create_task_graph.sql` - Complete task graph setup
- `docs/TASK_GRAPH_DEMO.md` - This guide

**Next Steps:**
1. Run `04_create_task_graph.sql` in Snowflake
2. Test manual execution
3. Show task graph in UI
4. Compare with dbt approach

