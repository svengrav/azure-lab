param identifier string = 'azure-lab'

param functioName string = 'func-${identifier}'

param functionPlanName string = 'plan-${identifier}'

param storageName string = 'st${replace(identifier, '-','')}${uniqueString(resourceGroup().name)}'

param appInsightsName string = 'appi-${identifier}'

param windowsFunction bool = true

resource functionPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  location: resourceGroup().location
  name: functionPlanName
  sku: {
    // consumption
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: !windowsFunction // If reserved its a linux function
  }
}

resource function 'Microsoft.Web/sites@2021-02-01' = {
  name: functioName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionPlan.id
    httpsOnly: true
    clientAffinityEnabled: true
    siteConfig: {
      appSettings: [
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsights.properties.InstrumentationKey
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value}'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'dotnet'
        }
      ]
    }
  }
  dependsOn: [
    storage
    functionPlan
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  location: resourceGroup().location
  name: storageName
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
