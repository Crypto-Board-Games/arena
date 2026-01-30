using Arena.Server;

using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;

using System.Net;


using (var app = WebApplication.CreateBuilder(args).Configure().Build())
{
    if (app.Environment.IsDevelopment())
    {
        app.UseDeveloperExceptionPage().UseMigrationsEndPoint();
    }
    else
    {
        app.UseExceptionHandler("/Error");
    }
    app.UseForwardedHeaders(new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
        KnownProxies = { }
    })
           .UseHttpLogging()
           .UseResponseCompression()
           .UseAllowAddress(app.Configuration["AdminSafeList"]!.Split(';'))

           .UseSwagger(setupAction =>
           {
               setupAction.OpenApiVersion = Microsoft.OpenApi.OpenApiSpecVersion.OpenApi3_1;
           })

           .UseSwaggerUI(setupAction =>
           {
               setupAction.DocumentTitle = nameof(Arena);
               setupAction.RoutePrefix = "api";
           })
           .UseDefaultFiles()

           .UseStaticFiles(new StaticFileOptions
           {
               ServeUnknownFileTypes = true,
               DefaultContentType = "application/octet-stream"
           })

           .UseRouting()
           .UseCors()

           .UseAuthentication()
           .UseAuthorization();

    app.MapControllers();
    app.MapBlazorHub(configureOptions =>
    {

    });
    app.ConfigureHubs().Run();
}