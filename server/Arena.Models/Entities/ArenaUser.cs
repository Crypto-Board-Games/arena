using Microsoft.AspNetCore.Identity;

using System.ComponentModel.DataAnnotations;

namespace Arena.Models.Entities;

public class ArenaUser : IdentityUser
{
    [StringLength(0x20)]
    public string? LoginProvider
    {
        get; set;
    }

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