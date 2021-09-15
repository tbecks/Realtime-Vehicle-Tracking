using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.SignalRService;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace VehicleDataFunctionApp
{
    public static class SignalRNegociate
    {
        [FunctionName("SignalRNegociate")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function)] HttpRequest req,
            [SignalRConnectionInfo(HubName = "diggerdata")] SignalRConnectionInfo connectionInfo,
            ILogger log)
        {
            return new OkObjectResult(connectionInfo);
        }
    }
}