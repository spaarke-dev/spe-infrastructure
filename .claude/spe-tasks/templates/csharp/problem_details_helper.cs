using Microsoft.Graph;
using Microsoft.AspNetCore.Http;

namespace api;

public static class ProblemDetailsHelper
{
    public static IResult FromGraphException(ServiceException ex)
    {
        var status = (int?)ex.StatusCode ?? 500;
        var title = status == 403 ? "forbidden" : status == 401 ? "unauthorized" : "error";
        var code = ex.Error?.Code ?? "";
        var detail = (status == 403 && code.Contains("Authorization_RequestDenied", StringComparison.OrdinalIgnoreCase))
            ? "missing graph app role (filestoragecontainer.selected) for the api identity."
            : status == 403 ? "api identity lacks required container-type permission for this operation."
            : ex.Message;

        var requestId = ex.ResponseHeaders != null && ex.ResponseHeaders.TryGetValue("request-id", out var rid) ? rid : null;

        return Results.Problem(
            title: title,
            detail: detail,
            statusCode: status,
            extensions: new Dictionary<string, object?>
            {
                ["graphErrorCode"] = code,
                ["graphRequestId"] = requestId
            });
    }
}
