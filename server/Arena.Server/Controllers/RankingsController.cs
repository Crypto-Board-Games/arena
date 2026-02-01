using Arena.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Controllers;

[ApiController]
[Route("api/rankings")]
[Authorize]
public class RankingsController : ControllerBase
{
    private readonly ArenaDbContext _dbContext;

    public RankingsController(ArenaDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<IActionResult> GetRankings([FromQuery] int limit = 100)
    {
        if (limit <= 0)
        {
            limit = 100;
        }

        var userId = GetUserId();
        if (!userId.HasValue)
        {
            return Unauthorized();
        }

        var me = await _dbContext.Users.FindAsync(userId.Value);
        if (me == null)
        {
            return NotFound();
        }

        var topUsers = await _dbContext.Users
            .OrderByDescending(u => u.Elo)
            .ThenByDescending(u => u.Wins)
            .ThenBy(u => u.CreatedAt)
            .Take(limit)
            .ToListAsync();

        var rankings = topUsers.Select((u, index) => new
        {
            rank = index + 1,
            userId = u.Id,
            displayName = u.DisplayName,
            elo = u.Elo,
            wins = u.Wins,
            losses = u.Losses
        });

        var myRank = await CalculateRank(me);

        return Ok(new
        {
            rankings,
            myRank
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

    private async Task<int> CalculateRank(Arena.Models.Entities.User user)
    {
        var betterCount = await _dbContext.Users.CountAsync(u =>
            u.Elo > user.Elo ||
            (u.Elo == user.Elo && u.Wins > user.Wins) ||
            (u.Elo == user.Elo && u.Wins == user.Wins && u.CreatedAt < user.CreatedAt));

        return betterCount + 1;
    }
}
