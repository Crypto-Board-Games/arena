using Arena.Models;
using Arena.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class GamesController : ControllerBase
{
    private readonly ArenaDbContext _dbContext;

    public GamesController(ArenaDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    [Authorize]
    public async Task<IActionResult> GetMyGames([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = GetUserId();
        if (!userId.HasValue)
        {
            return Unauthorized();
        }

        var query = _dbContext.Games
            .Where(g => g.BlackPlayerId == userId.Value || g.WhitePlayerId == userId.Value)
            .Where(g => g.Status == GameStatus.Completed)
            .OrderByDescending(g => g.EndedAt);

        var totalCount = await query.CountAsync();
        var games = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(g => new GameDto
            {
                Id = g.Id,
                BlackPlayerId = g.BlackPlayerId,
                WhitePlayerId = g.WhitePlayerId,
                WinnerId = g.WinnerId,
                Status = g.Status.ToString(),
                CreatedAt = g.CreatedAt,
                EndedAt = g.EndedAt
            })
            .ToListAsync();

        return Ok(new
        {
            games,
            totalCount,
            page,
            pageSize,
            totalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetGame(Guid id)
    {
        var game = await _dbContext.Games.FindAsync(id);
        if (game == null)
        {
            return NotFound();
        }

        var blackPlayer = await _dbContext.Users.FindAsync(game.BlackPlayerId);
        var whitePlayer = await _dbContext.Users.FindAsync(game.WhitePlayerId);

        return Ok(new GameDetailDto
        {
            Id = game.Id,
            BlackPlayer = blackPlayer != null ? new GameUserDto
            {
                Id = blackPlayer.Id,
                DisplayName = blackPlayer.DisplayName,
                Elo = blackPlayer.Elo
            } : null,
            WhitePlayer = whitePlayer != null ? new GameUserDto
            {
                Id = whitePlayer.Id,
                DisplayName = whitePlayer.DisplayName,
                Elo = whitePlayer.Elo
            } : null,
            WinnerId = game.WinnerId,
            Status = game.Status.ToString(),
            CreatedAt = game.CreatedAt,
            EndedAt = game.EndedAt
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
}

public class GameDto
{
    public Guid Id { get; set; }
    public Guid BlackPlayerId { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Guid? WinnerId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? EndedAt { get; set; }
}

public class GameDetailDto
{
    public Guid Id { get; set; }
    public GameUserDto? BlackPlayer { get; set; }
    public GameUserDto? WhitePlayer { get; set; }
    public Guid? WinnerId { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? EndedAt { get; set; }
}

public class GameUserDto
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public int Elo { get; set; }
}
