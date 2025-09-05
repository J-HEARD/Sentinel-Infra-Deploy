targetScope = 'subscription'

@description('8-digit numeric suffix. Defaults to a value derived from current UTC time.')
@minLength(8)
@maxLength(8)
param suffix string = substring(utcNow('yyyyMMddHHmmssffff'), 8, 8)

var rgName        = 'RGsentest${suffix}'
var workspaceName = 'WSsentest${suffix}'

@description('Pricing tier (PerGB2018 = Pay-As-You-Go)')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param pricingTier string = 'PerGB2018'

@description('Daily ingestion limit in GB')
param dailyQuota int = 2

@description('Data retention in days')
@minValue(7)
@maxValue(730)
param dataRetention int = 90

@description('If true when changing retention to 30 days, older data deleted immediately')
param immediatePurgeDataOn30Days bool = true

@description('Enable UEBA (User and Entity BEHAVIOURAL Analytics)')
param enableUEBA bool = true

@description('Array of data connectors to enable')
@allowed([
  'AzureActiveDirectory'
  'Office365'
  'AzureActiveDirectoryIDP'
  'AzureActivity'
  'MicrosoftDefenderForCloud'
  'Microsoft365Defender'
  'Dynamics365'
  'IOT'
  'Office365Project'
  'OfficeIRM'
  'PowerBI'
  'ThreatIntelligence'
])
param enableDataConnectors array = []

@description('AAD data types')
@allowed([
  'SignInLogs'
  'AuditLogs'
  'NonInteractiveUserSignInLogs'
  'ServicePrincipalSignInLogs'
  'ManagedIdentitySignInLogs'
  'ProvisioningLogs'
  'ADFSSignInLogs'
  'UserRiskEvents'
  'RiskyUsers'
  'NetworkAccessTrafficLogs'
  'RiskyServicePrincipals'
  'ServicePrincipalRiskEvents'
])
param aadStreams array = []

@description('Deployment location')
param location string = deployment().location

// Create the resource group (always required for nested deployments)
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
}

// Deploy workspace
module workspace './modules/workspace.bicep' = {
  name: 'workspaceCreation'
  scope: rg
  params: {
    workspaceName: workspaceName
    pricingTier: pricingTier
    dailyQuota: dailyQuota
    dataRetention: dataRetention
    immediatePurgeDataOn30Days: immediatePurgeDataOn30Days
    location: location
  }
}

// Deploy settings (UEBA) via ARM template
module settings './modules/settings.bicep' = {
  name: 'settingsDeploy'
  scope: rg
  dependsOn: [workspace]
  params: {
    workspaceName: workspaceName
    enableUeba: enableUEBA
    identityProviders: []
    enableDiagnostics: false
  }
}

// signInLogs module removed as per design correction

// Deploy Microsoft Entra ID (Azure AD) solution
module solutions './modules/solutions.bicep' = {
  name: 'aadSolutionDeploy'
  scope: rg
  dependsOn: [
    workspace
    settings
  ]
  params: {
    workspaceName: workspaceName
    location: location
  }
}

// Deploy data connectors via ARM template
module dataConnectors './modules/dataConnectors.bicep' = if (!empty(enableDataConnectors)) {
  name: 'dataConnectorsDeploy'
  scope: rg
  dependsOn: [
    workspace
    settings
    solutions
  ]
  params: {
    dataConnectorsKind: enableDataConnectors
    aadStreams: aadStreams
    workspaceName: workspaceName
    tenantId: subscription().tenantId
    subscriptionId: subscription().subscriptionId
    location: location
  }
}

output workspaceName string = workspaceName
