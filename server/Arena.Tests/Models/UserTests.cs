using Arena.Models.Entities;

namespace Arena.Tests.Models;

public class UserTests
{
    [Fact]
    public void User_DefaultValues_AreCorrect()
    {
        // Arrange & Act
        var user = new ArenaUser
        {
            Id = Guid.NewGuid().ToString(),
            Email = "test@example.com",
            DisplayName = "Test User",
            CreatedAt = DateTime.UtcNow
        };

        // Assert
        Assert.Equal(1200, user.Elo);
        Assert.Equal(0, user.Wins);
        Assert.Equal(0, user.Losses);
        Assert.Null(user.LastPlayedAt);
    }

    [Fact]
    public void User_Properties_CanBeSet()
    {
        // Arrange
        var user = new ArenaUser
        {
            DisplayName = "Player"
        };
        var now = DateTime.UtcNow;

        // Act
        user.Id = Guid.NewGuid().ToString();
        user.Email = "user@test.com";
        user.Elo = 1500;
        user.Wins = 10;
        user.Losses = 5;
        user.CreatedAt = now;
        user.LastPlayedAt = now;

        // Assert
        Assert.NotEqual(Guid.Empty.ToString(), user.Id);
        Assert.Equal("user@test.com", user.Email);
        Assert.Equal("Player", user.DisplayName);
        Assert.Equal(1500, user.Elo);
        Assert.Equal(10, user.Wins);
        Assert.Equal(5, user.Losses);
        Assert.Equal(now, user.CreatedAt);
        Assert.Equal(now, user.LastPlayedAt);
    }

    [Fact]
    public void User_RequiredProperties_CannotBeNull()
    {
        // Arrange & Act
        var user = new ArenaUser
        {
            Id = Guid.NewGuid().ToString(),
            Email = "required@test.com",
            DisplayName = "Required Test",
            CreatedAt = DateTime.UtcNow
        };

        // Assert
        Assert.NotNull(user.Email);
        Assert.NotNull(user.DisplayName);
    }
}
