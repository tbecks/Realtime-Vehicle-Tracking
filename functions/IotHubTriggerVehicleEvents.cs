using IoTHubTrigger = Microsoft.Azure.WebJobs.EventHubTriggerAttribute;

using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.EventHubs;
using System.Text;
using System.Net.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;

namespace Company.Function
{
    public static class IotHubTriggerVehicleEvents
    {
        private static HttpClient client = new HttpClient();
        [FunctionName("VehicleHubPush")]
        public static async Task RunAsync(
            [IoTHubTrigger(
                "messages/events", 
                Connection = "AzureIOTHubConnectionString")]EventData message, 
            [SignalR(HubName = "vehicletracking")] IAsyncCollector<SignalRMessage> signalRMessages,
            ILogger log)
        {
            log.LogInformation($"C# IoT Hub trigger function processed a message: {Encoding.UTF8.GetString(message.Body.Array)}");
            await signalRMessages.AddAsync(new SignalRMessage
                {
                    Target = "newVehicleData",
                    Arguments = new[] {Encoding.UTF8.GetString(message.Body.Array)}
                });
        }
    }
}