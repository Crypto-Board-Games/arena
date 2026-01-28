namespace Arena.Server.Models;

public class GameSession
{
    public Guid GameId { get; set; }
    public int[,] Board { get; set; } = new int[15, 15];
    public Guid CurrentTurnPlayerId { get; set; }
    public Guid BlackPlayerId { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Timer? TurnTimer { get; set; }
    public int RemainingSeconds { get; set; } = 30;
    public Guid? DisconnectedPlayerId { get; set; }
    public Timer? DisconnectGraceTimer { get; set; }
    public bool IsGameEnded { get; set; }
    public Guid? WinnerId { get; set; }
    public string? EndReason { get; set; }

    public Guid GetPlayerIdByColor(int color) => color == 1 ? BlackPlayerId : WhitePlayerId;

    public int GetColorByPlayerId(Guid playerId) => playerId == BlackPlayerId ? 1 : 2;

    public Guid GetOpponentId(Guid playerId) => playerId == BlackPlayerId ? WhitePlayerId : BlackPlayerId;

    public string SerializeBoard()
    {
        var flatBoard = new int[15 * 15];
        for (int i = 0; i < 15; i++)
        {
            for (int j = 0; j < 15; j++)
            {
                flatBoard[i * 15 + j] = Board[i, j];
            }
        }
        return System.Text.Json.JsonSerializer.Serialize(flatBoard);
    }

    public void DeserializeBoard(string json)
    {
        var flatBoard = System.Text.Json.JsonSerializer.Deserialize<int[]>(json);
        if (flatBoard != null && flatBoard.Length == 15 * 15)
        {
            for (int i = 0; i < 15; i++)
            {
                for (int j = 0; j < 15; j++)
                {
                    Board[i, j] = flatBoard[i * 15 + j];
                }
            }
        }
    }
}
