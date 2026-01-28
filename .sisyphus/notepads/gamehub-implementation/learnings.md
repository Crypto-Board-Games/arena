# GameHub Implementation Learnings

## SignalR Hub Testing
- Use Moq to mock IHubCallerClients, IGroupManager, HubCallerContext
- Setup ISingleClientProxy for Caller and IClientProxy for Group
- Verify with SendCoreAsync instead of SendAsync for better matching
- Use `It.Is<object?[]>()` to match SignalR message payloads

## EF Core InMemory for Tests
- Need `Microsoft.EntityFrameworkCore.InMemory` package
- Use unique database names per test: `Guid.NewGuid().ToString()`

## Turn-Based Game Logic
- After each move, switch CurrentTurnPlayerId to opponent
- Tests must account for turn changes when verifying occupied positions
- Pre-populate board state to test specific scenarios

## Timer Implementation
- Use System.Threading.Timer with 1-second interval for turn timer
- Dispose timers properly on game end and disconnect
- Store remaining seconds in session state
