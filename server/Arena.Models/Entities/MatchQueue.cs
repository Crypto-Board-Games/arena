namespace Arena.Models.Entities;

public class MatchQueue
{
    public Guid Id { get; set; }

    public required string UserId
    {
        get; set;
    }

    public int Elo { get; set; }
    public DateTime QueuedAt { get; set; }
    public string? ConnectionId { get; set; }
}
