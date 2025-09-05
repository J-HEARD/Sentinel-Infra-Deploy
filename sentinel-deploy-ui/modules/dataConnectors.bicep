@description('Kinds of data connectors to enable (AAD, O365, Defender, etc.)')
param dataConnectorsKind array = []

@description('AAD stream types to enable')
param aadStreams array = []

@description('Workspace name to attach connectors')
param workspaceName string

@description('Tenant ID for connector configuration')
param tenantId string

@description('Subscription ID for connector configuration')
param subscriptionId string

@description('Deployment location')
param location string

// Reference the existing Log Analytics workspace
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Treat either label as "enable Entra ID"
var enableEntra = contains(dataConnectorsKind, 'MicrosoftEntraID') || contains(dataConnectorsKind, 'AzureActiveDirectory')

// Entra ID connector (diagnostic settings, will fail if limit in tenancy is reached. Reder to docs on how to clear)
resource entraDiagnostics 'Microsoft.aadiam/diagnosticSettings@2017-04-01' = if (enableEntra) {
  name: '${workspaceName}-entraDiagnosticSettings'
  scope: tenant()
  properties: {
    workspaceId: law.id
    logs: [
      { category: 'SignInLogs',                       enabled: contains(aadStreams,'SignInLogs') }
      { category: 'AuditLogs',                        enabled: contains(aadStreams,'AuditLogs') }
      { category: 'NonInteractiveUserSignInLogs',     enabled: contains(aadStreams,'NonInteractiveUserSignInLogs') }
      { category: 'ServicePrincipalSignInLogs',       enabled: contains(aadStreams,'ServicePrincipalSignInLogs') }
      { category: 'ManagedIdentitySignInLogs',        enabled: contains(aadStreams,'ManagedIdentitySignInLogs') }
      { category: 'ProvisioningLogs',                 enabled: contains(aadStreams,'ProvisioningLogs') }
      { category: 'ADFSSignInLogs',                   enabled: contains(aadStreams,'ADFSSignInLogs') }
      { category: 'UserRiskEvents',                   enabled: contains(aadStreams,'UserRiskEvents') }
      { category: 'RiskyUsers',                       enabled: contains(aadStreams,'RiskyUsers') }
      { category: 'NetworkAccessTrafficLogs',         enabled: contains(aadStreams,'NetworkAccessTrafficLogs') }
      { category: 'RiskyServicePrincipals',           enabled: contains(aadStreams,'RiskyServicePrincipals') }
      { category: 'ServicePrincipalRiskEvents',       enabled: contains(aadStreams,'ServicePrincipalRiskEvents') }
      { category: 'EnrichedOffice365AuditLogs',       enabled: contains(aadStreams,'EnrichedOffice365AuditLogs') }
      { category: 'MicrosoftGraphActivityLogs',       enabled: contains(aadStreams,'MicrosoftGraphActivityLogs') }
      { category: 'RemoteNetworkHealthLogs',          enabled: contains(aadStreams,'RemoteNetworkHealthLogs') }
    ]
  }
}

// O365 Connector
resource o365Connector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2020-01-01' = if(contains(dataConnectorsKind, 'Office365')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'o365')}'
  location: location
  kind: 'Office365'
  properties: {
    tenantId: tenantId
    dataTypes: {
      exchange: { state: 'enabled' }
      sharePoint: { state: 'enabled' }
      teams: { state: 'enabled' }
    }
  }
}

// AAD Identity Protection
resource aadipConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2020-01-01' = if(contains(dataConnectorsKind, 'AzureActiveDirectoryIDP')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'aadip')}'
  location: location
  kind: 'AzureActiveDirectory'
  properties: {
    tenantId: tenantId
    dataTypes: { alerts: { state: 'enabled' } }
  }
}

// Azure Activity
resource azureActivityConnector 'Microsoft.OperationalInsights/workspaces/dataSources@2020-03-01-preview' = if(contains(dataConnectorsKind, 'AzureActivity')) {
  name: '${workspaceName}/${replace(subscriptionId,'-','')}'
  location: location
  kind: 'AzureActivityLog'
  properties: {
    linkedResourceId: '/subscriptions/${subscriptionId}/providers/microsoft.insights/eventtypes/management'
  }
}

// Defender for Cloud
resource mdcConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2020-01-01' = if(contains(dataConnectorsKind, 'MicrosoftDefenderForCloud')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'asc')}'
  location: location
  kind: 'AzureSecurityCenter'
  properties: {
    subscriptionId: subscriptionId
    dataTypes: { alerts: { state: 'enabled' } }
  }
}

// Microsoft 365 Defender
resource m365dConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'Microsoft365Defender')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'm365d')}'
  location: location
  kind: 'MicrosoftThreatProtection'
  properties: {
    tenantId: tenantId
    dataTypes: { incidents: { state: 'enabled' } }
  }
}

// Dynamics 365
resource d365Connector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'Dynamics365')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'd365')}'
  location: location
  kind: 'Dynamics365'
  properties: {
    tenantId: tenantId
    dataTypes: { dynamics365CdsActivities: { state: 'enabled' } }
  }
}

// IoT
resource iotConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'IOT')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'iot')}'
  location: location
  kind: 'IOT'
  properties: {
    subscriptionId: subscriptionId
    dataTypes: { alerts: { state: 'enabled' } }
  }
}

// Office 365 Project
resource projectConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'Office365Project')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'project')}'
  location: location
  kind: 'Office365Project'
  properties: {
    tenantId: tenantId
    dataTypes: { logs: { state: 'enabled' } }
  }
}

// Office IRM
resource irmConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'OfficeIRM')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'irm')}'
  location: location
  kind: 'OfficeIRM'
  properties: {
    tenantId: tenantId
    dataTypes: { alerts: { state: 'enabled' } }
  }
}

// PowerBI
resource powerbiConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2022-12-01-preview' = if(contains(dataConnectorsKind, 'PowerBI')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'powerbi')}'
  location: location
  kind: 'OfficePowerBI'
  properties: {
    tenantId: tenantId
    dataTypes: { logs: { state: 'enabled' } }
  }
}

// Threat Intelligence
resource tiConnector 'Microsoft.OperationalInsights/workspaces/providers/dataConnectors@2020-01-01' = if(contains(dataConnectorsKind, 'ThreatIntelligence')) {
  name: '${workspaceName}/Microsoft.SecurityInsights/${uniqueString(resourceGroup().id, 'ti')}'
  location: location
  kind: 'ThreatIntelligence'
  properties: {
    tenantId: tenantId
    dataTypes: { indicators: { state: 'enabled' } }
  }
}

