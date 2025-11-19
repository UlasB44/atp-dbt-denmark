# 🔷 Azure DevOps Setup Guide - ATP Denmark dbt Project

## 📋 Overview

This guide will help you set up the ATP Denmark dbt project in Azure DevOps with:
- ✅ Git repository
- ✅ CI/CD pipelines
- ✅ Secure secret management
- ✅ Automated dbt runs
- ✅ Environment management (Dev/Prod)

---

## 🚀 Step-by-Step Setup

### Step 1: Create Azure DevOps Project

1. Go to https://dev.azure.com
2. Click **"+ New project"**
3. Fill in details:
   - **Project name**: `ATP-Denmark`
   - **Description**: `ATP Denmark Data Warehouse - dbt on Snowflake`
   - **Visibility**: Private
   - **Version control**: Git
   - **Work item process**: Agile
4. Click **"Create"**

---

### Step 2: Import Repository from GitHub

#### Option A: Import via UI

1. In your new project, go to **Repos** → **Files**
2. Click **"Import a repository"**
3. Fill in:
   - **Clone URL**: `https://github.com/UlasB44/atp-dbt-denmark.git`
   - **Name**: `atp-dbt-denmark`
   - **Requires authentication**: No (public repo)
4. Click **"Import"**

#### Option B: Mirror from GitHub (Continuous Sync)

```bash
# Clone from GitHub
git clone https://github.com/UlasB44/atp-dbt-denmark.git
cd atp-dbt-denmark

# Add Azure DevOps remote
git remote add azure https://<your-org>@dev.azure.com/<your-org>/ATP-Denmark/_git/atp-dbt-denmark

# Push to Azure DevOps
git push azure main --force
```

---

### Step 3: Create Variable Group for Secrets

1. Go to **Pipelines** → **Library**
2. Click **"+ Variable group"**
3. Name: `snowflake-credentials`
4. Add variables:

| Variable Name | Value | Type |
|---------------|-------|------|
| `SNOWFLAKE_ACCOUNT` | `UTYEYAD-XT83149` | Plain text |
| `SNOWFLAKE_USER` | `admin` | Plain text |
| `SNOWFLAKE_PASSWORD` | `TpqTqe4v@M9Usorku@RA` | 🔒 Secret |
| `SNOWFLAKE_USER_PROD` | `admin` | Plain text |
| `SNOWFLAKE_PASSWORD_PROD` | `<prod_password>` | 🔒 Secret |

**Important**: Click the 🔒 (lock) icon for passwords to mark them as secrets!

5. Click **"Save"**

---

### Step 4: Create Azure Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **"New pipeline"**
3. Select **"Azure Repos Git"**
4. Select your repository: `atp-dbt-denmark`
5. Select **"Existing Azure Pipelines YAML file"**
6. Path: `/azure-pipelines.yml`
7. Click **"Continue"**
8. Review the pipeline YAML
9. Click **"Run"**

---

### Step 5: Create Environments

1. Go to **Pipelines** → **Environments**
2. Click **"New environment"**
3. Create **Production** environment:
   - **Name**: `production`
   - **Description**: `Snowflake Production Environment`
   - **Resource**: None
4. Click **"Create"**
5. In environment settings:
   - Go to **Approvals and checks**
   - Add **"Approvals"**
   - Add required approvers
   - This ensures manual approval before production deployment

---

### Step 6: Upload Pipeline Files

Copy the pipeline files to your Azure DevOps repo:

```bash
# In your local clone
mkdir -p azure-devops
cp /Users/ulasbulut/Desktop/Cursor/atp/azure-devops/* azure-devops/

# Commit and push
git add azure-devops/
git commit -m "Add Azure DevOps pipeline configuration"
git push azure main
```

---

### Step 7: Configure Branch Policies

1. Go to **Repos** → **Branches**
2. Click **"..."** next to `main` branch
3. Select **"Branch policies"**
4. Enable:
   - ✅ **Require a minimum number of reviewers**: 1
   - ✅ **Check for linked work items**: Optional
   - ✅ **Check for comment resolution**: Recommended
   - ✅ **Build validation**: Select your pipeline

---

## 📂 Repository Structure

```
ATP-Denmark/
├── azure-pipelines.yml          # Main CI/CD pipeline
├── models/                      # dbt models
│   ├── pension/
│   ├── housing/
│   └── integration/
├── python_models/               # Snowpark Python equivalents
├── dbt_project.yml             # dbt configuration
├── profiles.yml                # Connection profiles (uses secrets)
├── terraform-atp/              # Infrastructure as Code
└── azure-devops/               # Azure DevOps specific files
    ├── AZURE_DEVOPS_SETUP.md
    ├── azure-pipelines-dev.yml
    └── azure-pipelines-prod.yml
```

---

## 🔄 CI/CD Pipeline Flow

### Pull Request Pipeline
```
PR Created → Build Stage
            ├─ Install dbt
            ├─ dbt debug (test connection)
            ├─ dbt deps (install packages)
            ├─ dbt run (build models in Dev)
            ├─ dbt test (run data quality tests)
            └─ Publish test results
```

### Main Branch Pipeline
```
Merge to Main → Build Stage → Deploy Stage
                ├─ dbt run (Dev)     ├─ Wait for approval
                ├─ dbt test (Dev)    ├─ dbt run (Prod)
                └─ Artifacts         └─ dbt test (Prod)
```

---

## 🔐 Secret Management

### Current Setup (Variable Groups)
✅ Secrets stored in Azure DevOps Library
✅ Encrypted at rest
✅ Access controlled by Azure RBAC
✅ Audit logged

### Enhanced Setup (Azure Key Vault)

For production, link to Azure Key Vault:

1. **Create Azure Key Vault**:
   ```bash
   az keyvault create \
     --name atp-denmark-kv \
     --resource-group atp-rg \
     --location westeurope
   ```

2. **Add Secrets**:
   ```bash
   az keyvault secret set \
     --vault-name atp-denmark-kv \
     --name SNOWFLAKE-PASSWORD \
     --value "TpqTqe4v@M9Usorku@RA"
   ```

3. **Link to Variable Group**:
   - Go to **Pipelines** → **Library**
   - Click **"+ Variable group"**
   - Toggle **"Link secrets from an Azure key vault"**
   - Select your subscription and Key Vault
   - Add secrets

---

## 🎯 Pipeline Features

### ✅ Implemented Features

| Feature | Status | Description |
|---------|--------|-------------|
| **Automated Builds** | ✅ | Triggers on code push |
| **dbt Tests** | ✅ | Runs data quality tests |
| **Test Results** | ✅ | Published to Azure DevOps |
| **Artifacts** | ✅ | dbt docs and manifests |
| **Multi-Stage** | ✅ | Dev → Prod deployment |
| **Manual Approval** | ✅ | Required for production |
| **Secret Management** | ✅ | Azure Variable Groups |
| **Branch Protection** | ✅ | PR required for main |

### 🔄 Coming Soon

| Feature | Status | Description |
|---------|--------|-------------|
| **Terraform Deploy** | 📋 Planned | IaC deployment |
| **Snowflake Tests** | 📋 Planned | SQL-based tests |
| **Data Quality Dashboard** | 📋 Planned | dbt docs hosting |
| **Slack Notifications** | 📋 Planned | Build status alerts |

---

## 📊 Monitoring & Observability

### View Pipeline Runs
1. Go to **Pipelines** → **Pipelines**
2. Select your pipeline
3. View run history, logs, and test results

### View dbt Artifacts
1. Go to pipeline run
2. Click **"1 published"** (artifacts)
3. Download **dbt-artifacts**
4. Extract and view:
   - `manifest.json` - Model lineage
   - `run_results.json` - Execution results
   - `catalog.json` - Data catalog

### View Test Results
1. Go to pipeline run
2. Click **"Tests"** tab
3. View pass/fail status
4. Drill into failures

---

## 🔧 Customization

### Run on Schedule

Add to `azure-pipelines.yml`:

```yaml
schedules:
  - cron: "0 6 * * *"  # Daily at 6 AM
    displayName: Daily dbt run
    branches:
      include:
        - main
    always: true
```

### Add Slack Notifications

```yaml
- task: SlackNotification@1
  inputs:
    SlackApiToken: '$(SLACK_TOKEN)'
    MessageAuthor: 'Azure DevOps'
    MessageText: 'dbt pipeline completed!'
```

### Deploy Terraform First

```yaml
- stage: Infrastructure
  jobs:
    - job: terraform_apply
      steps:
        - script: |
            terraform init
            terraform apply -auto-approve
```

---

## 🐛 Troubleshooting

### Pipeline Fails on dbt debug

**Issue**: Connection to Snowflake fails

**Fix**:
1. Check Variable Group has correct credentials
2. Verify SNOWFLAKE_ACCOUNT format (should be `UTYEYAD-XT83149`)
3. Test connection manually:
   ```bash
   snowsql -a UTYEYAD-XT83149 -u admin
   ```

### dbt test failures

**Issue**: Data quality tests fail

**Fix**:
1. Review test results in pipeline
2. Check logs for specific failures
3. Fix data or adjust tests
4. Re-run pipeline

### Secret not found

**Issue**: `$(SNOWFLAKE_PASSWORD)` not resolving

**Fix**:
1. Ensure Variable Group is linked to pipeline
2. Check variable name matches exactly
3. Verify it's marked as secret

---

## ✅ Checklist

Before going live, ensure:

- [ ] Azure DevOps project created
- [ ] Repository imported from GitHub
- [ ] Variable group `snowflake-credentials` created
- [ ] Secrets added and marked as 🔒
- [ ] Pipeline created from `azure-pipelines.yml`
- [ ] Production environment created with approvals
- [ ] Branch policies enabled on `main`
- [ ] First pipeline run successful
- [ ] Test results published
- [ ] dbt artifacts available

---

## 📚 Additional Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [dbt Azure DevOps Guide](https://docs.getdbt.com/docs/deploy/azure-devops)
- [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 🎉 You're All Set!

Your ATP Denmark project is now fully integrated with Azure DevOps!

**Next Steps**:
1. Make a code change
2. Create a Pull Request
3. Watch the pipeline run automatically
4. Merge to main
5. Approve production deployment
6. Monitor results in Azure DevOps

🚀 **Happy deploying!**

