namespace Arena.Models.Entities;

public enum GameStatus
{
    InProgress = 0,
    Completed = 1,
    Abandoned = 2
}

public class Game
{
    public Guid Id { get; set; }
    public Guid BlackPlayerId { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Guid? WinnerId { get; set; }
    public GameStatus Status { get; set; } = GameStatus.InProgress;
    public string? CurrentBoardState { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? EndedAt { get; set; }
}
