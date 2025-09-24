# pr-5 — tests & cleanup (complete instructions)

## PR-5 Files
- Files for this step are found /claude/PR-5 Files
- Use these files to complete the tasks in PR-5

> goal: add integration/unit tests, basic coverage & ci, and ensure no legacy cert-based app-only paths remain. this includes ready-to-apply patches and optional, testability-friendly refactor.

---

## 0) guardrails
- do **not** call live Graph in tests.
- keep behavior/contracts unchanged.
- no secrets in repo or test output.

---

## 1) what you’ll add
- **integration tests** (xunit + webapplicationfactory):
  - `/healthz` → 200
  - `/ping` → 200 with json incl. `traceId`
  - **security headers** present
  - **cors preflight** succeeds for allowed origin
  - **obo endpoints** without bearer → 401 (problem+json)
- **unit tests** for `ProblemDetailsHelper.FromGraphException` 403 mapping
- **coverage** via coverlet; **ci** workflow (github actions)
- **optional**: test-friendly OBO service refactor + fake graph factory for precondition tests

---

## 2) apply the core tests patch
1) create a branch:
```bash
git checkout -b feature/pr5-tests-cleanup
```

2) apply patch:
```bash
git apply pr5_add_tests.patch
```

3) if the Program.cs hunk fails, add this at the **end** of `Program.cs` manually:
```csharp
public partial class Program { }
```

4) add the test project to your solution (if you use a .sln):
```bash
dotnet sln add tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj
```

5) run:
```bash
dotnet build
dotnet test
```

---

## 3) optional: make OBO endpoints easy to fake (recommended)
This keeps your endpoint code small but lets tests fake OBO behavior without touching Graph.

Apply:
```bash
git apply pr5_obo_testable_service.patch
dotnet build
```

This:
- adds `Services/IOboSpeService` and `Services/OboSpeService`
- registers it in DI
- rewires `Api/OBOEndpoints.cs` to call the service (behavior identical)

> In tests, you can now override `IOboSpeService` with a fake that returns fixed data—no Graph calls needed.

Example override (add to `CustomWebAppFactory.ConfigureServices`):
```csharp
services.AddScoped<Services.IOboSpeService>(_ => new FakeOboSpeService());
```

…and provide:
```csharp
public sealed class FakeOboSpeService : Services.IOboSpeService
{
    public Task<IList<Microsoft.Graph.Models.DriveItem>> ListChildrenAsync(string _, string __, CancellationToken ___)
        => Task.FromResult<IList<Microsoft.Graph.Models.DriveItem>>(new List<Microsoft.Graph.Models.DriveItem>());
    public Task<IResult?> DownloadContentAsync(string _, string __, string ___, CancellationToken ____)
        => Task.FromResult<IResult?>(Results.File(new MemoryStream(new byte[]{1,2,3}), "application/octet-stream"));
    public Task<Microsoft.Graph.Models.DriveItem?> UploadSmallAsync(string _, string __, string ___, Stream ____, CancellationToken _____)
        => Task.FromResult<Microsoft.Graph.Models.DriveItem?>(new Microsoft.Graph.Models.DriveItem { Name = "hello.txt" });
}
```

---

## 4) optional: fake graph client factory (lightweight)
If you only need to assert **preconditions** (e.g., 401) and guarantee no outbound auth, you can swap in a minimal fake factory.

Apply:
```bash
git apply pr5_fake_graph_factory.patch
```

Enable during tests:
```bash
# before running tests
export USE_FAKE_GRAPH=1
dotnet test
```

> Note: this fake does **not** emulate Graph APIs; it only prevents real tokens and gives you a safe placeholder client. Prefer the **OBO service refactor** for true happy-path tests.

---

## 5) add CI (github actions)
Create `.github/workflows/dotnet.yml` with:
```yaml
<copy from this doc>
```

Push a PR and validate the workflow runs:
- Build ok
- Tests pass
- Coverage ≥ threshold (defaults to 60%)

---

## 6) cleanup checklist
- No cert-based app-only path remains (MI is the only app-only flow).
- OBO confidential client is used **only** for OBO.
- No tokens/claims logged in tests or app logs.
- README/docs updated: how to run tests and local env pre-reqs.

---

## 7) acceptance criteria (merge gate)
- `dotnet test` passes locally and in CI.
- Headers & CORS tests succeed.
- OBO unauthenticated → 401 problem+json.
- ProblemDetails helper tests differentiate 403 causes.
- Coverage meets threshold (or agreed baseline).
- Optional refactor compiles and leaves runtime behavior unchanged.

---

## 8) prompt for claude code

> **Execute PR-5 exactly as described in `pr-5 — tests & cleanup (complete instructions)`**.  
> Steps:  
> 1) Apply `pr5_add_tests.patch`. If the `Program.cs` hunk fails, add `public partial class Program { }` at the end manually.  
> 2) Add the test project to the solution and run tests.  
> 3) Add `.github/workflows/dotnet.yml` from this doc.  
> 4) (Optional) Apply `pr5_obo_testable_service.patch` and re-run tests.  
> 5) (Optional) Apply `pr5_fake_graph_factory.patch`; run tests with `USE_FAKE_GRAPH=1`.  
> Return a compiling patch and passing test output; confirm no legacy cert-based app-only code paths remain.
