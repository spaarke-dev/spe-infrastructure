# pr-4 — security & observability hardening (minimal apis)

> purpose: add explicit **authorization policies**, **security headers**, **CORS** for the SPA, and **OpenTelemetry + Azure Monitor (App Insights)**. Ensure rate limits/validation are consistently applied to both **MI** and **OBO** endpoints.

---

## 0) guardrails
- No Razor/MVC. No browser Graph calls.
- RFC7807 with `traceId` everywhere on errors; include `graphRequestId` when available.
- Never log tokens/claims; redact `Authorization` headers.
- Apply `graph-read` / `graph-write` rate-limits consistently.

---

## 1) scope
- Add **authorization policies**: `canmanagecontainers`, `canwritefiles` (replace stubs with your real mapping).
- Add **security headers** middleware.
- Add **CORS** for your SPA origin(s).
- Add **OpenTelemetry** and **Azure Monitor exporter** (App Insights).
- Ensure request size limits are enforced for small upload (keep 4 MiB cutoff; larger uses upload sessions).

---

## 2) cloud config (app settings)
- `Cors:AllowedOrigins` — comma-separated origins (e.g., `https://app.contoso.com,https://localhost:5173`)
- `ApplicationInsights:ConnectionString` — your App Insights connection string

> Keys stay in Key Vault where appropriate (e.g., OBO confidential client secret). Do **not** store secrets in repo.

---

## 3) ready-to-apply patch (program wiring + middleware)

> Save as `pr4_security_observability.patch` and run:
> ```
> git checkout -b feature/pr4-security-observability
> git apply pr4_security_observability.patch
> dotnet build
> ```
> If your files differ, ask Claude to adapt.

<details>
<summary><strong>Unified diff</strong></summary>

```diff
diff --git a/Program.cs b/Program.cs
index 2222222..4444444 100644
--- a/Program.cs
+++ b/Program.cs
@@ -1,12 +1,27 @@
 using System.Threading.RateLimiting;
 using Microsoft.AspNetCore.RateLimiting;
 using Microsoft.Extensions.Logging;
+using Microsoft.AspNetCore.Authorization;
+using Microsoft.AspNetCore.HttpOverrides;
+using OpenTelemetry.Trace;
+using OpenTelemetry.Resources;
+using OpenTelemetry.Metrics;
+using OpenTelemetry.Logs;
+using OpenTelemetry;
+using Api; // MapOBOEndpoints & SecurityHeaders
@@
 var builder = WebApplication.CreateBuilder(args);

+// Authorization policies (replace RequireAssertion with your real mapping)
+builder.Services.AddAuthorization(options =>
+{
+    options.AddPolicy("canmanagecontainers", p => p.RequireAssertion(_ => true)); // TODO
+    options.AddPolicy("canwritefiles",      p => p.RequireAssertion(_ => true)); // TODO
+});
+
 // Rate limiting (existing)
 // builder.Services.AddRateLimiter( ... );
@@
+// CORS for SPA
+var allowed = builder.Configuration.GetValue<string>("Cors:AllowedOrigins") ?? "";
+builder.Services.AddCors(o =>
+{
+    o.AddPolicy("spa", p =>
+    {
+        if (!string.IsNullOrWhiteSpace(allowed))
+            p.WithOrigins(allowed.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
+        else
+            p.AllowAnyOrigin(); // dev fallback
+        p.AllowAnyHeader().AllowAnyMethod();
+        p.WithExposedHeaders("request-id","client-request-id","traceparent");
+    });
+});
+
+// OpenTelemetry (ASP.NET Core + HttpClient). Configure Azure Monitor in cloud via connection string.
+builder.Services.AddOpenTelemetry()
+    .ConfigureResource(r => r.AddService(serviceName: "spe-bff-api"))
+    .WithTracing(t =>
+    {
+        t.AddAspNetCoreInstrumentation();
+        t.AddHttpClientInstrumentation(o => o.RecordException = true);
+    })
+    .WithMetrics(m => { });
+
 var app = builder.Build();

 // Middlewares
 app.UseRateLimiter();
+app.UseCors("spa");
+app.UseMiddleware<Api.SecurityHeadersMiddleware>();
+app.UseAuthorization();

 // Map endpoints
 app.MapOBOEndpoints();

 app.Run();
diff --git a/Api/SecurityHeadersMiddleware.cs b/Api/SecurityHeadersMiddleware.cs
new file mode 100644
index 0000000..7777777
--- /dev/null
+++ b/Api/SecurityHeadersMiddleware.cs
@@ -0,0 +1,68 @@
+namespace Api;
+
+public sealed class SecurityHeadersMiddleware
+{
+    private readonly RequestDelegate _next;
+    public SecurityHeadersMiddleware(RequestDelegate next) => _next = next;
+
+    public async Task Invoke(HttpContext ctx)
+    {
+        var h = ctx.Response.Headers;
+        if (!h.ContainsKey("X-Content-Type-Options")) h.Append("X-Content-Type-Options", "nosniff");
+        if (!h.ContainsKey("Referrer-Policy"))       h.Append("Referrer-Policy", "no-referrer");
+        if (!h.ContainsKey("X-Frame-Options"))       h.Append("X-Frame-Options", "DENY");
+        if (!h.ContainsKey("X-XSS-Protection"))      h.Append("X-XSS-Protection", "0");
+        if (!h.ContainsKey("Strict-Transport-Security"))
+            h.Append("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
+        // Locked-down CSP for API responses (safe for JSON/file responses)
+        if (!h.ContainsKey("Content-Security-Policy"))
+            h.Append("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'");
+
+        await _next(ctx);
+    }
+}
```
```

</details>

> NuGet note: if you want **Azure Monitor export**, add the package `Azure.Monitor.OpenTelemetry.AspNetCore` in your project file and call `.UseAzureMonitor()` in the OpenTelemetry builder (Claude can wire this for you). You can also keep OTLP if you prefer.

---

## 4) apply policies/limits on endpoints
- `.RequireAuthorization("canmanagecontainers")` on **admin** ops (e.g., `POST /api/containers`).
- `.RequireAuthorization("canwritefiles")` on **write** ops (uploads, delete).
- `graph-read` limiter on list/get/download; `graph-write` on upload/delete.

Example:
```csharp
app.MapPost("/api/containers", /* ... */)
   .RequireAuthorization("canmanagecontainers")
   .RequireRateLimiting("graph-write");
```

---

## 5) logging hygiene
- Do **not** log `Authorization` header or tokens/claims.
- Include `traceId` and (when present) Graph `request-id` in error logs.
- Consider a small inbound filter that removes `Authorization` from any generic request logging.

---

## 6) tests you should add
- **Headers present** on 200/4xx responses (CSP, HSTS, X-Content-Type-Options, Referrer-Policy).
- **CORS preflight** (OPTIONS) succeeds for allowed origin.
- **Policies enforced**: 401/403 on protected endpoints when missing token/role.
- **Rate limits**: verify limiter applied on write endpoints.

---

## 7) validate in cloud
- Set `Cors:AllowedOrigins` to your SPA domains.
- Set `ApplicationInsights:ConnectionString` (or use Azure Monitor extension).
- Verify traces/logs are visible in App Insights; correlate with `traceId`.

---

## 8) merge gate (acceptance criteria)
- Build succeeds; security headers and CORS active.
- Policy-protected endpoints return 401/403 as expected.
- OTEL traces and request logs visible in App Insights.
- No secrets or tokens in logs.
