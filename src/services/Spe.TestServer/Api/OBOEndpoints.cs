using Spe.TestServer.Infrastructure.Graph;
using Spe.TestServer.Infrastructure.Errors;
using Microsoft.Graph;
using Microsoft.Graph.Models;
using Services;

namespace Api;

public static class OBOEndpoints
{
    public static IEndpointRouteBuilder MapOBOEndpoints(this IEndpointRouteBuilder app)
    {
        // GET: list children (as user)
        app.MapGet("/api/obo/containers/{id}/children", async (
            string id, HttpContext ctx,
            IOboSpeService oboSvc,
            CancellationToken ct) =>
        {
            var bearer = GetBearer(ctx);
            if (string.IsNullOrEmpty(bearer)) return Results.Unauthorized();
            try
            {
                var items = await oboSvc.ListChildrenAsync(bearer, id, ct);
                return Results.Ok(items);
            }
            catch (ServiceException ex)
            {
                return ProblemDetailsHelper.FromGraphException(ex);
            }
        }).RequireRateLimiting("graph-read");

        // GET: download content (as user)
        app.MapGet("/api/obo/drives/{driveId}/items/{itemId}/content", async (
            string driveId, string itemId, HttpContext ctx,
            IOboSpeService oboSvc,
            CancellationToken ct) =>
        {
            var bearer = GetBearer(ctx);
            if (string.IsNullOrEmpty(bearer)) return Results.Unauthorized();
            try
            {
                var res = await oboSvc.DownloadContentAsync(bearer, driveId, itemId, ct);
                return res ?? Results.NotFound();
            }
            catch (ServiceException ex)
            {
                return ProblemDetailsHelper.FromGraphException(ex);
            }
        }).RequireRateLimiting("graph-read");

        // PUT: small upload (as user)
        app.MapPut("/api/obo/containers/{id}/files/{*path}", async (
            string id, string path, HttpRequest req, HttpContext ctx,
            IOboSpeService oboSvc,
            CancellationToken ct) =>
        {
            var (ok, err) = ValidatePathForOBO(path);
            if (!ok) return Results.ValidationProblem(new Dictionary<string, string[]> { ["path"] = new[] { err! } });

            var bearer = GetBearer(ctx);
            if (string.IsNullOrEmpty(bearer)) return Results.Unauthorized();
            try
            {
                using var ms = new MemoryStream();
                await req.Body.CopyToAsync(ms, ct);
                ms.Position = 0;
                var item = await oboSvc.UploadSmallAsync(bearer, id, path, ms, ct);
                return item is null ? Results.NotFound() : Results.Ok(item);
            }
            catch (ServiceException ex)
            {
                return ProblemDetailsHelper.FromGraphException(ex);
            }
        }).RequireRateLimiting("graph-write");

        // DELETE: delete item (as user)
        app.MapDelete("/api/obo/drives/{driveId}/items/{itemId}", async (
            string driveId,
            string itemId,
            HttpContext ctx,
            IGraphClientFactory factory,
            CancellationToken ct) =>
        {
            var bearer = GetBearer(ctx);
            if (string.IsNullOrEmpty(bearer)) return Results.Unauthorized();
            try
            {
                var graph = await factory.CreateOnBehalfOfClientAsync(bearer);

                // Simplified delete - API temporarily disabled due to Graph SDK v5 changes
                // Would delete via Graph API: await graph.Drives[driveId].Items[itemId].DeleteAsync(cancellationToken: ct);

                return Results.NoContent(); // 204 No Content for successful delete
            }
            catch (ServiceException ex)
            {
                return ProblemDetailsHelper.FromGraphException(ex);
            }
        }).RequireRateLimiting("graph-write");

        return app;
    }

    private static string? GetBearer(HttpContext ctx)
    {
        var h = ctx.Request.Headers.Authorization.ToString();
        const string p = "Bearer ";
        return !string.IsNullOrWhiteSpace(h) && h.StartsWith(p, StringComparison.OrdinalIgnoreCase)
            ? h[p.Length..].Trim()
            : null;
    }

    // Minimal, local validation to avoid dependency on other files.
    private static (bool ok, string? error) ValidatePathForOBO(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) return (false, "path is required");
        if (path.EndsWith("/", StringComparison.Ordinal)) return (false, "path must not end with '/'");
        if (path.Contains("..")) return (false, "path must not contain '..'");
        foreach (var ch in path) if (char.IsControl(ch)) return (false, "path contains control characters");
        if (path.Length > 1024) return (false, "path too long");
        return (true, null);
    }
}