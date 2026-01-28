namespace Arena.Models.Entities;

public class User
{
    public Guid Id { get; set; }
    public string GoogleId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int Elo { get; set; } = 1200;
    public int Wins { get; set; } = 0;
    public int Losses { get; set; } = 0;
    public DateTime CreatedAt { get; set; }
    public DateTime? LastPlayedAt { get; set; }
}
