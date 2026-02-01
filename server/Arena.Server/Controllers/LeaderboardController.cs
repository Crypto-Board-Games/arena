using Arena.Models;

using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class LeaderboardController(ArenaDbContext dbContext) : ControllerBase
{
    private readonly ArenaDbContext _dbContext = dbContext;

    [HttpGet]
    public async Task<IActionResult> GetLeaderboard([FromQuery] int limit = 100)
    {
        var users = await _dbContext.Users
            .OrderByDescending(u => u.Elo)
            .ThenByDescending(u => u.Wins)
            .Take(limit)
            .Select((u, index) => new LeaderboardEntryDto
            {
                Rank = index + 1,
                UserId = u.Id,
                DisplayName = u.DisplayName,
                Elo = u.Elo,
                Wins = u.Wins,
                Losses = u.Losses
            })
            .ToListAsync();

        for (int i = 0; i < users.Count; i++)
        {
            users[i].Rank = i + 1;
        }

        return Ok(users);
    }

    [HttpGet("rank/{userId:guid}")]
    public async Task<IActionResult> GetUserRank(Guid userId)
    {
        var user = await _dbContext.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound();
        }

        var rank = await _dbContext.Users
            .CountAsync(u => u.Elo > user.Elo || (u.Elo == user.Elo && u.Wins > user.Wins));

        return Ok(new
        {
            userId,
            rank = rank + 1,
            displayName = user.DisplayName,
            elo = user.Elo,
            wins = user.Wins,
            losses = user.Losses
        });
    }
}

public class LeaderboardEntryDto
{
    public int Rank { get; set; }
    public required string UserId
    {
        get; set;
    }

    public required string DisplayName
    {
        get; set;
    }

    public int Elo { get; set; }
    public int Wins { get; set; }
    public int Losses { get; set; }
}
