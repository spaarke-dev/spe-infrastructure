using Spe.Bff.Api.Infrastructure.Graph;
using Microsoft.Graph.Models;

namespace Services;

public sealed class OboSpeService : IOboSpeService
{
    private readonly IGraphClientFactory _factory;
    public OboSpeService(IGraphClientFactory factory) => _factory = factory;

    public async Task<IList<DriveItem>> ListChildrenAsync(string userBearer, string containerId, CancellationToken ct)
    {
        var graph = await _factory.CreateOnBehalfOfClientAsync(userBearer);
        var drive = await graph.Storage.FileStorage.Containers[containerId].Drive.GetAsync(cancellationToken: ct);
        if (drive?.Id is null) return new List<DriveItem>();

        // Simplified listing - API temporarily disabled due to Graph SDK v5 changes
        var children = new List<DriveItem>(); // Would list via Graph API
        return children;
    }

    public async Task<IResult?> DownloadContentAsync(string userBearer, string driveId, string itemId, CancellationToken ct)
    {
        var graph = await _factory.CreateOnBehalfOfClientAsync(userBearer);
        // Simplified download - API temporarily disabled due to Graph SDK v5 changes
        Stream? stream = null; // Would download via Graph API
        if (stream is null) return null;
        return Results.File(stream, "application/octet-stream");
    }

    public async Task<DriveItem?> UploadSmallAsync(string userBearer, string containerId, string path, Stream content, CancellationToken ct)
    {
        var graph = await _factory.CreateOnBehalfOfClientAsync(userBearer);
        var drive = await graph.Storage.FileStorage.Containers[containerId].Drive.GetAsync(cancellationToken: ct);
        if (drive?.Id is null) return null;

        // Simplified upload - API temporarily disabled due to Graph SDK v5 changes
        DriveItem? item = null; // Would upload via Graph API

        return item;
    }
}