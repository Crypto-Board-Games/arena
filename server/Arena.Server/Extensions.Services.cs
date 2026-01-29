using Arena.Server.Models;
using Arena.Server.Services;

using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Server.Kestrel.Core;

using System.Collections.Concurrent;
using System.Net;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplicationBuilder ConfigureServices(this WebApplicationBuilder builder, string[] origins)
    {
        _ = builder.Services.AddMemoryCache()

            .AddSingleton<IEloCalculator, EloCalculator>()
            .AddSingleton<ConcurrentDictionary<Guid, GameSession>>()
            .AddSingleton<ConcurrentDictionary<string, Guid>>()

            .AddHttpLogging(configureOptions =>
            {
                configureOptions.LoggingFields = HttpLoggingFields.RequestPropertiesAndHeaders;
            })

            .AddCors(options =>
            {
                options.AddDefaultPolicy(policy =>
                {
                    policy
#if DEBUG
                                   .AllowAnyOrigin()
#else
                                   .WithOrigins(origins)
                                   .AllowCredentials()
#endif
                                   .AllowAnyHeader()
                                   .AllowAnyMethod();
                });
            })

            .Configure<KestrelServerOptions>(configureOptions =>
            {
                configureOptions.ListenAnyIP(15397, configure =>
                {
                    _ = configure.UseConnectionLogging();
                });
                configureOptions.Limits.MaxRequestBodySize = 0x400 * 0x400 * 0x400;
            })

            .Configure<ForwardedHeadersOptions>(configureOptions =>
            {
                configureOptions.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                configureOptions.KnownProxies.Add(IPAddress.Parse(builder.Configuration["ProxyIpAddress"]!));
            });

        return builder;
    }
}