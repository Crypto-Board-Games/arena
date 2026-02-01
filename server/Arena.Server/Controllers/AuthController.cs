using Arena.Models;
using Arena.Models.Entities;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Arena.Server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ArenaDbContext _dbContext;
    private readonly IConfiguration _configuration;

    public AuthController(ArenaDbContext dbContext, IConfiguration configuration)
    {
        _dbContext = dbContext;
        _configuration = configuration;
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleAuth([FromBody] GoogleAuthRequest request)
    {
        try
        {
            GoogleJsonWebSignature.Payload? payload = null;

            if (HttpContext.RequestServices.GetRequiredService<IHostEnvironment>().IsDevelopment() &&
                request.IdToken == "dev_bypass_token")
            {
                // Development-only bypass for local testing.
                payload = new GoogleJsonWebSignature.Payload
                {
                    Subject = request.Email ?? Guid.NewGuid().ToString("N"),
                    Email = request.Email ?? "test@example.com",
                    Name = request.DisplayName
                };
            }
            else
            {
                var googleClientId = _configuration["Google:ClientId"];
                if (!string.IsNullOrWhiteSpace(googleClientId))
                {
                    payload = await GoogleJsonWebSignature.ValidateAsync(
                        request.IdToken,
                        new GoogleJsonWebSignature.ValidationSettings
                        {
                            Audience = new[] { googleClientId }
                        });
                }
                else
                {
                    payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken);
                }
            }

            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.GoogleId == payload.Subject);

            if (user == null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    GoogleId = payload.Subject,
                    Email = payload.Email,
                    DisplayName = payload.Name ?? payload.Email.Split('@')[0],
                    Elo = 1200,
                    Wins = 0,
                    Losses = 0,
                    CreatedAt = DateTime.UtcNow
                };
                _dbContext.Users.Add(user);
                await _dbContext.SaveChangesAsync();
            }

            var (token, expiresIn) = GenerateJwtToken(user);

            return Ok(new
            {
                access_token = token,
                expires_in = expiresIn,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    displayName = user.DisplayName,
                    elo = user.Elo,
                    wins = user.Wins,
                    losses = user.Losses
                }
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { message = "Invalid Google token" });
        }
    }

    private (string token, int expiresIn) GenerateJwtToken(User user)
    {
        var secret = _configuration["Jwt:Secret"]
            ?? _configuration["Jwt:Key"]
            ?? "arena-secret-key-for-development-minimum-32-chars";

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var now = DateTime.UtcNow;
        var expiresAt = now.AddHours(24);

        var claims = new[]
        {
            new Claim("sub", user.Id.ToString()),
            new Claim("email", user.Email),
            new Claim("name", user.DisplayName),
            new Claim(JwtRegisteredClaimNames.Iat, ((DateTimeOffset)now).ToUnixTimeSeconds().ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "arena",
            audience: _configuration["Jwt:Audience"] ?? "arena",
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials
        );

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresIn: 86400);
    }
}

public class GoogleAuthRequest
{
    public string IdToken { get; set; } = string.Empty;

    public string? Email { get; set; }

    public string? DisplayName { get; set; }
}
