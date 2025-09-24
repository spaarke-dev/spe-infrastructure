using Azure.Identity;
using Microsoft.Graph;
using Microsoft.Identity.Client;
using Microsoft.Kiota.Abstractions.Authentication;

namespace infrastructure.graph;

public interface IGraphClientFactory
{
    GraphServiceClient CreateAppOnlyClient();
    Task<GraphServiceClient> CreateOnBehalfOfClientAsync(string userAccessToken);
}

public sealed class GraphClientFactory : IGraphClientFactory
{
    private readonly string _uamiClientId;
    private readonly IConfidentialClientApplication _cca;

    public GraphClientFactory(IConfiguration cfg)
    {
        _uamiClientId = cfg["uami_client_id"] ?? throw new InvalidOperationException("uami_client_id not set");
        var tenantId = cfg["tenant_id"] ?? throw new InvalidOperationException("tenant_id not set");
        var apiAppId = cfg["api_app_id"] ?? throw new InvalidOperationException("api_app_id not set");
        var clientSecret = cfg["api_client_secret"]; // optional if no OBO endpoints yet

        var builder = ConfidentialClientApplicationBuilder
            .Create(apiAppId)
            .WithAuthority($"https://login.microsoftonline.com/{tenantId}");

        if (!string.IsNullOrWhiteSpace(clientSecret))
            builder = builder.WithClientSecret(clientSecret);

        _cca = builder.Build();
    }

    public GraphServiceClient CreateAppOnlyClient()
    {
        var cred = new DefaultAzureCredential(new DefaultAzureCredentialOptions {
            ManagedIdentityClientId = _uamiClientId
        });
        var auth = new TokenCredentialAuthenticationProvider(cred, new[] { "https://graph.microsoft.com/.default" });
        return new GraphServiceClient(auth);
    }

    public async Task<GraphServiceClient> CreateOnBehalfOfClientAsync(string userAccessToken)
    {
        var result = await _cca.AcquireTokenOnBehalfOf(
            new[] { "https://graph.microsoft.com/.default" },
            new UserAssertion(userAccessToken)).ExecuteAsync();

        return new GraphServiceClient(new DelegateAuthenticationProvider(req =>
        {
            req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", result.AccessToken);
            return Task.CompletedTask;
        }));
    }
}
