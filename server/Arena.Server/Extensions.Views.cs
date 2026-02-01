using Microsoft.AspNetCore.ResponseCompression;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplicationBuilder ConfigureViews(this WebApplicationBuilder builder)
    {
        _ = builder.Services

            .AddResponseCompression(configureOptions =>
            {
                configureOptions.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(["application/octet-stream"]);
            })

            .AddRazorPages(configure =>
            {

            });

        _ = builder.Services.AddServerSideBlazor(configure =>
        {
            configure.DetailedErrors = true;
            configure.DisconnectedCircuitMaxRetained = 0x32;
        });

        return builder;
    }
}