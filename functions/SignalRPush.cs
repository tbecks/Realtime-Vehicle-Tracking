using IoTHubTrigger = Microsoft.Azure.WebJobs.EventHubTriggerAttribute;

using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;
using Microsoft.Azure.EventHubs;
using System.Threading.Tasks;
using System.Text;
using System.Net.Http;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;

namespace SignalR
{
    public static class Functions
    {
        private static HttpClient client = new HttpClient();

        [FunctionName("messages")]
        public static async Task RunAsync(
            [IoTHubTrigger(
                "messages/events", 
                Connection = "AzureIOTHubConnectionString")]EventData message, 
            [SignalR(HubName = "maphub")] IAsyncCollector<SignalRMessage> signalRMessages,
            ILogger log)
        {
            log.LogInformation($"C# IoT Hub trigger function processed a message: {Encoding.UTF8.GetString(message.Body.Array)}");
            await signalRMessages.AddAsync(new SignalRMessage
                {
                    Target = "newVehicleData",
                    Arguments = new[] {Encoding.UTF8.GetString(message.Body.Array)}
                });
        }


        [FunctionName("negotiate")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Anonymous)] HttpRequest req,
            [SignalRConnectionInfo(HubName = "maphub")] SignalRConnectionInfo connectionInfo,
            ILogger log)
        {
            return new OkObjectResult(connectionInfo);
        }
    }
}