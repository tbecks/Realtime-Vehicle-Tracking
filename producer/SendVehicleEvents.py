import csv
import requests
import time

# Replace the following variables with your information
sas = 'SharedAccessSignature sr=VehicleTrackingIoT.azure-devices.net%2Fdevices%2FMineVehicle&sig=qopZ6FVlHeFoHm%2F7wLMWSWfZqL8yrvuUNTtKxl%2FqQWM%3D&se=1635154402'
#sas = <REPLACE WITH YOUR SAS TOKEN>
iotHub = 'VehicleTrackingIoT'
deviceId = 'MineVehicle'


api = '2018-06-30'
restUri = "https://"+iotHub+".azure-devices.net/devices/"+deviceId+"/messages/events?api-version="+api
count = 0
with open('../data/AllVehicles.csv') as f:
    reader = csv.reader(f)
    next(reader, None)
    for row in reader:
        count = count + 1
        payload = {"EquipmentID" : row[4], "Longtitude": row[3], "Latitude": row[2], "VehicleType": row[1], "RowKey" : count}
        r = requests.post(restUri, json=payload, headers = {'Authorization':sas})
        print(payload)
        time.sleep(0.8)
