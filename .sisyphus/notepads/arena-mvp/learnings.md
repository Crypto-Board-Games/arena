## EF Core Data Model Implementation (2026-01-28)

### Entities Implemented
- **User**: GoogleId (unique), Email (unique), DisplayName, Elo (default 1200), Wins/Losses (default 0)
- **Game**: BlackPlayerId, WhitePlayerId, WinnerId (nullable), Status (enum), CurrentBoardState (JSON, nullable)
- **MatchQueue**: UserId (unique), Elo (snapshot), QueuedAt, ConnectionId (nullable)
- **GameStatus enum**: InProgress (0), Completed (1), Abandoned (2)

### Database Constraints
- Unique indexes: User.GoogleId, User.Email, MatchQueue.UserId
- Foreign keys with Restrict delete: Game → User (all player references)
- Foreign key with Cascade delete: MatchQueue → User
- All IDs are Guid type
- Timestamps use DateTime (UTC recommended in application code)

### Package Versions (Critical)
- Must use consistent EF Core versions across all projects
- Updated to EF Core 10.0.0 and Npgsql.EntityFrameworkCore.PostgreSQL 10.0.0
- Version mismatch causes runtime errors in migrations

### TDD Approach
- Followed RED-GREEN-REFACTOR cycle strictly
- 12 tests total: 3 User + 5 Game + 3 MatchQueue + 1 existing
- All tests passing before migration creation

### Migration Files
- Created: 20260128074150_InitialCreate.cs
- Location: Arena.Models/Migrations/
- Verified: All tables, foreign keys, and unique indexes correctly generated

### PostgreSQL Setup
- Connection string in appsettings.Development.json
- Database: arena, User: postgres, Password: postgres
- Migration ready to apply when PostgreSQL is running
- Command: `dotnet ef database update --project Arena.Models --startup-project Arena.Server`

### Project Structure
```
Arena.Models/
├── Entities/
│   ├── User.cs
│   ├── Game.cs
│   └── MatchQueue.cs
├── ArenaDbContext.cs
└── Migrations/
    └── 20260128074150_InitialCreate.cs

Arena.Tests/Models/
├── UserTests.cs
├── GameTests.cs
└── MatchQueueTests.cs
```

### Key Decisions
- No soft delete pattern (per requirements)
- No detailed move history (only CurrentBoardState for reconnection)
- Simple entity design without navigation properties
- Restrict delete on Game references to prevent data loss
- Cascade delete on MatchQueue to auto-cleanup when user deleted
