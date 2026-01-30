using Arena.Models.Entities;

using Microsoft.AspNetCore.Identity;

namespace Arena.Server.Core;

public interface IAuthorizationService
{
    Task<(IdentityResult, ArenaUser?)> SignAsync<T>(T user, string scheme, string providerKey, string? email) where T : class;
}