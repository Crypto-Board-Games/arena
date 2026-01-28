using Xunit;
using Arena.Models.Entities;

namespace Arena.Tests.Models;

public class UserTests
{
    [Fact]
    public void User_DefaultValues_AreCorrect()
    {
        // Arrange & Act
        var user = new User
        {
            Id = Guid.NewGuid(),
            GoogleId = "google123",
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
        var user = new User();
        var now = DateTime.UtcNow;

        // Act
        user.Id = Guid.NewGuid();
        user.GoogleId = "google456";
        user.Email = "user@test.com";
        user.DisplayName = "Player";
        user.Elo = 1500;
        user.Wins = 10;
        user.Losses = 5;
        user.CreatedAt = now;
        user.LastPlayedAt = now;

        // Assert
        Assert.NotEqual(Guid.Empty, user.Id);
        Assert.Equal("google456", user.GoogleId);
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
        var user = new User
        {
            Id = Guid.NewGuid(),
            GoogleId = "google789",
            Email = "required@test.com",
            DisplayName = "Required Test",
            CreatedAt = DateTime.UtcNow
        };

        // Assert
        Assert.NotNull(user.GoogleId);
        Assert.NotNull(user.Email);
        Assert.NotNull(user.DisplayName);
    }
}
