using Arena.Models.Entities;

using Google.Apis.Auth;
using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Arena.Server.Controllers;

[ApiController, Route("api/[controller]")]
public class AuthController(UserManager<ArenaUser> userManager, SignInManager<ArenaUser> signInManager, ) : ControllerBase
{
    [HttpPost("google")]
    public async Task<IActionResult> GoogleAuth([FromBody] GoogleAuthRequest request)
    {
        try
        {
            var payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken);

            var result = await signInManager.ExternalLoginSignInAsync(GoogleDefaults.AuthenticationScheme, payload.Subject, isPersistent: false, bypassTwoFactor: true);

            if (!result.Succeeded)
            {
                var user = await userManager.Users.FirstOrDefaultAsync(u => u.GoogleId == payload.Subject);

                if (user == null)
                {
                    user = new ArenaUser
                    {
                        UserName = payload.Email,
                        Email = payload.Email,
                        DisplayName = payload.Name ?? payload.Email?.Split('@')[0] ?? "Player",
                        Elo = 1200,
                        Wins = 0,
                        Losses = 0,
                        CreatedAt = DateTime.UtcNow
                    };

                    var result = await _userManager.CreateAsync(user);
                    if (!result.Succeeded)
                    {
                        return BadRequest(new { message = "Failed to create user", errors = result.Errors });
                    }
                }
            }
            var token = GenerateJwtToken(user);

            return Ok(new AuthResponse
            {
                Token = token,
                User = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    Elo = user.Elo,
                    Wins = user.Wins,
                    Losses = user.Losses
                }
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { message = "Invalid Google token" });
        }
    }

    private
}

public class GoogleAuthRequest
{
    public string IdToken { get; set; } = string.Empty;
}

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public UserDto User { get; set; } = null!;
}

public class UserDto
{
    public required string Id { get; set; }
    public string? Email { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public int Elo { get; set; }
    public int Wins { get; set; }
    public int Losses { get; set; }
}
