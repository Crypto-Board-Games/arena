using Arena.Server.Core;

namespace Arena.Server.Services;

public class EloCalculator : IEloCalculator
{
    private const int KFactor = 32;

    public (int winnerNewElo, int loserNewElo, int winnerChange, int loserChange) Calculate(int winnerElo, int loserElo)
    {
        double expectedWinner = 1.0 / (1.0 + Math.Pow(10, (loserElo - winnerElo) / 400.0));
        double expectedLoser = 1.0 / (1.0 + Math.Pow(10, (winnerElo - loserElo) / 400.0));

        int winnerChange = (int)Math.Round(KFactor * (1.0 - expectedWinner));
        int loserChange = (int)Math.Round(KFactor * (0.0 - expectedLoser));

        int winnerNewElo = winnerElo + winnerChange;
        int loserNewElo = loserElo + loserChange;

        return (winnerNewElo, loserNewElo, winnerChange, loserChange);
    }
}