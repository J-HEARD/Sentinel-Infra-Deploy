# 📘 Microsoft Sentinel Infrastructure Deployment Guide 📘

This guide provides detailed step-by-step instructions for deploying the complete Microsoft Sentinel infrastructure solution.

## 📑 Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Phase 1: Core Sentinel Deployment](#phase-1-core-sentinel-deployment)
3. [Phase 2: MDVM Connector Deployment](#phase-2-mdvm-connector-deployment)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Verification and Testing](#verification-and-testing)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

---

## 🔍 Pre-Deployment Checklist 🔍

Before beginning deployment, ensure you have:

### Required Permissions
- [ ] **Azure Subscription Owner** or Contributor + User Access Administrator
- [ ] **Log Analytics Contributor** on the target workspace (for Phase 2)
- [ ] **Global Admin** or **Application Administrator** in M365 tenant (for MDVM permissions)

### Technical Requirements
- [ ] Azure subscription with sufficient quota
- [ ] PowerShell 7+ or Azure Cloud Shell access
- [ ] Azure PowerShell modules installed (`Az.Accounts`, `Az.Resources`)

### Planning Decisions
- [ ] Resource naming convention defined
- [ ] Azure region selected
- [ ] Retention period determined (default: 90 days)
- [ ] Data connectors identified
- [ ] Network architecture decided (public vs. private endpoints)

---

## Phase 1: Core Sentinel Deployment

### Step 1: Deploy Core Infrastructure via Portal

1. **Navigate to the deployment page:**
  
   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-ui%2Fmain%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-ui%2Fmain%2FcreateUiDefinition.json)

2. **Configure basic settings:**
   ```
   Subscription:         [Select your subscription]
   Resource Group:       CISO-RG-SENTINEL (or custom name)
   Region:              [Select your region]
   ```

3. **Configure workspace settings:**
   ```
   Workspace Name:       CISO-WS-SENTINEL (or custom name)
   Pricing Tier:        PerGB2018 (recommended)
   Data Retention:      90 (days)
   Daily Quota:         0 (unlimited) or set limit
   ```

4. **Enable features:**
   ```
   Enable UEBA:         Yes (recommended)
   ```

5. **Select data connectors:**
   - ✅ Azure Active Directory
   - ✅ Office 365
   - ✅ Microsoft Defender for Cloud
   - ✅ Microsoft 365 Defender
   - Select others as needed

6. **Review and create:**
   - Click "Review + Create"
   - Verify all settings
   - Click "Create"

### Step 2: Alternative Deployment Methods

#### Via Azure CLI:
```bash
az deployment sub create \
  --location eastus \
  --template-uri https://raw.githubusercontent.com/J-HEARD/sentinel-deploy-ui/main/azuredeploy.json \
  --parameters \
    rgName="CISO-RG-SENTINEL" \
    workspaceName="CISO-WS-SENTINEL" \
    location="eastus" \
    dataRetention=90 \
    enableUeba=true \
    enableDataConnectors='["AzureActiveDirectory","Office365","MicrosoftDefenderForCloud"]'
```

#### Via PowerShell:
```powershell
$params = @{
    rgName = "CISO-RG-SENTINEL"
    workspaceName = "CISO-WS-SENTINEL"
    location = "eastus"
    dataRetention = 90
    enableUeba = $true
    enableDataConnectors = @("AzureActiveDirectory","Office365","MicrosoftDefenderForCloud")
}

New-AzSubscriptionDeployment `
  -Location "eastus" `
  -TemplateUri "https://raw.githubusercontent.com/J-HEARD/sentinel-deploy-ui/main/azuredeploy.json" `
  @params
```

### Step 3: Verify Core Deployment

1. **Navigate to the resource group** in Azure Portal
2. **Verify resources created:**
   - Log Analytics Workspace
   - Microsoft Sentinel (solution)
3. **Check Sentinel portal:**
   - Go to Microsoft Sentinel
   - Select your workspace
   - Verify data connectors are configured

**⏱️ Expected Duration: 5-10 minutes**

---

## Phase 2: MDVM Connector Deployment

### Step 1: Deploy MDVM Infrastructure

1. **Navigate to deployment:**
   
   [![Deploy MDVM Connector](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2Fsentinel-deploy-mdvm%2Fmaster%2FazureDeploy.json)

2. **Configure settings:**
   ```
   Subscription:              [Same as Phase 1]
   Resource Group:            [Same as Phase 1 or new]
   Workspace Name:            CISO-WS-SENTINEL
   Workspace Resource Group:  CISO-RG-SENTINEL
   ```

3. **Review and create:**
   - Click "Review + Create"
   - Note the deployment outputs (you'll need these)

### Step 2: Configure API Permissions

1. **Capture deployment outputs:**
   - Go to Deployments in the resource group
   - Click on the MDVM deployment
   - Go to Outputs tab
   - Copy:
     - `UserAssignedManagedIdentityPrincipalId`
     - `UserAssignedManagedIdentityPrincipalName`

2. **Grant M365 Defender permissions:**

   Open PowerShell and run:
   ```powershell
   # Connect to Azure
   Connect-AzAccount -TenantId [Your-M365-Defender-Tenant-ID]
   
   # Set the managed identity ID from deployment output
   $managedIdentityPrincipalId = '[Paste-PrincipalId-Here]'
   
   # App roles to grant
   $permissions = @('Machine.Read.All','Vulnerability.Read.All','SecurityRecommendation.Read.All')
   
   # Grant permissions script
   $targets = @(
     @{ Name='MDE'; Uri='https://api.securitycenter.microsoft.com' }
   )
   
   foreach ($t in $targets) {
     $sp = (Invoke-AzRestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=servicePrincipalNames/any(s:s eq '$($t.Uri)')").Content | ConvertFrom-Json
     $sp = $sp.value | Select-Object -First 1
     if (-not $sp) { Write-Warning "Service principal not found for $($t.Uri)"; continue }
   
     $desired = @{}
     $sp.appRoles | ForEach-Object { $desired[$_.value] = $_.id }
   
     $existing = @()
     $assign = (Invoke-AzRestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo?`$filter=principalId eq $managedIdentityPrincipalId").Content | ConvertFrom-Json
     if ($assign.value) { $existing = $assign.value.appRoleId }
   
     foreach ($perm in $permissions) {
       $roleId = $desired[$perm]
       if (-not $roleId) { Write-Warning "Role $perm not found on $($t.Name)"; continue }
       if ($existing -contains $roleId) {
         Write-Host "Already assigned: $($t.Name) -> $perm" -ForegroundColor Green
       } else {
         $body = @{ principalId=$managedIdentityPrincipalId; resourceId=$sp.id; appRoleId=$roleId } | ConvertTo-Json
         Invoke-AzRestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo" -Payload $body | Out-Null
         Write-Host "Assigned: $($t.Name) -> $perm" -ForegroundColor Yellow
       }
     }
   }
   ```

3. **Verify permissions:**
   - Check for success messages in PowerShell output
   - All three permissions should show as "Assigned" or "Already assigned"

### Step 3: Initial Function Execution

1. **Navigate to Function App:**
   - Go to the resource group
   - Open the Function App (named `func-mdvm-[unique]`)

2. **Run the function manually:**
   - Click on "Functions" in the left menu
   - Select "GetMDVMData"
   - Click "Code + Test"
   - Click "Test/Run"
   - Click "Run"

3. **Monitor execution:**
   - Check the logs for successful API calls
   - Verify no authentication errors
   - First run may take 5-15 minutes

**⏱️ Expected Duration: 20-30 minutes**

---

## Post-Deployment Configuration

### Configure Analytics Rules

1. **Navigate to Microsoft Sentinel**
2. **Go to Analytics**
3. **Create custom rules for MDVM data:**

   Example rule for critical vulnerabilities:
   ```kusto
   MDVMVulnerabilitiesByDevice_CL
   | where Severity == "Critical"
   | where ExposedMachines > 10
   | project TimeGenerated, CveId, Severity, ExposedMachines, PublicExploit
   ```

### Set Up Workbooks

1. **Navigate to Workbooks**
2. **Find "MDVM Dashboard"**
3. **Pin to dashboard for quick access**

### Configure Automation

1. **Create Logic Apps for:**
   - Ticket creation for critical vulnerabilities
   - Email notifications for new CVEs
   - Teams notifications for security updates

---

## Verification and Testing

### Phase 1 Verification

1. **Check data ingestion:**
   ```kusto
   union withsource=TableName *
   | where TimeGenerated > ago(1h)
   | summarize Count=count() by TableName
   | sort by Count desc
   ```

2. **Verify data connectors:**
   - Go to Data Connectors
   - Check status shows "Connected"
   - Review last data received timestamps

### Phase 2 Verification

1. **Check MDVM tables:**
   ```kusto
   search "MDVM*"
   | distinct $table
   ```

2. **Verify data population:**
   ```kusto
   MDVMVulnerabilitiesByDevice_CL
   | take 10
   ```

3. **Check Function App logs:**
   - Go to Function App
   - Select "Monitor"
   - Review execution history

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Function App authentication fails
**Solution:**
- Verify managed identity permissions were granted
- Ensure you connected to the correct tenant
- Check if M365 Defender API is enabled

#### Issue: No data in MDVM tables
**Solution:**
1. Check Function App execution logs
2. Verify DCR and DCE are properly configured
3. Ensure workspace has proper permissions

#### Issue: Data connectors show disconnected
**Solution:**
1. Re-authenticate the connector
2. Check service principal permissions
3. Verify no conditional access policies blocking

### Debug Commands

```powershell
# Check managed identity
Get-AzUserAssignedIdentity -ResourceGroupName "CISO-RG-SENTINEL"

# Verify Function App settings
Get-AzFunctionApp -ResourceGroupName "CISO-RG-SENTINEL" | Select-Object Name, State

# Check Log Analytics workspace
Get-AzOperationalInsightsWorkspace -ResourceGroupName "CISO-RG-SENTINEL"
```

---

## Maintenance

### Daily Tasks
- Monitor Function App executions
- Review critical vulnerability alerts
- Check data ingestion health

### Weekly Tasks
- Review analytics rule performance
- Update vulnerability priorities
- Check storage account usage

### Monthly Tasks
- Review retention policies
- Optimize analytics rules
- Update documentation
- Review costs and optimization opportunities

### Updating the Solution

1. **To update Function App code:**
   ```powershell
   # Download latest function package
   Invoke-WebRequest -Uri "https://github.com/J-HEARD/sentinel-deploy-mdvm/releases/latest/download/functionPackage.zip" -OutFile "functionPackage.zip"
   
   # Deploy to Function App
   Publish-AzWebApp -ResourceGroupName "CISO-RG-SENTINEL" -Name "func-mdvm-[unique]" -ArchivePath "functionPackage.zip"
   ```

2. **To update ARM templates:**
   - Redeploy using the same parameters
   - ARM will update only changed resources

---

## 🎯 Next Steps

After successful deployment:

1. **Customize analytics rules** based on your environment
2. **Create playbooks** for automated response
3. **Set up additional data sources** as needed
4. **Train SOC team** on new capabilities
5. **Document** your specific configurations

---

**Deployment Complete! 🎉**

Your Microsoft Sentinel infrastructure with MDVM integration is now operational. Monitor the dashboards and refine rules based on your security requirements.
