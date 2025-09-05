@description('Name for the Log Analytics workspace')
param workspaceName string

@description('Whether or not UEBA should be enabled')
param enableUeba bool = true

@description('Array of identity providers to sync with UEBA. Valid values: ActiveDirectory, AzureActiveDirectory')
param identityProviders array = [
  'AzureActiveDirectory'
]

@description('Enable diagnostic settings on SentinelHealth')
param enableDiagnostics bool = false

@description('Diagnostic setting resource name')
param settingName string = 'HealthSettings'

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Ensure Sentinel is enabled
resource sentinelOnboarding 'Microsoft.SecurityInsights/onboardingStates@2024-03-01' = {
  name: 'default'
  scope: law
  properties: {}
}

// Enable UEBA Entity Analytics if requested and providers are set
resource entityAnalytics 'Microsoft.SecurityInsights/settings@2022-12-01-preview' = if (enableUeba && length(identityProviders) > 0) {
  name: 'EntityAnalytics'
  scope: law
  kind: 'EntityAnalytics'
  properties: {
    entityProviders: identityProviders
  }
  dependsOn: [
    sentinelOnboarding
  ]
}

// Enable Behavior Analytics solution if UEBA is enabled
resource behaviorAnalytics 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableUeba) {
  name: 'BehaviorAnalyticsInsights(${workspaceName})'
  location: resourceGroup().location
  properties: {
    workspaceResourceId: law.id
  }
  plan: {
    name: 'BehaviorAnalyticsInsights(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/BehaviorAnalyticsInsights'
    promotionCode: ''
  }
  dependsOn: [
    sentinelOnboarding
  ]
}

// Enable diagnostic settings if requested
resource diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: settingName
  scope: law
  properties: {
    workspaceId: law.id
    logs: [
      {
        category: 'Automation'
        enabled: true
      }
      {
        category: 'DataConnectors'
        enabled: true
      }
      {
        category: 'Analytics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    sentinelOnboarding
  ]
}
