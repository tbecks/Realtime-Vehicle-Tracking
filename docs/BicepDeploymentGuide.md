# Realtime Vehicle Tracking Solution Deployment Guide with Bicep
This guide can be used to  deploy the solution within your own environment using a Bicep template and the Azure CLI to provision the Infrastructure.

## Prerequisites to deploy the solution
* Azure account with subscription
* Create an Azure Resource Group called **RealtimeVehicleTracking**
* Install Azure CLI

# Part 1: Deploy Infrastructure
The first step is to deploy the Bicep Template, one simple commmand will do the trick. From the root of the repo, browse to ./infrastructure with your CLI and run the following:

`az deployment group create -f azuredeploy.bicep -g RealtimeVehicleTracking --parameters projectName=**YOURPROJECTNAME**`

Please denote two things
- `-g` is the resource group, in this case it was our `RealtimeVehicleTracking`
- `projectName=**YOURPROJECTNAME**` please replace this with your own chosen name


Once this has been deployed, you will see some outputs in the JSON;
- Website URL
- Function App URL 
- IOT Hub Name
save these for later

# Part 2: Create IOT Device
After we have our infra, we can create the device via the CLI:
`az iot hub device-identity create -n **IOTHUBNAME** -d MineVehicle`

Denote...
-  We need to specify our iothub name in `-n **IOTHUBNAME**`
- We specify a device name with `-d MineVehicle`. This is the name of the device in our producer.


# Part 3: Configure Producer
We need to configure our Producer to Link to our IOThub.. 

1. Run command to create a SAS Token: `az iot hub generate-sas-token -n **IOTHUBNAME** --policy iothubowner -d MineVehicle` (once again denote the name of the iothub and device here)
2. open up ./producer/SendVehicleEvents.py and replace the following lines:
```
# Replace the following variables with your information
sas = <REPLACE WITH YOUR SAS TOKEN>
iotHub = <REPLACE WITH YOUR IOTHUB NAME>
```

After this, if you run the python script, you should be able to see messages flow into iothub.


# Part 4: Edit Code
We need to point our js code to look at the functions we are going to build.. To do so open up ./web/index.html.

On line 25, replace the URL with the Function App URL from the outputs you got when you deployed the bicep template: `const baseurl = 'https://yourfunctionhere.azurewebsites.net';`

Save this file.


# Part 5: Deploy Code
- Deploy the ./functions folder to the Function App instance
- Deploy the ./web folder to the Web App instance



# Part 6: Run Producer
Magic! If you run the producer you should see messages get sent to iothub... From iothub they get picked up by the functionapp and passed onto signalr... your web browser on the html site should have opened a connection to signalr, and see various traffic moving!
