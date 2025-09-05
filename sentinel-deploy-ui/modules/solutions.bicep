@description('Sentinel workspace name')
param workspaceName string

@description('Deployment location (use the workspace location)')
param location string

@description('URI to the Microsoft Entra ID solution mainTemplate.json')
param microsoftEntraIdSolutionUri string = 'https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/Solutions/Microsoft%20Entra%20ID/Package/mainTemplate.json'

var azureActivityUri = 'https://catalogartifact.azureedge.net/publicartifacts/azuresentinel.azure-sentinel-solution-azureactivity-c9097f86-9937-4d19-9849-736db696b675-azure-sentinel-solution-azureactivity/Artifacts/mainTemplate.json'

resource azureActivity 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'AzureActivity'
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: azureActivityUri
      contentVersion: '1.0.0.0'
    }
    parameters: {
      workspace:            { value: workspaceName }
      location:             { value: location }
      'workspace-location': { value: location }
      'workbook1-name':     { value: 'Azure Activity' }
    }
  }
}

resource microsoftEntraId 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'MicrosoftEntraID'
  properties: {
    mode: 'Incremental'
    templateLink: {
      uri: microsoftEntraIdSolutionUri
      contentVersion: '1.0.0.0'
    }
    parameters: {
      workspace:            { value: workspaceName }
      location:             { value: location }
      'workspace-location': { value: location }
    }
  }
}
