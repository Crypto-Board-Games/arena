using System.Data;
using Arena.Models;
using Arena.Models.Entities;
using Arena.Server.Hubs;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Arena.Server.Services;

public sealed class MatchmakingService : BackgroundService
{
    private const int BaseRange = 200;
    private const int RangeIncrement = 50;
    private const int RangeIncrementSeconds = 30;
    private const int MatchAnyoneSeconds = 180;

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IHubContext<MatchmakingHub> _hubContext;
    private readonly ILogger<MatchmakingService> _logger;

    public MatchmakingService(
        IServiceScopeFactory scopeFactory,
        IHubContext<MatchmakingHub> hubContext,
        ILogger<MatchmakingService> logger)
    {
        _scopeFactory = scopeFactory;
        _hubContext = hubContext;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var lastStatusBroadcastAt = DateTime.MinValue;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<ArenaDbContext>();

                // Status broadcast every 10 seconds.
                if ((DateTime.UtcNow - lastStatusBroadcastAt).TotalSeconds >= 10)
                {
                    await BroadcastStatus(db, stoppingToken);
                    lastStatusBroadcastAt = DateTime.UtcNow;
                }

                await TryMakeOneMatch(db, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Matchmaking loop error");
            }

            await Task.Delay(TimeSpan.FromSeconds(1), stoppingToken);
        }
    }

    private static int CalculateRangeSeconds(int waitingSeconds)
    {
        var increments = waitingSeconds / RangeIncrementSeconds;
        return BaseRange + (increments * RangeIncrement);
    }

    private async Task BroadcastStatus(ArenaDbContext db, CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var entries = await db.MatchQueues.AsNoTracking().ToListAsync(ct);

        foreach (var entry in entries)
        {
            if (string.IsNullOrEmpty(entry.ConnectionId))
            {
                continue;
            }

            var waitingSeconds = Math.Max(0, (int)Math.Floor((now - entry.QueuedAt).TotalSeconds));
            var currentRange = CalculateRangeSeconds(waitingSeconds);

            await _hubContext.Clients.Client(entry.ConnectionId)
                .SendAsync("OnMatchmakingStatus", new
                {
                    waitingSeconds,
                    currentRange
                }, ct);
        }
    }

    private async Task TryMakeOneMatch(ArenaDbContext db, CancellationToken ct)
    {
        // Serializable transaction to reduce double-matching.
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);

        var now = DateTime.UtcNow;

        // Pick the oldest entry first.
        var entry = await db.MatchQueues
            .OrderBy(m => m.QueuedAt)
            .FirstOrDefaultAsync(ct);

        if (entry == null)
        {
            return;
        }

        var waitingSeconds = Math.Max(0, (int)Math.Floor((now - entry.QueuedAt).TotalSeconds));
        var range = waitingSeconds >= MatchAnyoneSeconds
            ? int.MaxValue
            : CalculateRangeSeconds(waitingSeconds);

        var opponentQuery = db.MatchQueues
            .Where(m => m.UserId != entry.UserId);

        if (range != int.MaxValue)
        {
            opponentQuery = opponentQuery.Where(m => Math.Abs(m.Elo - entry.Elo) <= range);
        }

        var opponent = await opponentQuery
            .OrderBy(m => Math.Abs(m.Elo - entry.Elo))
            .ThenBy(m => m.QueuedAt)
            .FirstOrDefaultAsync(ct);

        if (opponent == null)
        {
            await tx.CommitAsync(ct);
            return;
        }

        db.MatchQueues.Remove(entry);
        db.MatchQueues.Remove(opponent);

        var entryUser = await db.Users.FindAsync([entry.UserId], ct);
        var opponentUser = await db.Users.FindAsync([opponent.UserId], ct);

        // If either user is missing, drop the match and let clients re-queue.
        if (entryUser == null || opponentUser == null)
        {
            await db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            return;
        }

        var entryIsBlack = Random.Shared.Next(2) == 0;
        var blackUserId = entryIsBlack ? entry.UserId : opponent.UserId;
        var whiteUserId = entryIsBlack ? opponent.UserId : entry.UserId;

        var game = new Arena.Models.Entities.Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = blackUserId,
            WhitePlayerId = whiteUserId,
            Status = GameStatus.InProgress,
            CreatedAt = DateTime.UtcNow
        };

        db.Games.Add(game);
        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        await NotifyMatchFound(entry, entryUser, opponent, opponentUser, game, entryIsBlack, ct);
    }

    private async Task NotifyMatchFound(
        MatchQueue entry,
        User entryUser,
        MatchQueue opponent,
        User opponentUser,
        Arena.Models.Entities.Game game,
        bool entryIsBlack,
        CancellationToken ct)
    {
        if (!string.IsNullOrEmpty(entry.ConnectionId))
        {
            await _hubContext.Clients.Client(entry.ConnectionId)
                .SendAsync("OnMatchFound", new
                {
                    gameId = game.Id.ToString(),
                    opponentName = opponentUser.DisplayName,
                    yourColor = entryIsBlack ? "black" : "white"
                }, ct);
        }

        if (!string.IsNullOrEmpty(opponent.ConnectionId))
        {
            await _hubContext.Clients.Client(opponent.ConnectionId)
                .SendAsync("OnMatchFound", new
                {
                    gameId = game.Id.ToString(),
                    opponentName = entryUser.DisplayName,
                    yourColor = entryIsBlack ? "white" : "black"
                }, ct);
        }
    }
}
