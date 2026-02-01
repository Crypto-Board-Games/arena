using Arena.Models;
using Arena.Models.Entities;

using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Caching.Memory;

namespace Arena.Server;

public static partial class Extensions
{
    public static WebApplicationBuilder ConfigureStores(this WebApplicationBuilder builder, string connStr)
    {
        builder.Services.AddDbContextPool<ArenaDbContext>(options => ConfigureDangpleContextOptions(options, connStr))

            .AddDatabaseDeveloperPageExceptionFilter()

            .AddDefaultIdentity<ArenaUser>(configureOptions =>
            {
                configureOptions.Lockout.AllowedForNewUsers = false;
                configureOptions.Lockout.MaxFailedAccessAttempts = 0xA;
                configureOptions.Password.RequireUppercase = false;
                configureOptions.Password.RequiredLength = 0xA;
                configureOptions.User.RequireUniqueEmail = true;
            })
            .AddRoles<IdentityRole>()

            .AddEntityFrameworkStores<ArenaDbContext>()

            .AddDefaultTokenProviders();

        return builder;
    }

    static DbContextOptionsBuilder ConfigureDangpleContextOptions(this DbContextOptionsBuilder options, string connStr)
    {
        return options

            .UseNpgsql(connStr, npgsqlOptionsAction =>
            {
                npgsqlOptionsAction.UseNetTopologySuite()
                                   .UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery)
                                   .EnableRetryOnFailure(3);
            })

            .UseMemoryCache(new MemoryCache(new MemoryCacheOptions
            {

            }))

            .ConfigureWarnings(warningsConfigurationBuilderAction =>
            {
                var connectionError = (RelationalEventId.ConnectionError, LogLevel.Trace);
                var transactionError = (RelationalEventId.TransactionError, LogLevel.Trace);
                var commmandError = (RelationalEventId.CommandError, LogLevel.Trace);
                var includeWarning = (RelationalEventId.MultipleCollectionIncludeWarning, LogLevel.Trace);

                warningsConfigurationBuilderAction.Log(connectionError, transactionError, commmandError, includeWarning);
            })
#if DEBUG
            .EnableSensitiveDataLogging()
#endif
            .EnableDetailedErrors();
    }
}