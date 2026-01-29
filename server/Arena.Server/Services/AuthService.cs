using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Arena.Models.Entities;
using Arena.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;

public class AuthorizationService(IConfiguration configuration, UserManager<ArenaUser> userManager, SignInManager<ArenaUser> signInManager, PropertyService propertyService) : IAuthService
{
    public string GenerateJwtToken(ArenaUser user)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(configuration["Jwt:Key"] ?? "arena-secret-key-for-development-minimum-32-chars"));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim("sub", user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? ""),
            new Claim("name", user.DisplayName),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: configuration["Jwt:Issuer"] ?? "arena",
            audience: configuration["Jwt:Audience"] ?? "arena",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public ClaimsPrincipal? ValidateJwtToken(string? bearerToken, TokenValidationParameters validationParameters)
    {
        if (string.IsNullOrEmpty(bearerToken))
        {
            return null;
        }

        try
        {
            var token = bearerToken.Replace(JwtBearerDefaults.AuthenticationScheme, string.Empty).Trim();

            var principal = new JwtSecurityTokenHandler().ValidateToken(token, validationParameters, out SecurityToken _);

            return new ClaimsPrincipal(new ClaimsIdentity(principal.Claims, JwtBearerDefaults.AuthenticationScheme));
        }
        catch (Exception ex)
        {
            if (!ex.Message.StartsWith("IDX12709") && !ex.Message.StartsWith("IDX12741") && !ex.Message.StartsWith("IDX10223"))
            {
                logger.LogError("{ }", ex.Message);
            }
            return null;
        }
    }

    public async Task<(IdentityResult, ArenaUser?)> SignAsync<T>(T user, string scheme, string providerKey, string? email) where T : class
    {
        var signInResult = await signInManager.ExternalLoginSignInAsync(scheme, providerKey, false, true);

        if (signInResult.Succeeded && await userManager.FindByLoginAsync(scheme, providerKey) is ArenaUser pUser)
        {
            if (user is DeviceIdentity i)
            {
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
        var i = userInfo as DeviceIdentity;

        var user = new ArenaUser
        {
            UserName = email,
            Email = email,
            CreatedAt = DateTime.UtcNow,
            DisplayName = email?.Split('@')[0] ?? string.Empty,
        };
        var result = await userManager.CreateAsync(user);

        if (!result.Succeeded)
        {
            return (result, null);
        }
        return (await RegisterExternalLoginAsync(userInfo, user, scheme, providerKey), user);
    }
}