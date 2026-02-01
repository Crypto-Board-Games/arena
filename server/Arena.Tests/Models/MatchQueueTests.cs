using Arena.Models.Entities;

namespace Arena.Tests.Models;

public class MatchQueueTests
{
    [Fact]
    public void MatchQueue_Properties_CanBeSet()
    {
        var queueId = Guid.NewGuid();
        var userId = Guid.NewGuid().ToString();
        var queuedAt = DateTime.UtcNow;
        var connectionId = "connection123";

        var queue = new MatchQueue
        {
            Id = queueId,
            UserId = userId,
            Elo = 1500,
            QueuedAt = queuedAt,
            ConnectionId = connectionId
        };

        Assert.Equal(queueId, queue.Id);
        Assert.Equal(userId, queue.UserId);
        Assert.Equal(1500, queue.Elo);
        Assert.Equal(queuedAt, queue.QueuedAt);
        Assert.Equal(connectionId, queue.ConnectionId);
    }

    [Fact]
    public void MatchQueue_ConnectionId_CanBeNull()
    {
        var queue = new MatchQueue
        {
            Id = Guid.NewGuid(),
            UserId = Guid.NewGuid().ToString(),
            Elo = 1200,
            QueuedAt = DateTime.UtcNow
        };

        Assert.Null(queue.ConnectionId);
    }

    [Fact]
    public void MatchQueue_RequiredProperties_AreSet()
    {
        var userId = Guid.NewGuid().ToString();
        var queuedAt = DateTime.UtcNow;

        var queue = new MatchQueue
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Elo = 1300,
            QueuedAt = queuedAt
        };

        Assert.NotEqual(Guid.Empty, queue.Id);
        Assert.NotEqual(Guid.Empty.ToString(), queue.UserId);
        Assert.True(queue.Elo > 0);
        Assert.NotEqual(default, queue.QueuedAt);
    }
}