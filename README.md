# Realtime Vehicle Tracking

This solution is intended to simulate a vechicle tracking solution in real-time over a web based mapping applications.  Vehicle data consists of GPS coordinate data that is streamed into Azure and presented on a web application using Azure Maps. This pattern can be used for any streaming data you would like to visualize on web based map.


<img src=./docs/img/Realtime-Vehicle-Tracking.gif width=600>

The solution will use the following services:
* Local Python script - to publish tracking coordinates
* Data files with vehicle tracking data
* IoT Hub
* Azure Functions
* SignalR
* App Service
* Azure Maps
* Power BI

<img src=https://github.com/tbecks/Realtime-Vehicle-Tracking/blob/main/docs/img/Realtime%20Vehicle%20Tracking%20Lab%20Architecture.png>

Use the [Solution Deployment Guide](https://github.com/tbecks/Realtime-Vehicle-Tracking/edit/main/docs/SolutionDeploymentGuide.md) to walk through the steps to deploy the Realtime Vehicle Tracking solution in your own environment.

Alternatively.. the [Bicep Deployment Guide](https://github.com/tbecks/Realtime-Vehicle-Tracking/edit/main/docs/BicepDeploymentGuide.md) uses Bicep and Azure CLI to spin up the Infrastructure and Configure the app accordingly.

Franck Mercier has a great [blog post](https://github.com/franmer2/Logistic_Demo_FY24---Generic/blob/main/docs/Instructions_En.md) that walks through the same pattern using public transit scenarios.
