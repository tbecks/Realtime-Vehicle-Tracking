param projectName string = ''
param utcValue string = utcNow()

var location = resourceGroup().location

var unique = substring(uniqueString(resourceGroup().id),3)

var iotHubName = '${projectName}Hub${unique}'
var signalrName = '${projectName}signalr${unique}'
var funcPlanName = '${projectName}funcplan${unique}'
var storageName = '${projectName}${unique}'
var funcAppName = '${projectName}funcapp${unique}'
var appServicePlanName = '${projectName}webplan${unique}'
var webSiteName = '${projectName}web${unique}'
var appInightsName = '${projectName}appinsight${unique}'


// create iot hub
resource iot 'microsoft.devices/iotHubs@2020-03-01' = {
  name: iotHubName
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
  }
}

//create storage account (used by the azure function app)
resource storage 'Microsoft.Storage/storageAccounts@2018-02-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: false
  }
}


// create signalr instance
resource signalr 'Microsoft.SignalRService/signalR@2020-07-01-preview' = {
  name: signalrName
  location: location
  sku: {
    name: 'Standard_S1'
    capacity: 1
    tier:  'Standard'
  }
  properties: {
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    features: [
      {
        flag: 'ServiceMode'
        value: 'Serverless'
      }
    ]
  }
}

// create App Plan - "server farm"
resource appserver 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: funcPlanName
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'Dynamic'
    name: 'B1'
  }
}

// create Function app for hosting the IoTHub ingress and SignalR egress
resource funcApp 'Microsoft.Web/sites@2019-08-01' = {
  name: funcAppName
  kind: 'functionapp'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys(storageName, '2019-06-01').keys[0].value}'
        }
        {
          name: 'AzureSignalRConnectionString'
          value: 'Endpoint=https://${signalrName}.service.signalr.net;AccessKey=${listKeys(signalrName, providers('Microsoft.SignalRService', 'SignalR').apiVersions[0]).primaryKey};Version=1.0;'
        }
        {
          name: 'AzureIOTHubConnectionString'
          value: 'Endpoint=${iot.properties.eventHubEndpoints.events.endpoint};SharedAccessKeyName=iothubowner;SharedAccessKey=${listKeys(iot.id, iot.apiVersion).value[0].primaryKey};EntityPath=${iot.name}'
        }        
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }                
      ]
    }
    serverFarmId: appserver.id
    clientAffinityEnabled: false
  }
  dependsOn: [
    storage
    signalr
    appInsights
  ]
}

// Function AppInsights
resource appInsights 'Microsoft.Insights/components@2015-05-01' = {
  name: appInightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// WebApp App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: 'F1'
  }
  kind: 'linux'
}

// WebApp
resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

// Deploy function code from zip
// resource ingestfunction 'Microsoft.Web/sites/extensions@2015-08-01' = {
//   name: '${funcApp.name}/MSDeploy'
//   properties: {
// packageUri: 'https://github.com/adamlash/blade-infra/raw/main/functions/zipfiles/blade-functions.zip'
// dbType: 'None'
//     connectionString: ''
//   }
//   dependsOn: [
//     funcApp
//   ]
// }


output importantInfo object = {
  iotHubName: iotHubName
  signalRNegotiatePath: 'https://${funcApp.name}.azurewebsites.net/api/negotiate'
}
