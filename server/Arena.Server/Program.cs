using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using System.Text;
using System.Text.Json;
using System.Collections.Concurrent;
using Arena.Models;
using Arena.Server.Hubs;
using Arena.Server.Models;
using Arena.Server.Services;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<ArenaDbContext>(options =>
{
    if (!string.IsNullOrWhiteSpace(connectionString) && connectionString.TrimStart().StartsWith("Host=", StringComparison.OrdinalIgnoreCase))
    {
        options.UseNpgsql(connectionString);
    }
    else
    {
        options.UseSqlite(connectionString ?? "Data Source=arena.db");
    }
});

builder.Services.AddSingleton<IEloCalculator, EloCalculator>();
builder.Services.AddSingleton<ConcurrentDictionary<Guid, GameSession>>();
builder.Services.AddSingleton<ConcurrentDictionary<string, Guid>>();

builder.Services.AddHostedService<MatchmakingService>();

builder.Services.AddSignalR();

builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;

        var secret = builder.Configuration["Jwt:Secret"]
            ?? builder.Configuration["Jwt:Key"]
            ?? "arena-secret-key-for-development-minimum-32-chars";

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            NameClaimType = "sub",
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "arena",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "arena",
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(secret))
        };
        
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:8080", "http://localhost:3000")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<ArenaDbContext>();
    if (db.Database.ProviderName != null && db.Database.ProviderName.Contains("Sqlite", StringComparison.OrdinalIgnoreCase))
    {
        db.Database.EnsureCreated();
    }
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";

        HealthReportEntry? databaseEntry = report.Entries.TryGetValue("database", out var entry)
            ? entry
            : (HealthReportEntry?)null;

        var databaseStatus = databaseEntry.HasValue && databaseEntry.Value.Status == HealthStatus.Healthy
            ? "Connected"
            : "Disconnected";

        var payload = new Dictionary<string, object?>
        {
            ["status"] = report.Status.ToString(),
            ["database"] = databaseStatus,
            ["timestamp"] = DateTime.UtcNow.ToString("O")
        };

        if (databaseEntry.HasValue && databaseEntry.Value.Exception != null)
        {
            payload["error"] = databaseEntry.Value.Exception.Message;
        }

        await context.Response.WriteAsync(JsonSerializer.Serialize(payload));
    }
});

app.MapHub<GameHub>("/hubs/game");
app.MapHub<MatchmakingHub>("/hubs/matchmaking");

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
