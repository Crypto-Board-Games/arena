using Arena.Models;
using Arena.Models.Entities;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Hubs;

[Authorize]
public class MatchmakingHub(ArenaDbContext dbContext) : Hub
{
    private readonly ArenaDbContext _dbContext = dbContext;

    private const int EloRangeBase = 200;
    private const int EloRangeIncrement = 100;
    private const int MaxEloRange = 500;

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();

        if (!string.IsNullOrEmpty(userId))
        {
            var queueEntry = await _dbContext.MatchQueues.FirstOrDefaultAsync(m => m.UserId.Equals(userId));

            if (queueEntry != null)
            {
                _dbContext.MatchQueues.Remove(queueEntry);
                await _dbContext.SaveChangesAsync();
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinQueue()
    {
        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
        {
            await Clients.Caller.SendAsync("OnError", new { message = "Unauthorized" });
            return;
        }

        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
        {
            await Clients.Caller.SendAsync("OnError", new { message = "User not found" });
            return;
        }

        var existingEntry = await _dbContext.MatchQueues.FirstOrDefaultAsync(m => m.UserId.Equals(userId));

        if (existingEntry != null)
        {
            await Clients.Caller.SendAsync("OnQueueJoined", new { message = "Already in queue" });
            return;
        }

        var queueEntry = new MatchQueue
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Elo = user.Elo,
            QueuedAt = DateTime.UtcNow,
            ConnectionId = Context.ConnectionId
        };

        _dbContext.MatchQueues.Add(queueEntry);
        await _dbContext.SaveChangesAsync();

        await Clients.Caller.SendAsync("OnQueueJoined", new { message = "Joined queue" });

        await TryMatch(queueEntry);
    }

    public async Task LeaveQueue()
    {
        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
        {
            return;
        }

        var queueEntry = await _dbContext.MatchQueues
            .FirstOrDefaultAsync(m => m.UserId.Equals(userId));

        if (queueEntry != null)
        {
            _dbContext.MatchQueues.Remove(queueEntry);
            await _dbContext.SaveChangesAsync();
        }

        await Clients.Caller.SendAsync("OnQueueLeft", new { message = "Left queue" });
    }

    private async Task TryMatch(MatchQueue entry)
    {
        var waitTime = (DateTime.UtcNow - entry.QueuedAt).TotalSeconds;
        var eloRange = Math.Min(EloRangeBase + (int)(waitTime / 10) * EloRangeIncrement, MaxEloRange);

        var opponent = await _dbContext.MatchQueues
            .Where(m => m.UserId != entry.UserId)
            .Where(m => Math.Abs(m.Elo - entry.Elo) <= eloRange)
            .OrderBy(m => m.QueuedAt)
            .FirstOrDefaultAsync();

        if (opponent == null)
        {
            return;
        }

        _dbContext.MatchQueues.Remove(entry);
        _dbContext.MatchQueues.Remove(opponent);

        var blackPlayer = entry.Elo >= opponent.Elo ? opponent : entry;
        var whitePlayer = entry.Elo >= opponent.Elo ? entry : opponent;

        var game = new Arena.Models.Entities.Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = blackPlayer.UserId,
            WhitePlayerId = whitePlayer.UserId,
            Status = GameStatus.InProgress,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Games.Add(game);
        await _dbContext.SaveChangesAsync();

        var blackUser = await _dbContext.Users.FindAsync(blackPlayer.UserId);
        var whiteUser = await _dbContext.Users.FindAsync(whitePlayer.UserId);

        if (!string.IsNullOrEmpty(blackPlayer.ConnectionId))
        {
            await Clients.Client(blackPlayer.ConnectionId).SendAsync("OnMatchFound", new
            {
                gameId = game.Id,
                opponentName = whiteUser?.DisplayName,
                opponentElo = whiteUser?.Elo,
                yourColor = "black"
            });
        }

        if (!string.IsNullOrEmpty(whitePlayer.ConnectionId))
        {
            await Clients.Client(whitePlayer.ConnectionId).SendAsync("OnMatchFound", new
            {
                gameId = game.Id,
                opponentName = blackUser?.DisplayName,
                opponentElo = blackUser?.Elo,
                yourColor = "white"
            });
        }
    }

    string? GetUserId() => Context.User?.FindFirst("sub")?.Value;
}