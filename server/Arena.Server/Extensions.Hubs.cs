using Arena.Server.Hubs;

using Newtonsoft.Json;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplication ConfigureHubs(this WebApplication app)
    {
        app.MapHub<GameHub>("/hubs/game");
        app.MapHub<MatchmakingHub>("/hubs/matchmaking");

        return app;
    }

    public static WebApplicationBuilder ConfigureHubs(this WebApplicationBuilder builder)
    {
        builder.Services

            .AddSignalR(configure =>
            {
                configure.ClientTimeoutInterval = TimeSpan.FromSeconds(0x400);
                configure.HandshakeTimeout = TimeSpan.FromSeconds(0x200);
                configure.EnableDetailedErrors = true;
            })

            .AddNewtonsoftJsonProtocol(configure =>
            {
                configure.PayloadSerializerSettings.TypeNameHandling = TypeNameHandling.Auto;
                configure.PayloadSerializerSettings.NullValueHandling = NullValueHandling.Ignore;
            });

        return builder;
    }
}