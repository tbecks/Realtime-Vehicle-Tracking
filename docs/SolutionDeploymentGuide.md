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
  |Pricing and Scale Tier |Basic


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
3. Using [IoT Explorer](https://github.com/Azure/azure-iot-explorer/releases).

For this lab we will walk through the Azure CLI method.  Start by opening up a command prompt and running `az login`

Once logged in, generate the token by running: `az iot hub generate-sas-token -d {device_id} -n {iothub_name} -r {resource_group_name} -d {duration in seconds}`

The duration for the token is set in seconds, therefore to set the SAS token to be valid for a year run the following: `az iot hub generate-sas-token -d MineVehicle -n VehicleTrackingIoT -g RealtimeVehicleTracking  --duration 31536000`

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-IoTHub7-SASToken.png width=600>

You will need to use the returned SAS token and update the Python based producer in the next steps.  Copy the results within the double quotes which start with `SharedAccessSignature sr=`

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

<img src=./img/Deploy-Producer-Setup.png width=300>

Optionally you can also change the source of your data, for this lab we will use the existing `AllVehicles.csv` source file.

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
<img src=./img/Logo-SignalR.png width=75>

[Azure SignalR Service](https://docs.microsoft.com/en-us/azure/azure-signalr/signalr-overview) simplifies the process of adding real-time web functionality to applications over HTTP web connections. This real-time functionality allows the service to push content updates to connected clients, such as a single page web or mobile application. Clients are updated without having to poll the server for new data.  For our solution SignalR will be used to push events to our Azure Maps web interface, however, there are many other destinations and use cases which this pattern supports.

1. Create a new SignalR service from the Azure Portal.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-SignalR-1.png width=600>

Note: Ensure you update the pricing and service mode settings.

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

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-1.png width=600>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-1b.png width=600>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-2.png width=600>

Note: There is no requirement to have Application Insight Enabled.

2. Once the Function App service is provisioned, we need to deploy the provided code to the Azure Function service to create the new functions.  Ensure that you have downloaded the solution source code from GitHub and open with VS Code. 


&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-3.png width=300>

- In the Azure portal navigate to your Azure Function App to configure some key settings:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-2b.png width=600>

The following settings need to be defined in the Function App Configuration section:
- `AzureIOTHubConnectionString`
- `AzureSignalRConnectionString`

*Note: Bicep template will create the functions and configuration*

These settings can also be found in the `local.settings.json` file with your environment values:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AzureFunction-4.png width=600>

  |Configuration Parameter|Where to Get Value|
  |---|---|
  |AzureIOTHubConnectionString|IoT Hub > Built-in Endpoints > Event Hub-compatible endpoint
|
  |AzureSignalRConnectionString|SignalR > Connection Strings > For Access Key - Connection String|

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-7.png width=600>

### Deploy Function Code
We will deploy the funciton code from Visual Studio Code.  

Start by opening VS Code and logging into Azure:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-8.png width=200>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-9.png width=200>

**Optional:** `Build` and `Deploy` the project to the Azure Functions service.  From the VS Code terminal window run `dotnet build` (or right click the project file and select **Build .NET Core project**).  

Deploy the solution in VS Code by running the following commands in VS Code:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-10.png width=600>

- Open the Command Pallette (Ctl-Shift-P)
- Type `Azure Functions: Deploy to function app`
- Walk through the prompts to deploy to the Azure Functions service 

Note: If you are prompted click on `Update and Deploy`

Ensure the funciton successfully deploys.  You should see the following message after the deployment is complete:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-11.png width=300>

You can confirm the functions are deployed by navigating to the Azure Function App in the Azure Portal and selecting **Functions** from the left menu.  You should see the two functions deployed:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AzureFunction-12.png width=300>

## Azure Web App
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-0.png width=80>

The App Service will provide the web based front end to the solution.  It provides a web socket connection to the SignalR service to receive events from the Azure Functions service.  The web app is a simple HTML page with Javascript to render the map and vehicle locations.

Create a App Service instance in the Azure Portal:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-1.png width=600>

The name needs to be unique and will form your sites URL.  Select PHP as the runtime stack as we are using a simple HTML page with Javascript.  Make note of the App Service URL, this will be used to access the web front end from a browser.

### Deploy Web App Code

You should now have all the required services deployed in Azure:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-1b.png width=600>

#### Azure Function CORS Configuration

In order to allow the Azure Maps Service to communicate with the Azure Functions, you will need to make a configurtion change to the Azure Functions service.  

Navigate to the Azure Functions service in the Azure Portal and select **Platform Features > CORS** from the left menu.  Add the following URL to the list of allowed origins:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-1c.png width=600>

In our case we will add `https://realtimevehicles.azurewebsites.net` to the allowed origins list.  Click `Save` to save the changes.


#### Modify Web App Code
Open VS Code and ensure you have the Azure App Service extension installed:
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Deploy-AppService-3.png width=600>

In VS Code go into the "Explorer" blade to navigate the code base.  In the "Web" folder click the "Index.html" file. Replace the following values:

- baseurl (the url of your Azure Function App)
- subscriptionKey (the key to your Azure Maps service)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-3a.png width=600>

In addition, update the references to the web URL in the same index.html file:

For Images:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-3b.png width=600>

For Features:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-3c.png width=600>

#### Deploy Web App
Now we can deploy the web app code to the App Service.  

Open the Azure blade and navigate to the Azure App Service section.  Open App Services and right click on the App Service you created.  Select **Deploy to Web App**:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-3d.png width=500>


This will open the command pallet at the top, select `Browse` and follow the steps to choose which folder to deploy to your App Service:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-4.png width=500>

- Navigate to the web folder of the solution repo

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-5.png width=500>

Once the deployment is complete you should see the following message:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-6.png width=300>

You can now go to the URL of the Web App and test the solution (the URL will be unique for your deployment).  For now you will see a blank map zoomed in on a mine site: [https://realtimevehicles.azurewebsites.net/](https://realtimevehicles.azurewebsites.net/)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-7.png width=600>


# Part 5: Running the Solution #
To start the solution open the map in a browser: [https://realtimevehicles.azurewebsites.net/](https://realtimevehicles.azurewebsites.net/)

With the map open start the python based data producer.  This can be done through VS Code directly, or through a command prompt.  To run the producer through a command prompt:
- Open a command prompt in the producer folder: `.\Realtime-Vehicle-Tracking\producer\`
- In this folder is the python script to send events to IoT Hub: `py SendVehicleEvents.py`
- Run the producer by typing `py SendVehicleEvents.py`
- You will start to see streaming events being sent to IoT Hub:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-8.png width=600>

- Go back to the web browser and you should start to see the vehicles appear and move around the map based on the telemetry from the datafile:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-9.png width=600>

### Debugging the solution
In the event you would like to see the events being sent to the browser through the web socket, you can open the browsers development view and see events realtime in the browser.  To do this press `F12` in the browser to open the `developer tools`.  Select the **Console** tab and you will see the events being sent to the browser:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<img src=./img/Deploy-AppService-10.png width=600>


# Part 4: Extended Use Cases #
## Operational Data Capture: Integration with Cosmos DB for PostgreSQL #
Data can be persisted for for the purposes of operational reporting and analytics.  This enables near realtime analysis, reporting and alerting on the data.  In this use case we will use Cosmos DB for PostgreSQL to persist the data.

## Historical Data Capture: Integration with Lakehouse #
To persist data long term for the purposes of analytics:
- create a new Data Lake Storage Account
- create a route in IoT Hub to send data to the Data Lake Container
- create a new Default route (this is critical as creating a custom route will shut off the existing default route so you will need to explicitly create a new one

## Streaming Data Transformation with Azure Stream Analytics #
- using ASA jobs to transform daa

## Data Transformation with Databricks Spark Streaming Job #
- using a spark streaming job to process and persist data 

## Visualize Data with Power BI #
- using Power BI to visualize data
