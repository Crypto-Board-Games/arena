using Arena.Models.Entities;
using Arena.Services;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json;
using System.Text;

namespace Arena.Server;

public static partial class Extension
{
    public static WebApplicationBuilder ConfigureAuthenticates(this WebApplicationBuilder builder)
    {
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)

            .AddGoogle(googleOptions =>
            {
                googleOptions.Events.OnCreatingTicket = context =>
                {
                    var tokens = context.Properties.GetTokens().ToList();
                    var googleUser = JsonConvert.DeserializeObject<GoogleUser>(context.User.GetRawText());

                    if (googleUser != null)
                    {
                        using (var scope = context.HttpContext.RequestServices.CreateScope())
                        {
                            foreach (var token in scope.ServiceProvider.GetRequiredService<PropertyService>().GetEnumerator(googleUser))
                            {
                                tokens.Add(token);
                            }
                        }
                        context.Properties.StoreTokens(tokens);
                    }
                    return Task.CompletedTask;
                };
                googleOptions.SaveTokens = true;
                googleOptions.ClientId = builder.Configuration["Google:ClientId"]!;
                googleOptions.ClientSecret = builder.Configuration["Google:ClientSecret"]!;
            })

            .AddJwtBearer(options =>
            {
                var key = Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? "arena-secret-key-for-development-minimum-32-chars");

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "arena",
                    ValidAudience = builder.Configuration["Jwt:Audience"] ?? "arena",
                    IssuerSigningKey = new SymmetricSecurityKey(key)
                };

                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        var accessToken = context.Request.Headers[Microsoft.Net.Http.Headers.HeaderNames.Authorization];

                        var path = context.HttpContext.Request.Path;
                        if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                        {
                            context.Token = accessToken;
                        }
                        return Task.CompletedTask;
                    }
                };

                options.IncludeErrorDetails = true;
                options.SaveToken = true;
                options.RequireHttpsMetadata = false;
            });

        builder.Services.AddAuthorization();

        return builder;
    }
}