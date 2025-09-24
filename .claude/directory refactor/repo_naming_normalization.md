# repo naming normalization — from `spe.testserver` to `spe.bff.api`

> goal: eliminate the misleading `Spe.TestServer` name and adopt a conventional .NET layout/naming for a BFF. keep behavior identical; only move/rename and update namespaces.

## target structure (phase 1: single project, minimal churn)

```
src/
  Spe.Bff.Api/
    Api/                # endpoints, middleware
    Infrastructure/     # Graph, Resilience, Validation, Errors
    Services/           # OBO/MI business services
    Models/             # DTOs & contracts (consider renaming to Contracts/ later)
    Program.cs
    Spe.Bff.Api.csproj
tests/
  Spe.Bff.Api.Tests/
    ... (unchanged; references Spe.Bff.Api)
```

> later (phase 2 optional) you can split into projects: `Spe.Bff.Application`, `Spe.Bff.Infrastructure`, `Spe.Bff.Contracts` — but do that only after tasks A–E.

---

## step-by-step (works on mac/linux; windows powershell commands below)

> do this at repo root

```bash
git checkout -b chore/rename-to-spe-bff-api

# 1) move project folder & rename csproj
mkdir -p src
git mv src/services/Spe.TestServer src/Spe.Bff.Api
git mv src/Spe.Bff.Api/Spe.TestServer.csproj src/Spe.Bff.Api/Spe.Bff.Api.csproj

# 2) fix namespaces & usings (simple token replacement)
#   replace 'Spe.TestServer' with 'Spe.Bff.Api' across code and tests
rg -l "Spe\.TestServer" | xargs sed -i.bak 's/Spe\.TestServer/Spe.Bff.Api/g'
find . -name "*.bak" -delete

# 3) update csproj metadata
#   - set <AssemblyName> and <RootNamespace> to Spe.Bff.Api
#   - ensure TargetFramework is net8.0 and Nullable enabled
# (Claude can edit this file exactly per snippet below)

# 4) update solution/project refs (if you use a .sln)
# (adjust the path to your .sln if different)
dotnet sln list || true
# remove old project path if needed (optional, Claude can do this)
# dotnet sln YourSolution.sln remove src/services/Spe.TestServer/Spe.TestServer.csproj
# add new
dotnet sln add src/Spe.Bff.Api/Spe.Bff.Api.csproj || true

# 5) fix test project reference (if not already using relative include)
# open tests/Spe.Bff.Api.Tests/Spe.Bff.Api.Tests.csproj and ensure:
#   <ProjectReference Include="..\\..\\src\\Spe.Bff.Api\\Spe.Bff.Api.csproj" />

# 6) build & test
dotnet clean && dotnet restore
dotnet build
dotnet test
```

### windows powershell variant (namespace replacement)
```powershell
git checkout -b chore/rename-to-spe-bff-api
git mv src/services/Spe.TestServer src/Spe.Bff.Api
git mv src/Spe.Bff.Api/Spe.TestServer.csproj src/Spe.Bff.Api/Spe.Bff.Api.csproj

# replace namespaces/usings
Get-ChildItem -Recurse -Include *.cs,*.csproj |
  ForEach-Object {
    (Get-Content $_.FullName) -replace 'Spe\.TestServer','Spe.Bff.Api' |
      Set-Content $_.FullName
  }

dotnet sln add src/Spe.Bff.Api/Spe.Bff.Api.csproj
dotnet clean; dotnet restore; dotnet build; dotnet test
```

---

## csproj snippet (replace the top of `src/Spe.Bff.Api/Spe.Bff.Api.csproj`)

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <AssemblyName>Spe.Bff.Api</AssemblyName>
    <RootNamespace>Spe.Bff.Api</RootNamespace>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
  </PropertyGroup>
  <!-- keep your existing PackageReference and ItemGroup content below -->
</Project>
```

> If you already use `Directory.Build.props` or central package management, keep those as-is.

---

## namespace guidance (inside the single project)

Keep folders, update namespaces to be descriptive:

- `Api/` → `namespace Spe.Bff.Api.Endpoints` (and `.Middleware` if you split files)
- `Infrastructure/Graph` → `namespace Spe.Bff.Api.Infrastructure.Graph`
- `Infrastructure/Resilience` → `namespace Spe.Bff.Api.Infrastructure.Resilience`
- `Infrastructure/Validation` → `namespace Spe.Bff.Api.Infrastructure.Validation`
- `Infrastructure/Errors` → `namespace Spe.Bff.Api.Infrastructure.Errors`
- `Services/` → `namespace Spe.Bff.Api.Application` (or `.Services` if you prefer)
- `Models/` → **rename later** to `Contracts/` → `namespace Spe.Bff.Api.Contracts`

You can enforce this in bulk with Search/Replace in VS Code after the initial build passes.

---

## tests

Rename the test project (if not already): `tests/Spe.Bff.Api.Tests`. Ensure:

- `Spe.Bff.Api.Tests.csproj` contains a `<ProjectReference>` to `src/Spe.Bff.Api/Spe.Bff.Api.csproj`
- Namespaces in tests reference `Spe.Bff.Api.*` as needed

---

## optional (later): multi-project split

When you’re ready to formalize layers:

```
src/
  Spe.Bff.Api/            # web host (endpoints, middleware, DI)
  Spe.Bff.Application/    # services, interfaces, policies (no Graph)
  Spe.Bff.Infrastructure/ # Graph, resilience, validation, ProblemDetails
  Spe.Bff.Contracts/      # DTOs shared with SPA and tests
tests/
  Spe.Bff.Api.Tests/
  Spe.Bff.Application.Tests/
  Spe.Bff.Infrastructure.Tests/
```

- Move `Services/*` → `Spe.Bff.Application`
- Move `Infrastructure/*` → `Spe.Bff.Infrastructure`
- Move `Models/*` (DTOs) → `Spe.Bff.Contracts`
- Wire references: `Api → Application, Infrastructure, Contracts`; `Application → Contracts`; `Infrastructure → Application (if needed) & Contracts`

Do this after Phase 2 Tasks A–E so you’re not refactoring under active endpoint changes.

---

## acceptance (for this rename PR)
- Build & tests pass
- No code behavior changed
- All namespaces are `Spe.Bff.Api.*`
- Test project references updated
- Solution opens with the new project path
