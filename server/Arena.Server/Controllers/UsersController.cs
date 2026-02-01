using Arena.Models;
using Arena.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController(ArenaDbContext dbContext) : ControllerBase
{
    private readonly ArenaDbContext _dbContext = dbContext;

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetCurrentUser()
    {
        var userId = GetUserId();
        if (!userId.HasValue)
        {
            return Unauthorized();
        }

        var user = await _dbContext.Users.FindAsync(userId.Value);
        if (user == null)
        {
            return NotFound();
        }

        var gamesPlayed = user.Wins + user.Losses;
        var winRate = gamesPlayed > 0 ? (double)user.Wins / gamesPlayed * 100 : 0;

        var rank = await CalculateRank(user);

        return Ok(new
        {
            id = user.Id,
            displayName = user.DisplayName,
            email = user.Email,
            elo = user.Elo,
            wins = user.Wins,
            losses = user.Losses,
            winRate,
            gamesPlayed,
            rank
        });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetUser(Guid id)
    {
        var user = await _dbContext.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound();
        }

        return Ok(new
        {
            id = user.Id,
            email = user.Email,
            displayName = user.DisplayName,
            elo = user.Elo,
            wins = user.Wins,
            losses = user.Losses
        });
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst("sub")?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return null;
    }

    private async Task<int> CalculateRank(User user)
    {
        var betterCount = await _dbContext.Users.CountAsync(u =>
            u.Elo > user.Elo ||
            (u.Elo == user.Elo && u.Wins > user.Wins) ||
            (u.Elo == user.Elo && u.Wins == user.Wins && u.CreatedAt < user.CreatedAt));

        return betterCount + 1;
    }
}
