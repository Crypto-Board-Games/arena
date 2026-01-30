using Arena.Models.Entities;

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Arena.Server.Services;

public class JwtService(ILogger<JwtService> logger, string? issuer = "arena", string? audience = "arena", string? secretKey = "arena-secret-key-for-development-minimum-32-chars")
{
    public string GenerateJwtToken(ArenaUser user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim("sub", user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim("name", user.DisplayName),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(0x10),
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
}