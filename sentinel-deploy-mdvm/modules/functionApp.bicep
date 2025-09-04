param FunctionAppName string
param Location string
param UserAssignedMiId string
param UserAssignedMiPrincipalId string
param HostingPlanId string
param AppSettings array
param DeployFunctionCode bool
param RoleIdOwner string

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: FunctionAppName
  location: Location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedMiId}': {}
    }
  }
  kind: 'functionapp'
  properties: {
    serverFarmId: HostingPlanId
    httpsOnly: true
    siteConfig: {
      appSettings: AppSettings
      powerShellVersion: '7.4'
      minTlsVersion: '1.2' 
      ftpsState: 'Disabled'
      alwaysOn: false
      publicNetworkAccess: 'Enabled'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ] 
      }  
    }
  }
}

resource roleAssignmentFa 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (DeployFunctionCode == true) {
  name: guid(subscription().id, resourceGroup().id, UserAssignedMiId)
  scope: functionApp
  properties: {
    principalId: UserAssignedMiPrincipalId
    roleDefinitionId: RoleIdOwner
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.name
output functionAppId string = functionApp.id
