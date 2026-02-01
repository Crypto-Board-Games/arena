using Arena.Models;
using Arena.Models.Entities;

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Hubs;

[Authorize]
public class MatchmakingHub(ArenaDbContext dbContext) : Hub
{
    private readonly ArenaDbContext _dbContext;

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

    public async Task JoinMatchmaking()
    {
        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
        {
            await Clients.Caller.SendAsync("OnError", new { code = "auth_failed", message = "Authentication required" });
            return;
        }

        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
        {
            await Clients.Caller.SendAsync("OnError", new { code = "auth_failed", message = "Authentication required" });
            return;
        }

        var existingEntry = await _dbContext.MatchQueues.FirstOrDefaultAsync(m => m.UserId.Equals(userId));

        if (existingEntry != null)
        {
            existingEntry.ConnectionId = Context.ConnectionId;
            existingEntry.Elo = user.Elo;
            await _dbContext.SaveChangesAsync();
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
    }

    public async Task LeaveMatchmaking()
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
    }

    string? GetUserId() => Context.User?.FindFirst("sub")?.Value;
}