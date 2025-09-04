targetScope = 'subscription'

// Dummy wrapper template to enable "Deploy to Azure" from VS Code
// This file does not alter deployment behavior, it simply includes
// the existing azuredeploy.json ARM template for ease of use.

resource sentinelDeployUI 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'sentinelDeployUI-wrapper'
  properties: {
    mode: 'Incremental'
    template: loadJsonContent('./azuredeploy.json')
    // Parameters are optional – you can pass them inline during deploy if needed
    parameters: {}
  }
}
