# Realtime Vehicle Tracking Solution Deployment Guide
This guide can be used to manually deploy the solution within your own environment.

1. [Prerequisites to deploy the solution](#prerequisites-to-deploy-the-solution)
2. Setup IoT Hub for Data Publishing

## Prerequisites to deploy the solution
* Azure account with subscription
* Create an Azure Resource Group called **RealtimeVehicleTracking**
* Install VS Code or Azure CLI

## IoT Hub Configuration
### Setup IoT Hub for Data Publishing
The first step is to setup the IoT Hub to receive messages from the vehicles. Create a simple B1: Basic Tier IoT Hub, with a Public endpoint and a unique name.

<screen shot2>
  
Once the IoT Hub is provisioned, go in and create a new device for data capture:
  
<screen shot3>
  
Create a device called **MineVehicle**:
  
<screen shot4>
  
Click Refresh to see the newly created device.  

<screen shot 5>

This device will be the intended recipient of the vehicle telemetry events.  Even though our payload will be sending events from multiple vehicles, we can have a single device configured in IoT Hub to act as the recipient device.  The next step will be to get a SAS token that the data producer will use to connect to the IoT Hub and send events.

### Generate IoT Hub SAS Token
A Shared Access Signature (SAS) token will be required to enable our event generator to send events to the IoT Hub.  The SAS token can be generated by one of the following ways:

1. VS Code using the [Azure IoT Hub Extension](https://marketplace.visualstudio.com/items?itemName=vsciot-vscode.azure-iot-toolkit)
2. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/iot/hub?view=azure-cli-latest#az_iot_hub_generate_sas_token)

For this lab we will walk through the Azure CLI method.  Start by opening up a command prompt and running **az login**

Once logged in, generate the token by running: **az iot hub generate-sas-token -d {device_id} -n {iothub_name}**

<screen shot 7>

## Setup Python Vehicle Data Producer
To simulate vehicle telemetry being sent to 