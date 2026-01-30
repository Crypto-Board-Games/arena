using Arena.Models;
using Arena.Models.Entities;
using Arena.Server.Core;
using Arena.Server.Models;

using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

using System.Collections.Concurrent;

namespace Arena.Server.Hubs;

public class GameHub(ArenaDbContext dbContext, IEloCalculator eloCalculator, ConcurrentDictionary<Guid, GameSession> gameSessions, ConcurrentDictionary<string, string> connectionUserMap) : Hub
{
    private const int TurnTimeSeconds = 30;
    private const int DisconnectGraceSeconds = 30;

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();

        if (!string.IsNullOrEmpty(userId))
        {
            connectionUserMap[Context.ConnectionId] = userId;
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();

        connectionUserMap.TryRemove(Context.ConnectionId, out _);

        if (!string.IsNullOrEmpty(userId))
        {
            foreach (var session in gameSessions.Values.Where(s => !s.IsGameEnded && (userId.Equals(s.BlackPlayerId) || userId.Equals(s.WhitePlayerId))))
            {
                session.DisconnectedPlayerId = userId;

                await Clients.Group(session.GameId.ToString())
                    .SendAsync("OnOpponentDisconnected", new { gracePeriodSeconds = DisconnectGraceSeconds });

                session.DisconnectGraceTimer = new Timer(
                    async _ => await HandleDisconnectTimeout(session.GameId, userId),
                    null,
                    DisconnectGraceSeconds * 1000,
                    Timeout.Infinite);
            }
        }

        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinGame(string gameIdStr)
    {
        if (!Guid.TryParse(gameIdStr, out var gameId))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x = -1, y = -1, reason = "game_not_found" });
            return;
        }

        var game = await dbContext.Games.FindAsync(gameId);
        if (game == null)
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x = -1, y = -1, reason = "game_not_found" });
            return;
        }

        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId) || !game.BlackPlayerId.Equals(userId) && !game.WhitePlayerId.Equals(userId))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x = -1, y = -1, reason = "game_not_found" });

            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, gameIdStr);

        var session = gameSessions.GetOrAdd(gameId, _ => CreateSession(game));

        if (userId.Equals(session.DisconnectedPlayerId))
        {
            session.DisconnectedPlayerId = null;
            session.DisconnectGraceTimer?.Dispose();
            session.DisconnectGraceTimer = null;

            await Clients.OthersInGroup(gameIdStr).SendAsync("OnOpponentReconnected", new { });

            var yourColor = userId == session.BlackPlayerId ? "black" : "white";
            var currentTurn = session.CurrentTurnPlayerId == session.BlackPlayerId ? "black" : "white";
            await Clients.Caller.SendAsync("OnGameResumed", new
            {
                board = FlattenBoard(session.Board),
                yourColor,
                currentTurn,
                remainingSeconds = session.RemainingSeconds,
                opponentConnected = true
            });
            return;
        }

        var color = userId == session.BlackPlayerId ? "black" : "white";
        await Clients.Caller.SendAsync("OnGameStarted", new
        {
            gameId = gameIdStr,
            blackPlayerId = session.BlackPlayerId,
            whitePlayerId = session.WhitePlayerId,
            yourColor = color
        });

        if (session.TurnTimer == null && !session.IsGameEnded)
        {
            StartTurnTimer(session);
        }
    }

    public async Task PlaceStone(string gameIdStr, int x, int y)
    {
        if (!Guid.TryParse(gameIdStr, out var gameId) || !gameSessions.TryGetValue(gameId, out var session))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "game_not_found" });
            return;
        }

        if (session.IsGameEnded)
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "game_already_ended" });
            return;
        }

        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "not_your_turn" });

            return;
        }

        if (!userId.Equals(session.CurrentTurnPlayerId))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "not_your_turn" });

            return;
        }

        if (x < 0 || x >= 15 || y < 0 || y >= 15)
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "out_of_bounds" });
            return;
        }

        if (session.Board[y, x] != 0)
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = "occupied" });
            return;
        }

        var color = session.GetColorByPlayerId(userId);

        var rejection = ValidateMove(session.Board, x, y, color);

        if (rejection != null)
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x, y, reason = rejection });
            return;
        }

        session.Board[y, x] = color;
        session.TurnTimer?.Dispose();
        session.RemainingSeconds = TurnTimeSeconds;

        var colorStr = color == 1 ? "black" : "white";
        await Clients.Group(gameIdStr).SendAsync("OnMoveMade", new
        {
            x,
            y,
            color = colorStr,
            remainingTime = session.RemainingSeconds
        });

        await SaveBoardState(gameId, session);

        if (CheckWin(session.Board, x, y, color))
        {
            await EndGame(session, userId, "five_in_row");
            return;
        }

        session.CurrentTurnPlayerId = session.GetOpponentId(userId);
        StartTurnTimer(session);
    }

    public async Task Resign(string gameIdStr)
    {
        if (!Guid.TryParse(gameIdStr, out var gameId) || !gameSessions.TryGetValue(gameId, out var session))
        {
            await Clients.Caller.SendAsync("OnMoveRejected", new { x = -1, y = -1, reason = "game_not_found" });
            return;
        }

        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
        {
            return;
        }

        var winnerId = session.GetOpponentId(userId);

        await EndGame(session, winnerId, "resign");
    }

    private static GameSession CreateSession(Arena.Models.Entities.Game game)
    {
        var session = new GameSession
        {
            GameId = game.Id,
            BlackPlayerId = game.BlackPlayerId,
            WhitePlayerId = game.WhitePlayerId,
            CurrentTurnPlayerId = game.BlackPlayerId,
            RemainingSeconds = TurnTimeSeconds
        };

        if (!string.IsNullOrEmpty(game.CurrentBoardState))
        {
            session.DeserializeBoard(game.CurrentBoardState);
        }

        return session;
    }

    private void StartTurnTimer(GameSession session)
    {
        session.TurnTimer?.Dispose();
        session.RemainingSeconds = TurnTimeSeconds;

        session.TurnTimer = new Timer(
            async _ => await TimerTick(session.GameId),
            null,
            1000,
            1000);
    }

    private async Task TimerTick(Guid gameId)
    {
        if (!gameSessions.TryGetValue(gameId, out var session) || session.IsGameEnded)
        {
            return;
        }

        session.RemainingSeconds--;

        var currentPlayer = session.CurrentTurnPlayerId == session.BlackPlayerId ? "black" : "white";
        await Clients.Group(gameId.ToString()).SendAsync("OnTimerUpdate", new
        {
            currentPlayer,
            remainingSeconds = session.RemainingSeconds
        });

        if (session.RemainingSeconds <= 0)
        {
            session.TurnTimer?.Dispose();
            var winnerId = session.GetOpponentId(session.CurrentTurnPlayerId);
            await EndGame(session, winnerId, "timeout");
        }
    }

    private async Task HandleDisconnectTimeout(Guid gameId, string disconnectedUserId)
    {
        if (!gameSessions.TryGetValue(gameId, out var session) || session.IsGameEnded)
        {
            return;
        }

        if (session.DisconnectedPlayerId == disconnectedUserId)
        {
            var winnerId = session.GetOpponentId(disconnectedUserId);
            await EndGame(session, winnerId, "disconnect");
        }
    }

    private async Task EndGame(GameSession session, string winnerId, string reason)
    {
        if (session.IsGameEnded)
        {
            return;
        }

        session.IsGameEnded = true;
        session.WinnerId = winnerId;
        session.EndReason = reason;
        session.TurnTimer?.Dispose();
        session.DisconnectGraceTimer?.Dispose();

        var loserId = session.GetOpponentId(winnerId);

        var winner = await dbContext.Users.FindAsync(winnerId);
        var loser = await dbContext.Users.FindAsync(loserId);
        var game = await dbContext.Games.FindAsync(session.GameId);

        if (winner != null && loser != null && game != null)
        {
            var (winnerNewElo, loserNewElo, winnerChange, loserChange) =
                eloCalculator.Calculate(winner.Elo, loser.Elo);

            winner.Elo = winnerNewElo;
            winner.Wins++;
            winner.LastPlayedAt = DateTime.UtcNow;

            loser.Elo = loserNewElo;
            loser.Losses++;
            loser.LastPlayedAt = DateTime.UtcNow;

            game.WinnerId = winnerId;
            game.Status = GameStatus.Completed;
            game.EndedAt = DateTime.UtcNow;
            game.CurrentBoardState = null;

            await dbContext.SaveChangesAsync();

            await Clients.Group(session.GameId.ToString()).SendAsync("OnGameEnded", new
            {
                winnerId,
                reason,
                eloChange = new
                {
                    winner = winnerChange,
                    loser = loserChange
                }
            });
        }
    }

    private async Task SaveBoardState(Guid gameId, GameSession session)
    {
        var game = await dbContext.Games.FindAsync(gameId);
        if (game != null)
        {
            game.CurrentBoardState = session.SerializeBoard();
            await dbContext.SaveChangesAsync();
        }
    }

    private string? GetUserId()
    {
        var userIdClaim = Context.User?.FindFirst("sub")?.Value;

        if (!string.IsNullOrEmpty(userIdClaim))
        {
            return userIdClaim;
        }

        if (connectionUserMap.TryGetValue(Context.ConnectionId, out var mappedUserId))
        {
            return mappedUserId;
        }

        return null;
    }

    private static string? ValidateMove(int[,] board, int x, int y, int color)
    {
        if (color != 1)
        {
            return null;
        }

        var testBoard = (int[,])board.Clone();
        testBoard[y, x] = color;

        if (HasOverline(testBoard, x, y, color))
        {
            return "forbidden_overline";
        }

        if (HasExactFive(testBoard, x, y, color))
        {
            return null;
        }

        if (CountOpenThrees(testBoard, x, y) >= 2)
        {
            return "forbidden_33";
        }

        if (CountFours(testBoard, x, y) >= 2)
        {
            return "forbidden_44";
        }

        return null;
    }

    private static bool CheckWin(int[,] board, int x, int y, int color)
    {
        if (color == 1)
        {
            return HasExactFive(board, x, y, color);
        }
        return HasFiveOrMore(board, x, y, color);
    }

    private static readonly (int dx, int dy)[] Directions = [(1, 0), (0, 1), (1, 1), (1, -1)];

    private static bool HasOverline(int[,] board, int x, int y, int color)
    {
        foreach (var (dx, dy) in Directions)
        {
            if (CountConsecutive(board, x, y, dx, dy, color) >= 6)
            {
                return true;
            }
        }
        return false;
    }

    private static bool HasExactFive(int[,] board, int x, int y, int color)
    {
        foreach (var (dx, dy) in Directions)
        {
            if (CountConsecutive(board, x, y, dx, dy, color) == 5)
            {
                return true;
            }
        }
        return false;
    }

    private static bool HasFiveOrMore(int[,] board, int x, int y, int color)
    {
        foreach (var (dx, dy) in Directions)
        {
            if (CountConsecutive(board, x, y, dx, dy, color) >= 5)
            {
                return true;
            }
        }
        return false;
    }

    private static int CountConsecutive(int[,] board, int x, int y, int dx, int dy, int color)
    {
        return 1 + CountDirection(board, x, y, dx, dy, color) + CountDirection(board, x, y, -dx, -dy, color);
    }

    private static int CountDirection(int[,] board, int x, int y, int dx, int dy, int color)
    {
        int count = 0;
        int cx = x + dx;
        int cy = y + dy;
        while (cx >= 0 && cx < 15 && cy >= 0 && cy < 15 && board[cy, cx] == color)
        {
            count++;
            cx += dx;
            cy += dy;
        }
        return count;
    }

    private static int CountOpenThrees(int[,] board, int x, int y)
    {
        int count = 0;
        foreach (var (dx, dy) in Directions)
        {
            if (HasOpenThree(board, x, y, dx, dy))
            {
                count++;
            }
        }
        return count;
    }

    private static bool HasOpenThree(int[,] board, int x, int y, int dx, int dy)
    {
        var line = GetLine(board, x, y, dx, dy);
        string[] patterns = [".BBB.", ".BB.B.", ".B.BB."];

        foreach (var pattern in patterns)
        {
            if (HasPattern(line, pattern, 4))
            {
                return true;
            }
        }
        return false;
    }

    private static int CountFours(int[,] board, int x, int y)
    {
        int count = 0;
        foreach (var (dx, dy) in Directions)
        {
            if (HasFour(board, x, y, dx, dy))
            {
                count++;
            }
        }
        return count;
    }

    private static bool HasFour(int[,] board, int x, int y, int dx, int dy)
    {
        var line = GetLine(board, x, y, dx, dy);

        for (int start = 0; start <= line.Length - 4; start++)
        {
            if (4 < start || 4 > start + 3)
            {
                continue;
            }

            bool isMatch = true;
            for (int i = 0; i < 4; i++)
            {
                if (line[start + i] != 'B')
                {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch)
            {
                return true;
            }
        }

        for (int start = 0; start <= line.Length - 5; start++)
        {
            if (4 < start || 4 > start + 4)
            {
                continue;
            }

            int blackCount = 0;
            bool blocked = false;
            for (int i = 0; i < 5; i++)
            {
                char cell = line[start + i];
                if (cell == 'W')
                {
                    blocked = true;
                    break;
                }
                if (cell == 'B')
                {
                    blackCount++;
                }
            }
            if (!blocked && blackCount == 4)
            {
                return true;
            }
        }

        return false;
    }

    private static char[] GetLine(int[,] board, int x, int y, int dx, int dy)
    {
        var line = new char[9];
        for (int offset = -4; offset <= 4; offset++)
        {
            int cx = x + offset * dx;
            int cy = y + offset * dy;
            line[offset + 4] = CellToChar(board, cx, cy);
        }
        return line;
    }

    private static char CellToChar(int[,] board, int x, int y)
    {
        if (x < 0 || x >= 15 || y < 0 || y >= 15)
        {
            return 'W';
        }
        int cell = board[y, x];
        return cell == 0 ? '.' : (cell == 1 ? 'B' : 'W');
    }

    private static bool HasPattern(char[] line, string pattern, int centerIndex)
    {
        for (int start = 0; start <= line.Length - pattern.Length; start++)
        {
            if (centerIndex < start || centerIndex > start + pattern.Length - 1)
            {
                continue;
            }

            bool matches = true;
            for (int i = 0; i < pattern.Length; i++)
            {
                if (line[start + i] != pattern[i])
                {
                    matches = false;
                    break;
                }
            }
            if (matches)
            {
                return true;
            }
        }
        return false;
    }

    private static int[] FlattenBoard(int[,] board)
    {
        var flat = new int[15 * 15];
        for (int i = 0; i < 15; i++)
        {
            for (int j = 0; j < 15; j++)
            {
                flat[i * 15 + j] = board[i, j];
            }
        }
        return flat;
    }
}
