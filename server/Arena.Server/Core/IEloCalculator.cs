namespace Arena.Server.Core;

public interface IEloCalculator
{
    (int winnerNewElo, int loserNewElo, int winnerChange, int loserChange) Calculate(int winnerElo, int loserElo);
}