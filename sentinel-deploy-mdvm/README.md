# Microsoft Defender Vulnerability Management Sentinel Data Connector

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJ-HEARD%2FSentinel-Infra-Deploy%2Fmaster%2Fsentinel-deploy-mdvm%2FazureDeploy.json)

This custom data connector uses a Function App to pull Microsoft Defender Vulnerability Management (MDVM) data from the M365 Defender API and ingests into the selected Log Analytics workspace via the Azure Monitor DCR API. Public NIST CVE information is also ingested to enrich the MDVM data. A custom workbook is also included to visualize the data. Six custom tables are created in the workspace:
- *MDVMCVEKB_CL* - MDVM CVE knowledge base.
- *MDVMNISTCVEKB_CL* - NIST CVE knowledge base
- *MDVMNISTConfigurations_CL* - NIST CVE knowledge base: known vulnerable software configurations.
- *MDVMRecommendations_CL* - MDVM recommendations.
- *MDVMSecureConfigurationsByDevice_CL* - Secure configuration assessment details for each device.
- *MDVMVulnerabilitiesByDevice_CL* - Vulnerability assessment details for each device.

## **Pre-requisites**
1. An Azure Subscription
2. An Azure Sentinel/Log Analytics workspace
3. Permissions required to deploy resources:
    - Owner permissions on the target resource group.
    - Log Analytics Contributor or higher permissions on the destination Log Analytics workspace.
4. Permissions required for assigning the needed permissions post deployment:
    - Global Admin or Application Administrator privileges on Defender tenant. This is to give the solution access to the Defender API.

## **Deployment Process**
## 1. Deploy Azure Resources
1. Click the **Deploy to Azure** button above.
2. Once in the Azure Portal, select the **Subscription** and **Resource Group** to deploy the resources into.
3. Enter your **Workspace Name** and **Workspace Resource Group** (the resource group containing your Log Analytics workspace). All other resource names are automatically generated.
4. Click **Review and Create**.
5. Click **Create**.ged ieduln
6. When the deployment has completed, grab the UserAssignedManagedIdentityPrincipalId and UserAssignedManagedIdentityPrincipalName values from the deployment Outputs section. These will be used in the next step.

## 2. Assign Needed Permissions
After the resources have been deployed, we need to assign the appropriate M365 Defender API permissions to the newly created User Assigned Managed Identity by doing the following:
1. From a PowerShell prompt, connect to Azure via [Connect-AzAccount -TenantId [The Tenant ID your Defender instance resides in.]](https://learn.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount?view=azps-9.2.0) with an account that has the Global Admin or Application Administrator role assigned. Then, run the following PowerShell commands:
```PowerShell
# Managed identity principalId (GUID). Paste the value between quotes
$managedIdentityPrincipalId = ''

# App roles to grant
$permissions = @('Machine.Read.All','Vulnerability.Read.All','SecurityRecommendation.Read.All')

# Resolve resource apps by URI (works even if display names differ)
$targets = @(
  @{ Name='MDE';   Uri='https://api.securitycenter.microsoft.com' }
)

foreach ($t in $targets) {
  $sp = (Invoke-AzRestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=servicePrincipalNames/any(s:s eq '$($t.Uri)')").Content | ConvertFrom-Json
  $sp = $sp.value | Select-Object -First 1
  if (-not $sp) { Write-Warning "Service principal not found for $($t.Uri)"; continue }

  # Map role values to IDs
  $desired = @{}
  $sp.appRoles | ForEach-Object { $desired[$_.value] = $_.id }

  # Existing assignments for this MI
  $existing = @()
  $assign = (Invoke-AzRestMethod -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo?`$filter=principalId eq $managedIdentityPrincipalId").Content | ConvertFrom-Json
  if ($assign.value) { $existing = $assign.value.appRoleId }

  foreach ($perm in $permissions) {
    $roleId = $desired[$perm]
    if (-not $roleId) { Write-Warning "Role $perm not found on $($t.Name)"; continue }
    if ($existing -contains $roleId) {
      Write-Host "Already assigned: $($t.Name) -> $perm"
    } else {
      $body = @{ principalId=$managedIdentityPrincipalId; resourceId=$sp.id; appRoleId=$roleId } | ConvertTo-Json
      Invoke-AzRestMethod -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo" -Payload $body | Out-Null
      Write-Host "Assigned: $($t.Name) -> $perm"
    }
  }
}
```

## 3. Run Function App
The Function App is configured to run daily at 12:00 AM UTC. You can either wait for the next scheduled run or you can force a run by performing the following:
1. Open the newly deployed Function App in the Azure Portal.
2. Select the **GetMDVMData** Function in the Overview section.
3. Select **Code and Test**.
4. Select **Test/Run**. Note: If you deployed using private networking, you will either need to have connectivity to the private endpoint or, temporarily remove [network access restrictions](https://learn.microsoft.com/en-us/azure/app-service/overview-access-restrictions).
5. Select **Run**.

After a successful run, you should see data populated in the MDVM* custom tables.

<br>

---

Credit: Alex Anders
