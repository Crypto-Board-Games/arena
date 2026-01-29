using System.Net;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplicationBuilder Configure(this WebApplicationBuilder builder)
    {
        var connStr = builder.Configuration.GetConnectionString("ArenaConnection")!;

        var origins = builder.Configuration["Origins"]!.Split(';');

        return builder.ConfigureViews()
                      .ConfigureServices(origins)
                      .ConfigureControllers()
                      .ConfigureAuthenticates()
                      .ConfigureStores(connStr)
                      .ConfigureHubs();
    }

    public static IApplicationBuilder UseAllowAddress(this IApplicationBuilder builder, string[] safeIpAddress)
    {
        var allowIpAddress = new IPAddress[safeIpAddress.Length];

        for (int index = 0; index < safeIpAddress.Length; index++)
        {
            allowIpAddress[index] = IPAddress.Parse(safeIpAddress[index]);
        }
        return builder.Use(async (context, next) =>
        {
            if (context.Request.Path.StartsWithSegments($"/api", StringComparison.OrdinalIgnoreCase))
            {
                var remoteIp = context.Connection.RemoteIpAddress;

                if (!Array.Exists(allowIpAddress, match => match.Equals(remoteIp?.MapToIPv4()) || match.Equals(remoteIp)))
                {
                    context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;

                    return;
                }
            }
            await next();
        });
    }
}