using Xunit;
using Arena.Models.Entities;

namespace Arena.Tests.Models;

public class GameTests
{
    [Fact]
    public void Game_DefaultStatus_IsInProgress()
    {
        var game = new Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = Guid.NewGuid(),
            WhitePlayerId = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow
        };

        Assert.Equal(GameStatus.InProgress, game.Status);
    }

    [Fact]
    public void Game_Properties_CanBeSet()
    {
        var gameId = Guid.NewGuid();
        var blackId = Guid.NewGuid();
        var whiteId = Guid.NewGuid();
        var winnerId = Guid.NewGuid();
        var createdAt = DateTime.UtcNow;
        var endedAt = DateTime.UtcNow.AddMinutes(30);
        var boardState = "{\"board\":[[0,0,0]]}";

        var game = new Game
        {
            Id = gameId,
            BlackPlayerId = blackId,
            WhitePlayerId = whiteId,
            WinnerId = winnerId,
            Status = GameStatus.Completed,
            CurrentBoardState = boardState,
            CreatedAt = createdAt,
            EndedAt = endedAt
        };

        Assert.Equal(gameId, game.Id);
        Assert.Equal(blackId, game.BlackPlayerId);
        Assert.Equal(whiteId, game.WhitePlayerId);
        Assert.Equal(winnerId, game.WinnerId);
        Assert.Equal(GameStatus.Completed, game.Status);
        Assert.Equal(boardState, game.CurrentBoardState);
        Assert.Equal(createdAt, game.CreatedAt);
        Assert.Equal(endedAt, game.EndedAt);
    }

    [Fact]
    public void Game_WinnerId_CanBeNull()
    {
        var game = new Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = Guid.NewGuid(),
            WhitePlayerId = Guid.NewGuid(),
            Status = GameStatus.InProgress,
            CreatedAt = DateTime.UtcNow
        };

        Assert.Null(game.WinnerId);
        Assert.Null(game.EndedAt);
    }

    [Fact]
    public void GameStatus_HasCorrectValues()
    {
        Assert.Equal(0, (int)GameStatus.InProgress);
        Assert.Equal(1, (int)GameStatus.Completed);
        Assert.Equal(2, (int)GameStatus.Abandoned);
    }

    [Fact]
    public void Game_CurrentBoardState_CanBeNull()
    {
        var game = new Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = Guid.NewGuid(),
            WhitePlayerId = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow
        };

        Assert.Null(game.CurrentBoardState);
    }
}
