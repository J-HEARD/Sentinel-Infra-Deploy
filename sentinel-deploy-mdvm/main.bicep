var deploymentVersion = '1.1.2'
@description('A globally unique name for the Function App to be created which will run the code to ingest MDVM data into Sentinel.')
param FunctionAppName string = 'fa-mdvm-${uniqueString(resourceGroup().id)}'
@description('A globally unique name for the Key Vault to be created which will store Function App secrets.')
param KeyVaultName string = 'kv-mdvm-${uniqueString(resourceGroup().id)}'
@description('A globally unique name for the Function App Storage Account. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param StorageAccountName string = 'samdvm${uniqueString(resourceGroup().id)}'
@description('Name of custom role to be created at the Log Analytics resource group level. The name needs to be unique across the entire tenant. This role provides the Function App read access to the MDVM custom tables.')
param CustomRoleName string = 'Custom Role - Sentinel MDVM Table Reader'
@description('Name for Data Collection Endpoint used to ingest data into Log Analytics workspace.')
param DataCollectionEndpointName string = 'dce-mdvm-${uniqueString(resourceGroup().id)}'
@description('Name for Data Collection Rule used to ingest data into Log Analytics workspace.')
param DataCollectionRuleName string = 'dcr-mdvm-${uniqueString(resourceGroup().id)}'
@description('Azure Resource ID (NOT THE WORKSPACE ID) of the existing Log Analytics Workspace where you would like the MDVM data and optional Function App Application Insights data to reside. This can be found by clicking the "JSON View" link within the Overview page of the Log Analytics workspace resource. The format is: "/subscriptions/xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx/resourcegroups/xxxxxxxx/providers/microsoft.operationalinsights/workspaces/xxxxxxxx"')
param LogAnalyticsWorkspaceResourceID string = '/subscriptions/xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx-xxxxxxxx/resourcegroups/xxxxxxxx/providers/microsoft.operationalinsights/workspaces/xxxxxxxx'
@description('Deploy Azure workbooks to help visualize the MDVM data.')
param DeployWorkbooks bool = true
@description('Use the Azure Deployment Script resource to automatically deploy the Function App code. This requires the Microsoft.ContainerInstance resource provider to be registred on the subsription.')
param DeployFunctionCode bool = true
@description('GitHub repo where Azure Function package and post deployment script is located. Leave the default value unless you are using content from a different location. This is not applicable if the Deploy Function Code parameter is set to false.')
param RepoUri string = 'https://raw.githubusercontent.com/J-HEARD/Sentinel-Infra-Deploy/master/sentinel-deploy-mdvm'

var location = resourceGroup().location
var functionAppPackageUri = '${RepoUri}/functionPackage.zip'
var deploymentScriptUri = '${RepoUri}/deploymentScript.ps1'
var roleIdOwner = '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
var roleIdStorageBlobDataOwner = '/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b'

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: split(LogAnalyticsWorkspaceResourceID, '/')[8]
  scope: resourceGroup(split(LogAnalyticsWorkspaceResourceID, '/')[2], split(LogAnalyticsWorkspaceResourceID, '/')[4])
}

resource userAssignedMi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uami-${FunctionAppName}'
  location: location
}

module createCustomTables 'modules/customDcrTables.bicep' = {
  name: 'createCustomTables'
  params: {
    LogAnalyticsWorkspaceLocation: law.location
    LogAnalyticsWorkspaceResourceId: law.id
    DataCollectionEndpointName: DataCollectionEndpointName
    DataCollectionRuleName: DataCollectionRuleName
    ServicePrincipalId: userAssignedMi.properties.principalId
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: StorageAccountName
  dependsOn: [
    createCustomTables
  ]
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2' 
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    allowSharedKeyAccess: false 
  }
}

/*
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = if(EnableElasticPremiumPlan == true) {
  name: '${storageAccount.name}/default/${toLower(FunctionAppName)}'
}
*/


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: KeyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    } 
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: userAssignedMi.properties.principalId
        permissions: {
          secrets: [
            'get'
            'set'
            'list'
            'delete'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}



resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: FunctionAppName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    reserved: false
  }
}

var appSettingsDefault = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: ''
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'powershell'
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
  {
    name: 'LawResourceId'
    value: law.id
  }
  {
    name: 'DcrImmutableId'
    value: createCustomTables.outputs.DcrImmutableId
  }
  {
    name: 'DceUri'
    value: createCustomTables.outputs.DceUri
  }
  {
    name: 'UamiClientId'
    value: userAssignedMi.properties.clientId
  }
  {
    name: 'FullImport'
    value: '0'
  }
  {
    name: 'DeploymentVersion'
    value: deploymentVersion
  }
]

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, roleIdStorageBlobDataOwner, userAssignedMi.id) 
  scope: storageAccount 
  properties: {
    principalId: userAssignedMi.properties.principalId
    roleDefinitionId: roleIdStorageBlobDataOwner
    principalType: 'ServicePrincipal' 
  }
}

module functionAppDeploy 'modules/functionApp.bicep' = {
  name: 'functionAppDeploy'
  params: {
    AppSettings: appSettingsDefault
    FunctionAppName: FunctionAppName 
    HostingPlanId: hostingPlan.id
    Location: location 
    UserAssignedMiId: userAssignedMi.id
    DeployFunctionCode: DeployFunctionCode
    UserAssignedMiPrincipalId: userAssignedMi.properties.principalId
    RoleIdOwner: roleIdOwner 
  }
  dependsOn: [
    storageRoleAssignment 
  ]
}



module roleAssignmentLaw 'modules/lawRoleAssignment.bicep' = {
  scope: resourceGroup(split(law.id, '/')[2], split(law.id, '/')[4])
  dependsOn: [
    createCustomTables
  ]
  name: 'rbacAssignmentLaw'
  params: {
    PrincipalId: userAssignedMi.properties.principalId
    LawName: split(law.id, '/')[8]
    RoleName: CustomRoleName
  }
}

module sentinelWorkbooks 'modules/sentinelWorkbooks.bicep' = if (DeployWorkbooks == true) {
  name: 'sentinelWorkbooks'
  scope: resourceGroup(split(law.id, '/')[2], split(law.id, '/')[4])
  dependsOn: [
    createCustomTables
    functionAppDeploy
  ]
  params: {
    WorkbookSourceId: law.id
    Location: law.location
  }
}


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = if (DeployFunctionCode == true) {
  name: 'deployCode'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedMi.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '12.3'
    retentionInterval: 'PT1H'
    timeout: 'PT10M'
    cleanupPreference: 'Always'
    primaryScriptUri: deploymentScriptUri
    arguments: '-PackageUri ${functionAppPackageUri} -SubscriptionId ${split(subscription().id, '/')[2]} -ResourceGroupName ${resourceGroup().name} -FunctionAppName ${functionAppDeploy.outputs.functionAppName} -FAScope ${functionAppDeploy.outputs.functionAppId} -UAMIPrincipalId ${userAssignedMi.properties.principalId}'
  }
}

output UserAssignedManagedIdentityPrincipalId string = userAssignedMi.properties.principalId
output UserAssignedManagedIdentityPrincipalName string = userAssignedMi.name
