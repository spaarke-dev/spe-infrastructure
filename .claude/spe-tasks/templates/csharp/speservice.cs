using Microsoft.Graph;
using Microsoft.Graph.Models;

namespace infrastructure.graph;

public interface ISpeService
{
    Task<FileStorageContainer?> CreateContainerAsync(Guid containerTypeId, string name, string? description);
    Task<Drive?> GetContainerDriveAsync(string containerId);
    Task<DriveItem?> UploadSmallAsync(string containerId, string path, Stream content);
}

public sealed class SpeService : ISpeService
{
    private readonly IGraphClientFactory _factory;

    public SpeService(IGraphClientFactory factory) => _factory = factory;

    public async Task<FileStorageContainer?> CreateContainerAsync(Guid containerTypeId, string name, string? description)
    {
        var graph = _factory.CreateAppOnlyClient();
        var container = new FileStorageContainer
        {
            DisplayName = name,
            Description = description,
            ContainerTypeId = containerTypeId
        };
        return await graph.Storage.FileStorage.Containers.PostAsync(container);
    }

    public async Task<Drive?> GetContainerDriveAsync(string containerId)
    {
        var graph = _factory.CreateAppOnlyClient();
        return await graph.Storage.FileStorage.Containers[containerId].Drive.GetAsync();
    }

    public async Task<DriveItem?> UploadSmallAsync(string containerId, string path, Stream content)
    {
        var graph = _factory.CreateAppOnlyClient();
        return await graph.Storage.FileStorage.Containers[containerId].Drive.Root.ItemWithPath(path).Content.PutAsync(content);
    }
}
