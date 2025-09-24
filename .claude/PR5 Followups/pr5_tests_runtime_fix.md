# pr-5 follow-up — unblock test runtime & simplify ci (optional)

This addresses your **Azure.Core dependency resolution** issue and clarifies whether you need GitHub CI at all.

---

## part 1 — unblock test runtime

### why this happens
- The test host spins up your API via `WebApplicationFactory<Program>`.  
- If the **test project** carries its own transitive `Azure.Core` or lacks the app’s exact versions, the runtime can load **mismatched** assemblies → `FileLoadException` or type load errors.

### fix steps (do all 3)

1) **Add a ProjectReference** from tests → API so NuGet resolves identically.
2) **Copy local lock file assemblies** from the app closure into the test output.
3) **(Optional but recommended)**: use Central Package Management to pin `Azure.Core`, `Azure.Identity`, Graph/ Kiota versions solution-wide.

---

### ready-to-apply patch — test csproj

> Save as `pr5_tests_runtime_fix.patch` and run:
> ```
> git checkout -b fix/tests-runtime
> git apply pr5_tests_runtime_fix.patch
> dotnet clean && dotnet restore --force-evaluate
> dotnet test
> ```

```diff
diff --git a/tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj b/tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj
index 1111111..1212121 100644
--- a/tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj
+++ b/tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj
@@ -1,16 +1,23 @@
 <Project Sdk="Microsoft.NET.Sdk">
   <PropertyGroup>
     <TargetFramework>net8.0</TargetFramework>
     <Nullable>enable</Nullable>
     <ImplicitUsings>enable</ImplicitUsings>
     <IsPackable>false</IsPackable>
+    <CopyLocalLockFileAssemblies>true</CopyLocalLockFileAssemblies>
   </PropertyGroup>
   <ItemGroup>
     <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.7" />
     <PackageReference Include="xunit" Version="2.9.0" />
     <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2">
       <PrivateAssets>all</PrivateAssets>
       <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
     </PackageReference>
     <PackageReference Include="FluentAssertions" Version="6.12.0" />
     <PackageReference Include="coverlet.collector" Version="6.0.2">
       <PrivateAssets>all</PrivateAssets>
     </PackageReference>
   </ItemGroup>
+  <ItemGroup>
+    <!-- Adjust path to your API csproj -->
+    <ProjectReference Include="..\..\src\services\Spe.TestServer\Spe.TestServer.csproj" />
+  </ItemGroup>
 </Project>
```

> If your API project path differs, fix the `ProjectReference` path then re-run `dotnet restore`.

---

### optional: central package management (safer)

Create `Directory.Packages.props` **at the repo root** and pin your shared packages:

```xml
<Project>
  <ItemGroup>
    <!-- Pin shared packages (fill exact versions you already use in the API) -->
    <PackageVersion Include="Azure.Core" Version="x.y.z" />
    <PackageVersion Include="Azure.Identity" Version="x.y.z" />
    <PackageVersion Include="Microsoft.Graph" Version="5.x.y" />
    <PackageVersion Include="Microsoft.Kiota.Abstractions" Version="1.x.y" />
    <PackageVersion Include="Microsoft.Kiota.Authentication.Azure" Version="1.x.y" />
  </ItemGroup>
</Project>
```

**How to fill the versions quickly:**
```bash
dotnet list path/to/YourApi.csproj package --include-transitive
# copy exact versions for Azure.Core, Azure.Identity, Microsoft.Graph, Kiota.*
```

Then remove explicit versions for these packages from individual `.csproj` files (NuGet will use the central versions).

---

### sanity re-run
```bash
dotnet clean
dotnet restore --force-evaluate
# Optional: ensure no outbound Graph auth during tests
export USE_FAKE_GRAPH=1
dotnet test -v n
```

If it still fails, paste the **first FileLoadException** lines (assembly name, requested vs loaded version). That pinpoints any remaining mismatch.

---

## part 2 — do we need GitHub CI?

**No, it’s optional.** Benefits are real (tests on PRs, coverage gate, repeatable builds), but if it’s noise right now you can:

- **Disable it temporarily** by renaming the workflow:
  - `.github/workflows/dotnet.yml` → `.github/workflows/dotnet.yml.disabled`
- **Or** replace with a **minimal** workflow that just builds & tests (no coverage):

```yaml
name: .NET quick

on:
  pull_request:
  push:
    branches: [ main, develop ]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
      - run: dotnet restore
      - run: dotnet build --configuration Release --no-restore
      - run: dotnet test --configuration Release --no-build
```

> You can re-enable the fuller workflow later when the test runtime is green.

---

## part 3 — lightweight test isolation (optional)

If you want to *ensure* tests never touch Graph while you sort dependencies:

- **Use the OBO service refactor** (`IOboSpeService`) from the PR-5 kit and override it in tests with a fake that returns fixed data.
- Or set `USE_FAKE_GRAPH=1` to swap in the simple `IGraphClientFactory` fake (precondition tests only).

Both patterns avoid real tokens/network during tests and keep runtime assemblies minimal.

---

## acceptance (for this fix)
- `dotnet test` runs locally without `Azure.Core` load errors
- Optional minimal CI workflow green on PR
- No code changes to runtime behavior
