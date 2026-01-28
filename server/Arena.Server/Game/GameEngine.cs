namespace Arena.Server.Game;

public enum StoneColor
{
    Empty = 0,
    Black = 1,
    White = 2
}

public sealed class GameEngine
{
    public const int BoardSize = 15;

    private static readonly (int dx, int dy)[] Directions =
    {
        (1, 0),
        (0, 1),
        (1, 1),
        (1, -1)
    };

    // Open three patterns with empty ends (including broken threes).
    private static readonly string[] OpenThreePatterns =
    {
        ".BBB.",
        ".BB.B.",
        ".B.BB."
    };

    private readonly StoneColor[,] _board = new StoneColor[BoardSize, BoardSize];

    public StoneColor CurrentTurn { get; private set; } = StoneColor.Black;

    public StoneColor? Winner { get; private set; }

    public StoneColor GetStone(int row, int col)
    {
        if (!IsInBounds(row, col))
        {
            throw new ArgumentOutOfRangeException(nameof(row), "Position is outside the board.");
        }

        return _board[row, col];
    }

    public bool TryPlaceStone(int row, int col)
    {
        if (!IsInBounds(row, col))
        {
            return false;
        }

        if (Winner.HasValue)
        {
            return false;
        }

        if (_board[row, col] != StoneColor.Empty)
        {
            return false;
        }

        var color = CurrentTurn;
        _board[row, col] = color;

        if (color == StoneColor.Black)
        {
            // Renju ordering for black: overline is always forbidden, exact five wins, then 3-3/4-4.
            if (HasOverline(row, col, color))
            {
                _board[row, col] = StoneColor.Empty;
                return false;
            }

            if (HasWinningLine(row, col, color, exactFive: true))
            {
                Winner = color;
                return true;
            }

            if (CountOpenThrees(row, col) >= 2)
            {
                _board[row, col] = StoneColor.Empty;
                return false;
            }

            if (CountFours(row, col) >= 2)
            {
                _board[row, col] = StoneColor.Empty;
                return false;
            }
        }
        else
        {
            if (HasWinningLine(row, col, color, exactFive: false))
            {
                Winner = color;
                return true;
            }
        }

        CurrentTurn = color == StoneColor.Black ? StoneColor.White : StoneColor.Black;
        return true;
    }

    private static bool IsInBounds(int row, int col)
    {
        return row >= 0 && row < BoardSize && col >= 0 && col < BoardSize;
    }

    private bool HasOverline(int row, int col, StoneColor color)
    {
        foreach (var (dx, dy) in Directions)
        {
            if (CountConsecutive(row, col, dx, dy, color) >= 6)
            {
                return true;
            }
        }

        return false;
    }

    private bool HasWinningLine(int row, int col, StoneColor color, bool exactFive)
    {
        foreach (var (dx, dy) in Directions)
        {
            var count = CountConsecutive(row, col, dx, dy, color);
            if (exactFive ? count == 5 : count >= 5)
            {
                return true;
            }
        }

        return false;
    }

    private int CountConsecutive(int row, int col, int dx, int dy, StoneColor color)
    {
        return 1 + CountDirection(row, col, dx, dy, color) + CountDirection(row, col, -dx, -dy, color);
    }

    private int CountDirection(int row, int col, int dx, int dy, StoneColor color)
    {
        var count = 0;
        var r = row + dy;
        var c = col + dx;

        while (IsInBounds(r, c) && _board[r, c] == color)
        {
            count++;
            r += dy;
            c += dx;
        }

        return count;
    }

    private int CountOpenThrees(int row, int col)
    {
        var count = 0;

        foreach (var (dx, dy) in Directions)
        {
            if (HasOpenThree(row, col, dx, dy))
            {
                count++;
            }
        }

        return count;
    }

    private bool HasOpenThree(int row, int col, int dx, int dy)
    {
        var line = GetLine(row, col, dx, dy, StoneColor.Black);
        const int centerIndex = 4;

        foreach (var pattern in OpenThreePatterns)
        {
            if (HasPattern(line, pattern, centerIndex))
            {
                return true;
            }
        }

        return false;
    }

    private int CountFours(int row, int col)
    {
        var count = 0;

        foreach (var (dx, dy) in Directions)
        {
            if (HasFour(row, col, dx, dy))
            {
                count++;
            }
        }

        return count;
    }

    private bool HasFour(int row, int col, int dx, int dy)
    {
        var line = GetLine(row, col, dx, dy, StoneColor.Black);
        const int centerIndex = 4;

        if (HasStraightFour(line, centerIndex))
        {
            return true;
        }

        return HasBrokenFour(line, centerIndex);
    }

    private static bool HasStraightFour(char[] line, int centerIndex)
    {
        const int length = 4;
        for (var start = 0; start <= line.Length - length; start++)
        {
            if (centerIndex < start || centerIndex > start + length - 1)
            {
                continue;
            }

            var isMatch = true;
            for (var i = 0; i < length; i++)
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

        return false;
    }

    private static bool HasBrokenFour(char[] line, int centerIndex)
    {
        const int length = 5;
        for (var start = 0; start <= line.Length - length; start++)
        {
            if (centerIndex < start || centerIndex > start + length - 1)
            {
                continue;
            }

            var blackCount = 0;
            var blocked = false;
            for (var i = 0; i < length; i++)
            {
                var cell = line[start + i];
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

    private static bool HasPattern(char[] line, string pattern, int centerIndex)
    {
        for (var start = 0; start <= line.Length - pattern.Length; start++)
        {
            if (centerIndex < start || centerIndex > start + pattern.Length - 1)
            {
                continue;
            }

            var matches = true;
            for (var i = 0; i < pattern.Length; i++)
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

    private char[] GetLine(int row, int col, int dx, int dy, StoneColor color)
    {
        var line = new char[9];

        for (var offset = -4; offset <= 4; offset++)
        {
            var r = row + (offset * dy);
            var c = col + (offset * dx);
            line[offset + 4] = CellToChar(r, c, color);
        }

        return line;
    }

    private char CellToChar(int row, int col, StoneColor color)
    {
        if (!IsInBounds(row, col))
        {
            return 'W';
        }

        var cell = _board[row, col];
        if (cell == StoneColor.Empty)
        {
            return '.';
        }

        return cell == color ? 'B' : 'W';
    }
}
