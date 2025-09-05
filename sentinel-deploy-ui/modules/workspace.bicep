@description('Name for the Log Analytics workspace')
param workspaceName string

@description('Daily ingestion limit in GB')
param dailyQuota int = 2

@description('Data retention in days')
@minValue(7)
@maxValue(730)
param dataRetention int = 90

@description('If true when changing retention to 30 days, older data deleted immediately')
param immediatePurgeDataOn30Days bool = true

@description('Pricing tier (PerGB2018 = Pay-As-You-Go)')
param pricingTier string = 'PerGB2018'

@description('Location for the workspace')
param location string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: pricingTier
    }
    retentionInDays: dataRetention
    workspaceCapping: {
      dailyQuotaGb: dailyQuota
    }
    features: {
      immediatePurgeDataOn30Days: immediatePurgeDataOn30Days
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
