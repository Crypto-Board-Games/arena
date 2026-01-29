using Microsoft.AspNetCore.Identity;

namespace Arena.Models.Entities;

public class ArenaUser : IdentityUser
{
    public required string DisplayName
    {
        get; set;
    }

    public int Elo { get; set; } = 1200;

    public int Wins
    {
        get; set;
    }

    public int Losses
    {
        get; set;
    }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastPlayedAt { get; set; }
}