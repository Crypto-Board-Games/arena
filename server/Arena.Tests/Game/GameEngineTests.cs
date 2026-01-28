using Xunit;
using Arena.Server.Game;

namespace Arena.Tests.Gameplay;

public class GameEngineTests
{
    [Fact]
    public void EmptyBoard_IsValid()
    {
        var engine = new GameEngine();

        for (var row = 0; row < GameEngine.BoardSize; row++)
        {
            for (var col = 0; col < GameEngine.BoardSize; col++)
            {
                Assert.Equal(StoneColor.Empty, engine.GetStone(row, col));
            }
        }

        Assert.Equal(StoneColor.Black, engine.CurrentTurn);
        Assert.Null(engine.Winner);
    }

    [Fact]
    public void PlaceStone_UpdatesBoard()
    {
        var engine = new GameEngine();

        var placed = engine.TryPlaceStone(7, 7);

        Assert.True(placed);
        Assert.Equal(StoneColor.Black, engine.GetStone(7, 7));
        Assert.Equal(StoneColor.White, engine.CurrentTurn);
    }

    [Fact]
    public void FiveInRow_Horizontal_BlackWins()
    {
        var engine = new GameEngine();

        Place(engine, 7, 3);
        Place(engine, 0, 0);
        Place(engine, 7, 4);
        Place(engine, 0, 1);
        Place(engine, 7, 5);
        Place(engine, 0, 2);
        Place(engine, 7, 6);
        Place(engine, 0, 3);

        var placed = engine.TryPlaceStone(7, 7);

        Assert.True(placed);
        Assert.Equal(StoneColor.Black, engine.Winner);
    }

    [Fact]
    public void DoubleThree_Blocked_ForBlack()
    {
        var engine = new GameEngine();

        Place(engine, 7, 6);
        Place(engine, 0, 0);
        Place(engine, 7, 8);
        Place(engine, 0, 1);
        Place(engine, 6, 7);
        Place(engine, 0, 2);
        Place(engine, 8, 7);
        Place(engine, 0, 3);

        var placed = engine.TryPlaceStone(7, 7);

        Assert.False(placed);
        Assert.Equal(StoneColor.Empty, engine.GetStone(7, 7));
        Assert.Equal(StoneColor.Black, engine.CurrentTurn);
    }

    [Fact]
    public void DoubleFour_Blocked_ForBlack()
    {
        var engine = new GameEngine();

        Place(engine, 7, 5);
        Place(engine, 0, 0);
        Place(engine, 7, 6);
        Place(engine, 1, 2);
        Place(engine, 7, 8);
        Place(engine, 2, 4);
        Place(engine, 5, 7);
        Place(engine, 3, 6);
        Place(engine, 6, 7);
        Place(engine, 4, 8);
        Place(engine, 8, 7);
        Place(engine, 5, 10);

        var placed = engine.TryPlaceStone(7, 7);

        Assert.False(placed);
        Assert.Equal(StoneColor.Empty, engine.GetStone(7, 7));
        Assert.Equal(StoneColor.Black, engine.CurrentTurn);
    }

    [Fact]
    public void Overline_Six_Blocked_ForBlack()
    {
        var engine = new GameEngine();

        Place(engine, 7, 2);
        Place(engine, 0, 0);
        Place(engine, 7, 3);
        Place(engine, 1, 2);
        Place(engine, 7, 4);
        Place(engine, 2, 4);
        Place(engine, 7, 6);
        Place(engine, 3, 6);
        Place(engine, 7, 7);
        Place(engine, 4, 8);
        Place(engine, 7, 8);
        Place(engine, 5, 10);

        var placed = engine.TryPlaceStone(7, 5);

        Assert.False(placed);
        Assert.Equal(StoneColor.Empty, engine.GetStone(7, 5));
        Assert.Equal(StoneColor.Black, engine.CurrentTurn);
    }

    [Fact]
    public void Overline_Six_Allowed_ForWhite()
    {
        var engine = new GameEngine();

        Place(engine, 0, 0);
        Place(engine, 8, 2);
        Place(engine, 1, 2);
        Place(engine, 8, 3);
        Place(engine, 2, 4);
        Place(engine, 8, 4);
        Place(engine, 3, 6);
        Place(engine, 8, 6);
        Place(engine, 4, 8);
        Place(engine, 8, 7);
        Place(engine, 5, 10);
        Place(engine, 8, 8);
        Place(engine, 6, 12);

        var placed = engine.TryPlaceStone(8, 5);

        Assert.True(placed);
        Assert.Equal(StoneColor.White, engine.Winner);
    }

    [Fact]
    public void FiveInRow_OverridesDoubleThree()
    {
        var engine = new GameEngine();

        Place(engine, 7, 3);
        Place(engine, 0, 0);
        Place(engine, 7, 4);
        Place(engine, 1, 2);
        Place(engine, 7, 5);
        Place(engine, 2, 4);
        Place(engine, 7, 6);
        Place(engine, 3, 6);
        Place(engine, 6, 7);
        Place(engine, 4, 8);
        Place(engine, 8, 7);
        Place(engine, 5, 10);
        Place(engine, 6, 6);
        Place(engine, 6, 12);
        Place(engine, 8, 8);
        Place(engine, 7, 14);

        var placed = engine.TryPlaceStone(7, 7);

        Assert.True(placed);
        Assert.Equal(StoneColor.Black, engine.Winner);
    }

    private static void Place(GameEngine engine, int row, int col)
    {
        var placed = engine.TryPlaceStone(row, col);

        Assert.True(placed);
    }
}
