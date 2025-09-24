using Microsoft.Graph;
using Polly;

namespace infrastructure;

public static class RetryPolicies
{
    public static IAsyncPolicy GraphTransient()
        => Policy.Handle<ServiceException>(ex =>
                (int?)ex.StatusCode is 429 or 503 || ex.InnerException is HttpRequestException)
            .WaitAndRetryAsync(5, attempt => TimeSpan.FromSeconds(Math.Pow(2, attempt)));
}
