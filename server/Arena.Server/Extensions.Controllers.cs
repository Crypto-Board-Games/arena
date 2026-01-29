using Arena.Server.Services;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc.ApplicationModels;
using Microsoft.AspNetCore.Mvc.NewtonsoftJson;
using Microsoft.OpenApi;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplicationBuilder ConfigureControllers(this WebApplicationBuilder builder)
    {
        OpenApiInfo openApiInfo = new()
        {
            Contact = new OpenApiContact
            {
                Name = nameof(Arena),
                Url = new Uri("http://arena.dayond.kr")
            },
            Description = "this version that integrates all environments",
            TermsOfService = new Uri("http://arena.dayond.kr/terms"),
            Title = nameof(Arena)
        };

        OpenApiSecurityScheme securityScheme = new()
        {
            Scheme = JwtBearerDefaults.AuthenticationScheme,
            Description = $"JWT Authorization header using the {JwtBearerDefaults.AuthenticationScheme} scheme.",
            Name = Microsoft.Net.Http.Headers.HeaderNames.Authorization,
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.ApiKey
        };

        _ = builder.Services.AddSwaggerGen(setupAction =>
         {
             setupAction.CustomSchemaIds(schemaIdSelector => schemaIdSelector.FullName?.Replace('.', '_'));

             setupAction.EnableAnnotations();

             setupAction.AddSecurityDefinition(JwtBearerDefaults.AuthenticationScheme, securityScheme);

             setupAction.AddSecurityRequirement(document => new OpenApiSecurityRequirement
             {
                 [new OpenApiSecuritySchemeReference(JwtBearerDefaults.AuthenticationScheme, document)] = []
             });
         })

         .AddControllersWithViews(configure =>
         {
             configure.Conventions.Add(new RouteTokenTransformerConvention(new SlugifyParameterTransformer()));

             configure.ModelMetadataDetailsProviders.Add(new NewtonsoftJsonValidationMetadataProvider());
         })

         .AddNewtonsoftJson(setupAction =>
         {

         })

         .AddJsonOptions(configure =>
         {
#if DEBUG
             configure.JsonSerializerOptions.WriteIndented = true;
#endif
         });

        return builder;
    }
}