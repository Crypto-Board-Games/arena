using Arena.Models.Entities;
using Arena.Server.Core;
using Arena.Server.Infrastructure;
using Arena.Services;

using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Identity;

using System.Security.Claims;

namespace Arena.Server.Services;

public class AuthorizationService(UserManager<ArenaUser> userManager, SignInManager<ArenaUser> signInManager, UserRepository userRepository, PropertyService propertyService) : IAuthorizationService
{
    public async Task<(IdentityResult, ArenaUser?)> SignAsync<T>(T user, string scheme, string providerKey, string? email) where T : class
    {
        var signInResult = await signInManager.ExternalLoginSignInAsync(scheme, providerKey, false, true);

        if (signInResult.Succeeded && await userManager.FindByLoginAsync(scheme, providerKey) is ArenaUser pUser)
        {
            if (user is DeviceIdentity _)
            {
                pUser.LoginProvider = scheme;
            }
            _ = await userManager.UpdateAsync(pUser);

            return (await LogInUserAsync(user, scheme, pUser, providerKey), pUser);
        }

        if (user is DeviceIdentity di && string.IsNullOrEmpty(di.DeviceId) is false)
        {
            foreach (var (userId, loginProvider) in userRepository.ConfirmedExistingUsers(di.DeviceId))
            {
                if (scheme.Equals(loginProvider))
                {
                    continue;
                }

                if (await userManager.FindByIdAsync(userId) is ArenaUser existUser)
                {
                    existUser.LoginProvider = scheme;

                    return (await RegisterExternalLoginAsync(user, existUser, scheme, providerKey), existUser);
                }
            }
        }
        return await RegisterUserAsync(user, scheme, email, providerKey);
    }

    async Task<IdentityResult> LogInUserAsync<T>(T externalUser, string scheme, ArenaUser user, string providerKey) where T : class
    {
        var claimsIdentity = new ClaimsIdentity([new(ClaimTypes.NameIdentifier, user.Id)]);

        var loginInfo = new ExternalLoginInfo(new ClaimsPrincipal(claimsIdentity), scheme, providerKey, scheme)
        {
            AuthenticationProperties = new AuthenticationProperties
            {
                IsPersistent = true
            },
            AuthenticationTokens = propertyService.GetEnumerator(externalUser).Where(e => string.IsNullOrEmpty(e.Value) is false).DistinctBy(ks => ks.Name)
        };
        return await signInManager.UpdateExternalAuthenticationTokensAsync(loginInfo);
    }

    async Task<IdentityResult> RegisterExternalLoginAsync<T>(T userInfo, ArenaUser user, string scheme, string providerKey) where T : class
    {
        var claimsIdentity = new ClaimsIdentity([new(ClaimTypes.NameIdentifier, user.Id)]);

        var loginInfo = new ExternalLoginInfo(new ClaimsPrincipal(claimsIdentity), scheme, providerKey, scheme)
        {
            AuthenticationProperties = new AuthenticationProperties
            {
                IsPersistent = true
            },
            AuthenticationTokens = propertyService.GetEnumerator(userInfo).Where(e => string.IsNullOrEmpty(e.Value) is false).DistinctBy(ks => ks.Name)
        };
        var result = await userManager.AddLoginAsync(user, loginInfo);

        if (result.Succeeded)
        {
            var props = new AuthenticationProperties
            {
                IsPersistent = true
            };

            if (loginInfo.AuthenticationTokens != null)
            {
                props.StoreTokens(loginInfo.AuthenticationTokens);
            }
            await signInManager.SignInAsync(user, props, loginInfo.LoginProvider);

            return await signInManager.UpdateExternalAuthenticationTokensAsync(loginInfo);
        }
        return result;
    }

    async Task<(IdentityResult, ArenaUser?)> RegisterUserAsync<T>(T userInfo, string scheme, string? email, string providerKey) where T : class
    {
        _ = userInfo as DeviceIdentity;

        var user = new ArenaUser
        {
            UserName = email,
            Email = email,
            CreatedAt = DateTime.UtcNow,
            DisplayName = email?.Split('@')[0] ?? string.Empty,
            LoginProvider = scheme
        };
        var result = await userManager.CreateAsync(user);

        if (!result.Succeeded)
        {
            return (result, null);
        }
        return (await RegisterExternalLoginAsync(userInfo, user, scheme, providerKey), user);
    }
}