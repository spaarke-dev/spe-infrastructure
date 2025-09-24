using api;
using infrastructure.graph;
using infrastructure;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IGraphClientFactory, GraphClientFactory>();
builder.Services.AddScoped<ISpeService, SpeService>();

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("graph-write", o =>
    {
        o.Window = TimeSpan.FromSeconds(1);
        o.PermitLimit = 10;
        o.QueueLimit = 0;
    });
});

builder.Services.AddEndpointsApiExplorer();

var app = WebApplication.Create();

app.UseRateLimiter();

app.MapGet("/ping", (HttpContext ctx) =>
{
    return Results.Ok(new { ok = true, traceId = ctx.TraceIdentifier });
});

app.MapPost("/api/containers", async (ISpeService spe, Guid containerTypeId, string name, string? description) =>
{
    try
    {
        var created = await RetryPolicies.GraphTransient()
            .ExecuteAsync(() => spe.CreateContainerAsync(containerTypeId, name, description));
        return Results.Created($"/api/containers/{created?.Id}", created);
    }
    catch (Microsoft.Graph.ServiceException ex)
    {
        return ProblemDetailsHelper.FromGraphException(ex);
    }
}).RequireRateLimiting("graph-write");

app.Run();
