using Arena.Models;
using Arena.Models.Entities;
using Arena.Server.Hubs;
using Arena.Server.Models;
using Arena.Server.Services;

using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

using Moq;

using System.Collections.Concurrent;
using System.Security.Claims;

namespace Arena.Tests.Hubs;

public class GameHubTests : IDisposable
{
    private readonly ArenaDbContext _dbContext;
    private readonly Mock<IHubCallerClients> _mockClients;
    private readonly Mock<IGroupManager> _mockGroups;
    private readonly Mock<HubCallerContext> _mockContext;
    private readonly Mock<ISingleClientProxy> _mockCaller;
    private readonly Mock<IClientProxy> _mockGroupProxy;
    private readonly EloCalculator _eloCalculator;
    private readonly ConcurrentDictionary<Guid, GameSession> _gameSessions;
    private readonly ConcurrentDictionary<string, string> _connectionUserMap;
    private readonly GameHub _hub;

    private readonly ArenaUser _blackPlayer;
    private readonly ArenaUser _whitePlayer;
    private readonly Game _testGame;

    public GameHubTests()
    {
        var options = new DbContextOptionsBuilder<ArenaDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        _dbContext = new ArenaDbContext(options);

        _blackPlayer = new ArenaUser
        {
            Id = Guid.NewGuid().ToString(),
            Email = "black@test.com",
            DisplayName = "BlackPlayer",
            Elo = 1200,
            Wins = 0,
            Losses = 0,
            CreatedAt = DateTime.UtcNow
        };

        _whitePlayer = new ArenaUser
        {
            Id = Guid.NewGuid().ToString(),
            Email = "white@test.com",
            DisplayName = "WhitePlayer",
            Elo = 1200,
            Wins = 0,
            Losses = 0,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Users.AddRange(_blackPlayer, _whitePlayer);
        _dbContext.SaveChanges();

        _testGame = new Game
        {
            Id = Guid.NewGuid(),
            BlackPlayerId = _blackPlayer.Id,
            WhitePlayerId = _whitePlayer.Id,
            Status = GameStatus.InProgress,
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Games.Add(_testGame);
        _dbContext.SaveChanges();

        _mockClients = new Mock<IHubCallerClients>();
        _mockGroups = new Mock<IGroupManager>();
        _mockContext = new Mock<HubCallerContext>();
        _mockCaller = new Mock<ISingleClientProxy>();
        _mockGroupProxy = new Mock<IClientProxy>();

        _mockClients.Setup(c => c.Caller).Returns(_mockCaller.Object);
        _mockClients.Setup(c => c.Group(It.IsAny<string>())).Returns(_mockGroupProxy.Object);
        _mockClients.Setup(c => c.OthersInGroup(It.IsAny<string>())).Returns(_mockGroupProxy.Object);

        _eloCalculator = new EloCalculator();
        _gameSessions = new ConcurrentDictionary<Guid, GameSession>();
        _connectionUserMap = new ConcurrentDictionary<string, string>();

        _hub = new GameHub(_dbContext, _eloCalculator, _gameSessions, _connectionUserMap)
        {
            Clients = _mockClients.Object,
            Groups = _mockGroups.Object,
            Context = _mockContext.Object
        };
    }

    public void Dispose()
    {
        _hub.Dispose();
        _dbContext.Dispose();

        GC.SuppressFinalize(this);
    }

    private void SetupCallerAsBlackPlayer()
    {
        var connectionId = Guid.NewGuid().ToString();
        _mockContext.Setup(c => c.ConnectionId).Returns(connectionId);

        var claims = new List<Claim> { new("sub", _blackPlayer.Id.ToString()) };
        var identity = new ClaimsIdentity(claims, "test");
        var principal = new ClaimsPrincipal(identity);
        _mockContext.Setup(c => c.User).Returns(principal);

        _connectionUserMap[connectionId] = _blackPlayer.Id;
    }

    private void SetupCallerAsWhitePlayer()
    {
        var connectionId = Guid.NewGuid().ToString();
        _mockContext.Setup(c => c.ConnectionId).Returns(connectionId);

        var claims = new List<Claim> { new("sub", _whitePlayer.Id.ToString()) };
        var identity = new ClaimsIdentity(claims, "test");
        var principal = new ClaimsPrincipal(identity);
        _mockContext.Setup(c => c.User).Returns(principal);

        _connectionUserMap[connectionId] = _whitePlayer.Id;
    }

    [Fact]
    public async Task JoinGame_ValidGame_AddsToGroupAndSendsGameStarted()
    {
        SetupCallerAsBlackPlayer();
        var connectionId = _mockContext.Object.ConnectionId;

        await _hub.JoinGame(_testGame.Id.ToString());

        _mockGroups.Verify(g => g.AddToGroupAsync(connectionId, _testGame.Id.ToString(), default), Times.Once);
        _mockCaller.Verify(c => c.SendCoreAsync("OnGameStarted", It.IsAny<object?[]>(), default), Times.Once);
    }

    [Fact]
    public async Task JoinGame_InvalidGameId_SendsError()
    {
        SetupCallerAsBlackPlayer();
        var invalidGameId = Guid.NewGuid().ToString();

        await _hub.JoinGame(invalidGameId);

        _mockCaller.Verify(c => c.SendCoreAsync("OnMoveRejected",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("game_not_found")), default),
            Times.Once);
    }

    [Fact]
    public async Task PlaceStone_ValidMove_BroadcastsMoveMade()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        await _hub.PlaceStone(_testGame.Id.ToString(), 7, 7);

        _mockGroupProxy.Verify(c => c.SendCoreAsync("OnMoveMade", It.IsAny<object?[]>(), default), Times.Once);
    }

    [Fact]
    public async Task PlaceStone_NotYourTurn_RejectsMove()
    {
        SetupCallerAsWhitePlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        await _hub.PlaceStone(_testGame.Id.ToString(), 7, 7);

        _mockCaller.Verify(c => c.SendCoreAsync("OnMoveRejected",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("not_your_turn")), default),
            Times.Once);
    }

    [Fact]
    public async Task PlaceStone_OccupiedPosition_RejectsMove()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        var session = _gameSessions[_testGame.Id];
        session.Board[7, 7] = 1;

        await _hub.PlaceStone(_testGame.Id.ToString(), 7, 7);

        _mockCaller.Verify(c => c.SendCoreAsync("OnMoveRejected",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("occupied")), default),
            Times.AtLeastOnce);
    }

    [Fact]
    public async Task PlaceStone_OutOfBounds_RejectsMove()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        await _hub.PlaceStone(_testGame.Id.ToString(), 15, 15);

        _mockCaller.Verify(c => c.SendCoreAsync("OnMoveRejected",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("out_of_bounds")), default),
            Times.Once);
    }

    [Fact]
    public async Task PlaceStone_WinningMove_EndsGameWithFiveInRow()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        var session = _gameSessions[_testGame.Id];
        session.Board[7, 0] = 1;
        session.Board[7, 1] = 1;
        session.Board[7, 2] = 1;
        session.Board[7, 3] = 1;

        await _hub.PlaceStone(_testGame.Id.ToString(), 4, 7);

        _mockGroupProxy.Verify(c => c.SendCoreAsync("OnGameEnded",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("five_in_row")), default),
            Times.Once);

        var game = await _dbContext.Games.FindAsync([_testGame.Id], TestContext.Current.CancellationToken);

        Assert.Equal(GameStatus.Completed, game!.Status);
        Assert.Equal(_blackPlayer.Id, game.WinnerId);
    }

    [Fact]
    public async Task PlaceStone_ForbiddenMove_33_RejectsMove()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        var session = _gameSessions[_testGame.Id];
        session.Board[6, 6] = 1;
        session.Board[6, 8] = 1;
        session.Board[8, 6] = 1;
        session.Board[8, 8] = 1;

        await _hub.PlaceStone(_testGame.Id.ToString(), 7, 7);

        _mockCaller.Verify(c => c.SendCoreAsync("OnMoveRejected",
            It.Is<object?[]>(args => args[0] != null &&
                ($"{args[0]}".Contains("forbidden_33") || $"{args[0]}".Contains("forbidden"))), default),
            Times.AtLeastOnce);
    }

    [Fact]
    public async Task Resign_ValidGame_EndsGameWithResign()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        await _hub.Resign(_testGame.Id.ToString());

        _mockGroupProxy.Verify(c => c.SendCoreAsync("OnGameEnded",
            It.Is<object?[]>(args => args[0] != null && $"{args[0]}".Contains("resign")), default),
            Times.Once);

        var game = await _dbContext.Games.FindAsync([_testGame.Id], TestContext.Current.CancellationToken);

        Assert.Equal(GameStatus.Completed, game!.Status);
        Assert.Equal(_whitePlayer.Id, game.WinnerId);
    }

    [Fact]
    public async Task GameEnd_UpdatesEloAndStats()
    {
        SetupCallerAsBlackPlayer();
        await _hub.JoinGame(_testGame.Id.ToString());

        var session = _gameSessions[_testGame.Id];
        session.Board[7, 0] = 1;
        session.Board[7, 1] = 1;
        session.Board[7, 2] = 1;
        session.Board[7, 3] = 1;

        await _hub.PlaceStone(_testGame.Id.ToString(), 4, 7);

        var winner = await _dbContext.Users.FindAsync([_blackPlayer.Id], TestContext.Current.CancellationToken);
        var loser = await _dbContext.Users.FindAsync([_whitePlayer.Id], TestContext.Current.CancellationToken);

        Assert.True(winner!.Elo > 1200);
        Assert.True(loser!.Elo < 1200);
        Assert.Equal(1, winner.Wins);
        Assert.Equal(1, loser.Losses);
        Assert.NotNull(winner.LastPlayedAt);
        Assert.NotNull(loser.LastPlayedAt);
    }

    [Fact]
    public void EloCalculator_EqualPlayers_SymmetricResult()
    {
        var (winnerNew, loserNew, winnerChange, loserChange) = _eloCalculator.Calculate(1200, 1200);

        Assert.Equal(16, winnerChange);
        Assert.Equal(-16, loserChange);
        Assert.Equal(1216, winnerNew);
        Assert.Equal(1184, loserNew);
    }

    [Fact]
    public void EloCalculator_StrongBeatsWeak_SmallGain()
    {
        var (_, _, winnerChange, _) = _eloCalculator.Calculate(1400, 1000);

        Assert.True(winnerChange < 16);
    }

    [Fact]
    public void EloCalculator_WeakBeatsStrong_LargeGain()
    {
        var (_, _, winnerChange, _) = _eloCalculator.Calculate(1000, 1400);

        Assert.True(winnerChange > 16);
    }
}
