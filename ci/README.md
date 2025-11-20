# Azure DevOps Setup for ATP Denmark

## Files in this Directory

| File | Purpose |
|------|---------|
| `azure-pipelines.yml` | Main CI/CD pipeline (Build → Test → Deploy) |
| `azure-pipelines-dev.yml` | DEV environment pipeline (manual trigger) |
| `AZURE_DEVOPS_SETUP.md` | Complete setup guide with step-by-step instructions |
| `README.md` | This file |

---

## Quick Start

1. **Read the setup guide**: `AZURE_DEVOPS_SETUP.md`
2. **Create Azure DevOps project**: ATP-Denmark
3. **Import repository** from GitHub: `https://github.com/UlasB44/atp-dbt-denmark.git`
4. **Create Variable Group**: `snowflake-credentials`
5. **Add secrets**: SNOWFLAKE_PASSWORD (mark as secret!)
6. **Create pipeline** from `azure-pipelines.yml`
7. **Run pipeline** and verify success

---

## Required Secrets

Set these in Azure DevOps → Pipelines → Library → Variable Groups:

```
Variable Group Name: snowflake-credentials

Variables:
- SNOWFLAKE_ACCOUNT (plain text)
- SNOWFLAKE_USER (plain text)
- SNOWFLAKE_PASSWORD ( secret)
- SNOWFLAKE_USER_PROD (plain text)
- SNOWFLAKE_PASSWORD_PROD ( secret)
```

---

## Pipeline Stages

```
Pull Request:
 Build & Test
     dbt debug
     dbt run
     dbt test
     Publish results

Main Branch:
 Build & Test
  dbt debug
  dbt run
  dbt test
  Publish artifacts

 Deploy to Production
     Manual approval required
     dbt run (prod)
     dbt test (prod)
```

---

## Features

-  Automated CI/CD on push
-  Pull Request validation
-  Multi-stage deployment (Dev → Prod)
-  Manual approval for production
-  Secure secret management
-  Test result publishing
-  dbt artifact publishing
-  Branch protection

---

## Documentation

See `AZURE_DEVOPS_SETUP.md` for:
- Step-by-step setup instructions
- Secret management guide
- Troubleshooting tips
- Customization options
- Monitoring & observability

--- **Azure DevOps + dbt + Snowflake = Production-Ready Data Platform!**

