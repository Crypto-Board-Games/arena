using Arena.Models;
using Arena.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Hubs;

[Authorize]
public class MatchmakingHub : Hub
{
    private readonly ArenaDbContext _dbContext;

    public MatchmakingHub(ArenaDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId.HasValue)
        {
            var queueEntry = await _dbContext.MatchQueues
                .FirstOrDefaultAsync(m => m.UserId == userId.Value);
            
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
        if (!userId.HasValue)
        {
            await Clients.Caller.SendAsync("OnError", new { code = "auth_failed", message = "Authentication required" });
            return;
        }

        var user = await _dbContext.Users.FindAsync(userId.Value);
        if (user == null)
        {
            await Clients.Caller.SendAsync("OnError", new { code = "auth_failed", message = "Authentication required" });
            return;
        }

        var existingEntry = await _dbContext.MatchQueues
            .FirstOrDefaultAsync(m => m.UserId == userId.Value);
        
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
            UserId = userId.Value,
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
        if (!userId.HasValue)
        {
            return;
        }

        var queueEntry = await _dbContext.MatchQueues
            .FirstOrDefaultAsync(m => m.UserId == userId.Value);
        
        if (queueEntry != null)
        {
            _dbContext.MatchQueues.Remove(queueEntry);
            await _dbContext.SaveChangesAsync();
        }
    }

    private Guid? GetUserId()
    {
        var userIdClaim = Context.User?.FindFirst("sub")?.Value;
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return null;
    }
}
