using Microsoft.Graph.Models;

namespace Services;

public interface IOboSpeService
{
    Task<IList<DriveItem>> ListChildrenAsync(string userBearer, string containerId, CancellationToken ct);
    Task<IResult?> DownloadContentAsync(string userBearer, string driveId, string itemId, CancellationToken ct);
    Task<DriveItem?> UploadSmallAsync(string userBearer, string containerId, string path, Stream content, CancellationToken ct);
}