# Realtime Vehicle Tracking Solution Deployment Guide
This guide can be used to manually deploy the solution within your own environment.

<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Realtime%20Vehicle%20Tracking%20Lab%20Architecture.png>

1. [Prerequisites to deploy the solution](#prerequisites-to-deploy-the-solution)
2. [Part 1: Data Ingestion)(#part-1:-data-ingestion)

## Prerequisites to deploy the solution
The following will be required to complete the full deployment for the solution:
* [Azure account](https://account.microsoft.com/account/) with [subscription](https://azure.microsoft.com/en-ca/free/)
* [Create an Azure Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups) called **RealtimeVehicleTracking** which will be used to deploy the solution into
* [Install VS Code](https://code.visualstudio.com/download) and [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Download the Github Solution Source Code](https://github.com/tbecks/Realtime-Vehicle-Tracking/archive/refs/heads/main.zip)

---
# Part 1: Data Ingestion
The first step is to get the data ingested into our solution.  IoT Hub is the landing service used to receive events from the field and enable downstream events to subscribe and recive those events.  An event is purely a package of data, in our case represented by the vehicle id and its location.



## IoT Hub Configuration
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Logo-IoTHub.jpg width=75>

### Create a new IoT Hub Service
[Azure IoT Hub](https://docs.microsoft.com/en-us/azure/iot-hub/) is a cloud hosted service that acts as a central cloud based message hub for receiving telemetry events from field devices.  Downstream consumers will connect to IoT Hub to subscribe to the event stream for additional processing, alerting or analytics use cases.  In our use case simulated vehicle events will stream to Azure through an IoT Hub.

1. Login to the [Azure portal](https://portal.azure.com) using your Azure AAD login.
2. From the upper left corner select **Create a resource**

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzurePortal-1.png width=600>

3. Create a simple B1: Basic Tier IoT Hub, with a Public endpoint and a unique name:

  |Name             |Value|
  |---              |---|
  |Subscription     |Select the subscription to deploy the solution in
  |Resource Group   |Create a new Resource Group called **RealtimeVehicleTracking**
  |IoT Hub Name     |Create a globally unique name ie. *VehicleTrackingIoT*
  |Region           |Choose a region that you will deploy all your services to
  |Pricing and Scale Tier |B1 Basic


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub.png width=600>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub2.png width=600>
  

4. Once the IoT Hub is provisioned, click on **IoT Devices** to go in and create a new device, within the IoT Hub, used for data capture:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub3-Devices.png width=200>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub3-NewDevice.png width=600>
  
  
5. Create a device called **MineVehicle**:
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub4-CreateDevice.png width=400>
  
6. Click Refresh to see the newly created device.  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub5-Device.png width=600>

<BR>This device will be the intended recipient of the vehicle telemetry events.  Even though our payload will be sending events from multiple vehicles, we can have a single device configured in IoT Hub to act as the recipient device.  The next step will be to get a SAS token that the data producer will use to connect to the IoT Hub and send events.

  
7. Create Consumer Groups: **asa** and **cli**

Consumer Groups are a state views of the hub.  They enable multiple consuming applications to each have their own view of the event stream and read the stream independently.  This means when an application stops reading from an event stream, it can continue from where it left off.  It is best practice for each subscriber application to have its own consumer group defined.

To create a consumer group open the IoT Hub, under Hub Settings > Built-in endpoints, you will see Consumer Groups with the $Default group created.  Add two more consumer groups, one for potential Stream Analytics integration, and another for our command line interace (CLI) applications to connect to:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IotHub-ConsumerGroup.png width=300>

### Generate IoT Hub SAS Token
A Shared Access Signature (SAS) token will be required to enable our event generator to send events to the IoT Hub.  The SAS token can be generated by one of the following ways:

1. VS Code using the [Azure IoT Hub Extension](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-toolkit)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/iot/hub?view=azure-cli-latest#az_iot_hub_generate_sas_token)

For this lab we will walk through the Azure CLI method.  Start by opening up a command prompt and running `az login`

Once logged in, generate the token by running: `az iot hub generate-sas-token -d {device_id} -n {iothub_name} -r {resource_group_name} -d {duration in seconds}`

The duration for the token is set in seconds, therefore to set the SAS token to be valid for a year run the following: `az iot hub generate-sas-token -d MineVehicle -n VehicleTrackingIoT -g RealtimeVehicleTracking  --duration 31536000`

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub7-SASToken.png width=600>

You will need to use the returned SAS token and update the Python based producer in the next steps.

## Setup Python Vehicle Data Producer
<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Logo-Python.png width=75>

To simulate vehicle telemetry events being sent to IoT Hub, we will use a Python script to send telemetry data that has been stored in a CSV data file.  The data file is located in the data folder of this repo, and will be referenced by the Python script. The data in the event consists of asset (vehicle) information and asset location.

|EquipmentID|Latitude|Longitude|
|---|---|---|


### Update the Python Producer with your environment information
Open the **SendVehicleEvents.py** file in VS Code (or any text editor).  This file can be found in the **/src** folder.

In the file look for the section below `# Replace the following variables with your information`.  You will need to update the following variables:
- `sas`
- `iotHub`
- `deviceId`

### Test the Producer
We now want to test that we can successfully send data from our Python data producer to our IoT Hub.  This will validate that the producer is properly configured and the solution is receiving data in Azure.  The easiest way to verify that data is arriving on the IoT Hub is to use the Azure CLI commands:

1. Open a command promp (can be run by typing cmd in the Start menu)
2. Type `az login` and login to your Azure account (you will need to have [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli) for this to work)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-Producer-1.png width=300>


3. Once logged in run the following command to start monitoring your IoT Hub device for events:
    **az iot hub monitor-events -n {iothub_name} -d {device_id} -g {resource_group} --cg {consumer_group_name}**
    
    For example: `az iot hub monitor-events -n VehicleTrackingIoT -d MineVehicle -g RealtimeVehicleTracking --cg cli`
    
4. You should now see the CLI waiting for events to arrive.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-Producer-2.png width=300>

5. Go back into VS Code and select **Terminal > New Terminal** to open the terminal window in VS Code.  
6. Run `cd producer` from the terminal prompt to go into the folder with the python producer, then run `py SendVehicleEvents.py` to run the producer.  You should see the producer connect to IoT Hub and events start to stream:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-Producer-4.png width=600>

7. Go back to the Command Prompt window that was running the iot hub monitor events and you should start to see events streaming from IoT Hub to your cli window:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-Producer-5.png width=600>

This validates that we can subscribe to our IoT Hub and subscribe to the event stream.  Next step is consuming and visualizing that stream.



---
# Part 2: Data Processing
## SignalR Configuration
<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Logo-SignalR.png width=75>

[Azure SignalR Service](https://docs.microsoft.com/en-us/azure/azure-signalr/signalr-overview) simplifies the process of adding real-time web functionality to applications over HTTP web connections. This real-time functionality allows the service to push content updates to connected clients, such as a single page web or mobile application. Clients are updated without having to poll the server for new data.  For our solution SignalR will be used to push events to our Azure Maps web interface, however, there are many other destinations and use cases which this pattern supports.

1. Create a new SignalR service from the Azure Portal.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-SignalR-1.png width=600>

2. Once provisioned go in to the overview of you SignalR service and make note of the *connection string* as we will need to use this later on. 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-SignalR-2.png width=600>

Note: Keep the default Public endpoint for this lab. 

---
# Part 3: Data Visualization
## Azure Maps Deployment
  
[Azure Maps](https://docs.microsoft.com/en-ca/azure/azure-maps/) is a collection of geospatial services and SDKs that use fresh mapping data to provide geographic context to web and mobile applications.  Azure Maps has a rich set of REST APIs to render map based information.  In this solution, Azure Maps will be used to render the data over satelite imagery.  
  
<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Logo-AzureMaps.png width=75>

1. Create a new Azure Maps Service:
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureMaps-1.png width=600>

2. Once deployed make note of the Key.  This will be used when we configure the Azure Functions:
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureMaps-2.png width=600>

## Azure Functions Configuration
<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Logo-AzureFunctions.png width=75>
Azure Functions will be used to pull data from IoT Hub, negotiate a connection with the front end application server and push the events to SignalR which will push the data over a web socket on the web appliation.

There are two functions as part of the solution that we will be deploying:

- *messages* - Request new events from IoT Hub 
- *negotiate* - Negotiates a SignalR Connection to the Web App 

1. Start by deploying an Azure Function instance in Azure:
  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-0.png width=200>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-1.png width=600>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-2.png width=600>

Note: There is no requirement to have Application Insight Enabled.

2. Once the Function App service is provisioned, we need to deploy the provided code to the Azure Function service to create the new functions.  Ensure that you have downloaded the solution source code from GitHub and open with VS Code.  

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-3.png width=600>

  
***** Ensure prerequisit has downloading the code locally. and opening with VS Code.
FIX THIS:
- log into azure, go into azure function > configuration and add the following settings:
- `AzureWebJobsStorage` 
- `FUNCTIONS_WORKER_RUNTIME`
- `AzureIOTHubConnectionString`
- `AzureSignalRConnectionString`

*Note: Bicep template will create the functions and configuration*
- ADD SCREEN SHOT 

These settings can also be found in the `local.settings.json` file with your environment values:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-4.png width=600>

  |Configuration Parameter|Where to Get Value|
  |---|---|
  |AzureWebJobsStorage|(insert link)|
  |AzureIOTHubConnectionString|(insert link)|
  |AzureSignalRConnectionString|(insert link)|
  
`Build` and `Deploy` the project to the Azure Functions service.  From the VS Code terminal window run `dotnet build` (or right click the project file and select **Build .NET Core project**).  Once build deploy the solution in VS Code by running the following commands:

- Open the Command Pallette (Ctl-Shift-P)
- Type `Azure Functions: Deploy to function app`
- Walk through the prompts to deploy to the Azure Functions service you deployed previously

Ensure the funciton successfully deploys.

## Azure App Service
The App Service will provide the web based front end.  Create a App Service instance in the Azure Portal:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AppService-1.png width=600>

The name needs to be unique and will form your sites URL.  Select PHP as the runtime stack as we are using a simple HTML page with Javascript.  Make note of the App Service URL, this will be used to access the web front end from a browser.

Open VS Code and ensure you have the Azure App Service extension installed:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AppService-3.png width=600>

Then Open the Azure blade and navigate to the Azure App Service section to deploy the web source code to the App Service in Azure:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AppService-2.png width=600>

This will open the command pallet at the top, follow the steps to choose which folder to deploy to your App Service:
- Navigate to the web folder of the solution repo
- settings:
-   configure > web sockets on?

# Part 5: Running the Solution #
- open map
- start producer
- watch vehicles move around
-

# Part 4: Extended Use Cases #
## Data Lake Historical Data Capture #
To persist data long term for the purposes of analytics:
- create a new Data Lake Storage Account
- create a route in IoT Hub to send data to the Data Lake Container
- create a new Default route (this is critical as creating a custom route will shut off the existing default route so you will need to explicitly create a new one

## Data Transformation with Azure Stream Analytics #
- using ASA jobs to transform daa

## Data Transformation with Databricks Spark Streaming Job #
- using a spark streaming job to process and persist data 

## Visualize Data with Power BI #
- using Power BI to visualize data
