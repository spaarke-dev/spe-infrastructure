using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Hosting;
using Spe.Bff.Api.Tests.Mocks;
using Spe.TestServer.Infrastructure.Graph;

namespace Spe.Bff.Api.Tests;

public class CustomWebAppFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((ctx, cfg) =>
        {
            var dict = new Dictionary<string,string?>
            {
                ["Cors:AllowedOrigins"] = "https://localhost:5173",
                ["UAMI_CLIENT_ID"] = "test-client-id",
                ["TENANT_ID"] = "test-tenant-id",
                ["API_APP_ID"] = "test-app-id",
                ["API_CLIENT_SECRET"] = "test-secret"
            };
            cfg.AddInMemoryCollection(dict!);
        });

        // optional: DI overrides for tests can be placed here later
        builder.ConfigureServices(services =>
        {
            if (Environment.GetEnvironmentVariable("USE_FAKE_GRAPH") == "1")
            {
                var d = services.SingleOrDefault(s => s.ServiceType == typeof(IGraphClientFactory));
                if (d != null) services.Remove(d);
                services.AddSingleton<IGraphClientFactory, FakeGraphClientFactory>();
            }
        });
    }
}