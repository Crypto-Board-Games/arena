using Arena.Models.Entities;
using Arena.Server.Core;
using Arena.Server.Services;

using Microsoft.AspNetCore.Authentication.Google;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Controllers;

[ApiController, Route("api/[controller]")]
public class AuthController(ILogger<AuthController> logger, IAuthorizationService authService, JwtService jwtService) : ControllerBase
{
    [HttpPost("google")]
    public async Task<IActionResult> GoogleAuthAsync([FromBody] GoogleUser googleUser)
    {
        if (string.IsNullOrEmpty(googleUser.Email) || string.IsNullOrEmpty(googleUser.Id))
        {
            return BadRequest("important element was missing from the sign-up process.");
        }
        (IdentityResult result, ArenaUser? user) = await authService.SignAsync(googleUser, GoogleDefaults.AuthenticationScheme, googleUser.Id, googleUser.Email);

        if (result.Succeeded && user != null)
        {
            return Ok(new AuthResponse
            {
                User = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    DisplayName = user.DisplayName,
                    Elo = user.Elo,
                    Wins = user.Wins,
                    Losses = user.Losses
                },
                Token = jwtService.GenerateJwtToken(user)
            });
        }

        foreach (var err in result.Errors)
        {
            logger.LogError("Code: { }\nDescription: { }", err.Code, err.Description);
        }
        return Unauthorized(new { message = result.Errors });
    }
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