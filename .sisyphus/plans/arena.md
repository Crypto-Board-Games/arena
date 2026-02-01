# Arena - 온라인 오목 게임 플랫폼

## TL;DR

> **Quick Summary**: ELO 기반 랜덤 매칭으로 실력이 비슷한 상대와 렌주룰 오목을 웹에서 플레이하는 플랫폼
> 
> **Deliverables**:
> - Flutter Web 클라이언트 (오목 보드, 매칭 UI, 전적/랭킹)
> - .NET 백엔드 (SignalR 실시간 통신, Google OAuth, ELO 시스템)
> - PostgreSQL 데이터베이스 (사용자, 게임 기록, 랭킹)
> 
> **Estimated Effort**: Large (2-3 weeks)
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Models → Game Logic → SignalR Hub → Flutter Board → Integration

---

## Context

### Original Request
온라인에서 랜덤 매칭으로 오목을 플레이하고, 전적과 랭킹을 관리하는 웹 게임 플랫폼

### Interview Summary
**Key Discussions**:
- 렌주룰 적용 (3-3, 4-4, 장목 금지 - 흑만)
- 한 수당 30초 시간 제한
- ELO 기반 실력 매칭
- Google 소셜 로그인
- TDD 방식 개발

**Research Findings (Metis)**:
- 서버 권위적 규칙 검증이 치팅 방지에 필수
- SignalR + JWT 인증 조합이 .NET 실시간 게임에 표준
- Flutter Web에서 Riverpod + GoRouter 조합이 상태/라우팅 관리에 적합

### Metis Review
**Identified Gaps** (addressed with defaults):
- 초기 ELO → 1200 (표준)
- ELO 매칭 범위 → ±200, 30초마다 ±50 확장
- 타임아웃 시 → 자동 패배
- 연결 끊김 → 30초 대기 후 자동 패배
- 금지 수 → 서버 거부 + 클라이언트 시각적 피드백
- 기권 → MVP 포함
- 보드 크기 → 15×15 (표준)

---

## SignalR Contract Specification (AUTHORITATIVE)

> **NOTE**: 이 섹션이 SignalR 계약의 유일한 권위본입니다. 다른 곳에서 참조 시 이 섹션을 따릅니다.

### MatchmakingHub (`/hubs/matchmaking`)

**Client → Server Methods**:
| Method | Parameters | Description |
|--------|------------|-------------|
| `JoinMatchmaking` | - | 매칭 대기열 등록 |
| `LeaveMatchmaking` | - | 매칭 대기열 취소 |

**Server → Client Events**:
| Event | Payload | Description |
|-------|---------|-------------|
| `OnMatchFound` | `{ gameId: string, opponentName: string, yourColor: "black" \| "white" }` | 매칭 성공 |
| `OnMatchmakingStatus` | `{ waitingSeconds: int, currentRange: int }` | 대기 상태 (매 10초) |

### GameHub (`/hubs/game`)

**Client → Server Methods**:
| Method | Parameters | Response | Description |
|--------|------------|----------|-------------|
| `JoinGame` | `gameId: string` | `void` | 게임 방 입장 |
| `PlaceStone` | `gameId: string, x: int, y: int` | `void` (OnMoveMade or OnMoveRejected) | 돌 배치 시도 |
| `Resign` | `gameId: string` | `void` (OnGameEnded) | 기권 |

**Server → Client Events (GameHub)**

| Event | Payload | Recipient | Description |
|-------|---------|-----------|-------------|
| `OnGameStarted` | `{ gameId, blackPlayerId, whitePlayerId, yourColor }` | Both players | 게임 시작 알림 |
| `OnMoveMade` | `{ x, y, color, remainingTime }` | Both players | 돌 배치 완료 |
| `OnMoveRejected` | `{ x, y, reason }` | Caller only | 금지 수/에러 거부 |
| `OnTimerUpdate` | `{ currentPlayer, remainingSeconds }` | Both players | 타이머 (매 초) |
| `OnGameEnded` | `{ winnerId, reason, eloChange }` | Both players | 게임 종료 (상세 스키마 아래 참조) |
| `OnOpponentDisconnected` | `{ gracePeriodSeconds }` | Remaining player | 상대 연결 끊김 |
| `OnOpponentReconnected` | `{}` | Remaining player | 상대 재연결 |
| `OnGameResumed` | `{ board, yourColor, currentTurn, remainingSeconds, opponentConnected }` | Reconnected player | 재연결 후 게임 상태 복원 |
| `OnError` | `{ code, message }` | Caller only | 일반 에러 |

**OnMoveRejected Reason Types (전체 목록)**:
| Reason | Description |
|--------|-------------|
| `occupied` | 이미 돌이 있는 위치 |
| `forbidden_33` | 3-3 금지수 (흑만) |
| `forbidden_44` | 4-4 금지수 (흑만) |
| `forbidden_overline` | 장목 금지수 (흑만) |
| `not_your_turn` | 상대 턴에 시도 |
| `out_of_bounds` | 좌표 범위 초과 (x,y < 0 or >= 15) |
| `game_not_found` | 존재하지 않는 게임 |
| `game_already_ended` | 이미 종료된 게임 |

**OnError Code Types**:
| Code | Message | Trigger |
|------|---------|---------|
| `auth_failed` | "Authentication required" | JWT 없음/만료 |
| `not_in_game` | "You are not in this game" | JoinGame 안 한 상태에서 PlaceStone |
| `invalid_game_id` | "Invalid game ID format" | GUID 형식 오류 |

**OnGameEnded 상세 스키마**:
```json
{
  "winnerId": "uuid-string",      // 승자 User.Id (null if draw - 렌주에선 불가)
  "reason": "five_in_row",        // 종료 사유 (아래 목록)
  "eloChange": {
    "winner": 15,                 // 승자의 ELO 증가량 (양수)
    "loser": -15                  // 패자의 ELO 감소량 (음수)
  }
}
```

**OnGameEnded.reason 값 목록**:
| Reason | Description | ELO 변동 |
|--------|-------------|----------|
| `five_in_row` | 5목 완성으로 승리 | 정상 계산 |
| `timeout` | 상대 시간 초과로 승리 | 정상 계산 |
| `resign` | 상대 기권으로 승리 | 정상 계산 |
| `disconnect` | 상대 연결 끊김 (30초 초과)으로 승리 | 정상 계산 |
| `server_shutdown` | 서버 종료/재시작으로 게임 중단 | **ELO 변동 없음** |

**server_shutdown 시 특별 처리**:
```json
{
  "winnerId": null,
  "reason": "server_shutdown",
  "eloChange": { "winner": 0, "loser": 0 }
}
```
- 클라이언트 메시지: "서버 점검으로 게임이 종료되었습니다. ELO 변동은 없습니다."

**eloChange 해석**:
- 각 플레이어는 자신의 `winnerId` 비교로 승패 확인
- `eloChange.winner`: 승자가 얻는 ELO (항상 양수)
- `eloChange.loser`: 패자가 잃는 ELO (항상 음수)
- 클라이언트 표시: `내 userId == winnerId` → `+{eloChange.winner}` 표시, 아니면 `{eloChange.loser}` 표시

### GameHub Methods (Client → Server)

| Method | Parameters | Response | Description |
|--------|------------|----------|-------------|
| `JoinGame` | `gameId: string` | `void` | 게임 방 입장 |
| `PlaceStone` | `gameId: string, x: int, y: int` | `void` (OnMoveMade or OnMoveRejected) | 돌 배치 시도 |
| `Resign` | `gameId: string` | `void` (OnGameEnded) | 기권 |

### Connection Lifecycle
```
1. Client connects with JWT in query string: /hubs/game?access_token={jwt}
2. Server validates JWT, extracts userId from claims (sub)
3. Client calls JoinGame(gameId)
4. Server adds connection to game group
5. On disconnect: 30-second grace period timer starts
6. On reconnect within grace: timer cancelled, resume game
7. On grace period expire: auto-loss for disconnected player
```

### GameHub State Management (AUTHORITATIVE)

**상태 저장 위치**:
| State | Storage | Reason |
|-------|---------|--------|
| 게임 메타데이터 | PostgreSQL `Game` 테이블 | 영속성, 결과 기록 |
| 현재 보드 상태 | PostgreSQL `Game.CurrentBoardState` | 재연결 지원 |
| 활성 게임 세션 | **In-Memory** `ConcurrentDictionary<Guid, GameSession>` | 빠른 접근 |
| 턴 타이머 | **In-Memory** `System.Threading.Timer` per game | 실시간 처리 |
| 플레이어 연결 매핑 | **In-Memory** `ConcurrentDictionary<string, Guid>` (connectionId → userId) | 빠른 조회 |

**GameSession 클래스** (In-Memory):
```csharp
public class GameSession
{
    public Guid GameId { get; set; }
    public int[,] Board { get; set; } = new int[15, 15];  // 0=empty, 1=black, 2=white
    public Guid CurrentTurnPlayerId { get; set; }
    public Guid BlackPlayerId { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Timer TurnTimer { get; set; }
    public int RemainingSeconds { get; set; } = 30;
    public Guid? DisconnectedPlayerId { get; set; }  // Guid (User.Id와 일치)
    public Timer? DisconnectGraceTimer { get; set; }
}
```

**ConnectionId ↔ UserId 매핑**:
```csharp
// 저장
ConcurrentDictionary<string, Guid> _connectionUserMap;  // connectionId → userId

// OnConnected에서:
var userId = Guid.Parse(Context.User.FindFirst("sub").Value);
_connectionUserMap[Context.ConnectionId] = userId;

// OnDisconnected에서:
_connectionUserMap.TryRemove(Context.ConnectionId, out _);

// 조회:
if (_connectionUserMap.TryGetValue(connectionId, out var userId)) { ... }
```

**GameEngine 연결**:
- `GameHub`는 `GameEngine`을 DI로 주입받음
- `PlaceStone` 호출 시: `GameEngine.ValidateMove(board, x, y, color)` 검증
- 검증 통과 시: `GameSession.Board` 업데이트 → DB `CurrentBoardState` 동기화

**ELO 계산/DB 반영 (소유: GameHub)**:
```csharp
// GameHub.EndGame() 메서드에서 처리
async Task EndGame(Guid gameId, Guid winnerId, string reason)
{
    var session = _gameSessions[gameId];
    var loserId = winnerId == session.BlackPlayerId ? session.WhitePlayerId : session.BlackPlayerId;
    
    // 1. ELO 계산 (EloCalculator 서비스 사용)
    var (winnerChange, loserChange) = _eloCalculator.Calculate(winnerElo, loserElo);
    
    // 2. DB 업데이트 (트랜잭션)
    await using var tx = await _db.Database.BeginTransactionAsync();
    var winner = await _db.Users.FindAsync(winnerId);
    var loser = await _db.Users.FindAsync(loserId);
    
    winner.Elo += winnerChange;
    winner.Wins++;
    winner.LastPlayedAt = DateTime.UtcNow;
    
    loser.Elo += loserChange;  // loserChange는 음수
    loser.Losses++;
    loser.LastPlayedAt = DateTime.UtcNow;
    
    // 3. Game 상태 업데이트
    var game = await _db.Games.FindAsync(gameId);
    game.Status = GameStatus.Completed;
    game.WinnerId = winnerId;
    game.EndedAt = DateTime.UtcNow;
    game.CurrentBoardState = null;  // 정리
    
    await _db.SaveChangesAsync();
    await tx.CommitAsync();
    
    // 4. 이벤트 전송
    await Clients.Group(gameId.ToString()).OnGameEnded(new {
        winnerId,
        reason,
        eloChange = new { winner = winnerChange, loser = loserChange }
    });
}
```

**CurrentBoardState 사용/정리**:
- **사용**: 재연결 시 `JoinGame` 호출하면 `CurrentBoardState`에서 보드 복원
- **정리**: 게임 종료 시 `CurrentBoardState = null` 설정 (결과만 유지)

---

### Game Session Reconnection & Recovery (상세)

**재연결 시나리오**:
```
1. 플레이어 A가 연결 끊김
2. 30초 grace period 시작, 플레이어 B에게 OnOpponentDisconnected 전송
3. 플레이어 A가 30초 내에 재연결 + JoinGame(gameId) 호출
4. 서버가 게임 세션 복구 수행
```

**복구되는 정보**:
| Field | Source | Action |
|-------|--------|--------|
| Board state | `Game.CurrentBoardState` (DB) | JSON 파싱 후 GameSession.Board에 로드 |
| Current turn | `GameSession.CurrentTurnPlayerId` (Memory) | 그대로 유지 |
| Remaining time | `GameSession.RemainingSeconds` (Memory) | **리셋하지 않고 남은 시간 유지** |
| Turn timer | `GameSession.TurnTimer` (Memory) | 재시작 (남은 시간으로) |

**타이머 처리 규칙**:
```
- 재연결 시: 기존 남은 시간에서 타이머 재개 (리셋 X)
- 예: 남은 시간 15초에서 끊김 → 재연결 후 15초부터 계속
- 이유: 의도적 끊김으로 시간 벌기 방지
```

**서버 재시작 시 게임 세션 처리**:
```
1. In-Memory GameSession은 서버 재시작 시 모두 소실됨
2. Game.Status가 InProgress인 게임들은:
   a. 클라이언트 재연결 시 DB에서 CurrentBoardState 복원
   b. CurrentTurnPlayerId는 DB에 저장 필요 (추가 필드)
   c. RemainingSeconds는 복구 불가 → 30초로 리셋
3. 또는 MVP 단순화: 서버 재시작 시 진행 중 게임은 Abandoned로 처리
   - 두 플레이어 모두 ELO 변동 없음
   - 클라이언트에 "서버 점검으로 게임이 종료되었습니다" 표시
```

**MVP 결정**: 서버 재시작 시 진행 중 게임은 **Abandoned** 처리 (단순화)

**JoinGame 재연결 응답**:
```json
// 서버 → 재연결한 클라이언트
{
  "event": "OnGameResumed",
  "payload": {
    "board": [[0,0,...], ...],  // 15x15 2D array
    "yourColor": "black",
    "currentTurn": "black",
    "remainingSeconds": 15,
    "opponentConnected": true
  }
}
```

---

## Authentication Flow Specification

### OAuth 2.0 Web Flow (Google Sign-In for Flutter Web)

```
1. Flutter calls google_sign_in package
2. User completes Google OAuth in popup
3. Flutter receives Google ID Token
4. Flutter sends POST /api/auth/google with body:
   {
     "idToken": "google_id_token",
     "email": "user@gmail.com",
     "displayName": "User Name"
   }
5. Server validates Google ID Token with Google API
6. Server creates/updates User in DB
7. Server returns JWT:
   {
     "access_token": "jwt_token",
     "expires_in": 86400,
     "user": { "id": "...", "elo": 1200, "wins": 0, "losses": 0 }
   }
8. Flutter stores JWT in memory (NOT localStorage for security)
9. All API calls include: Authorization: Bearer {jwt}
10. SignalR connects with: /hubs/game?access_token={jwt}
```

### JWT Token Specification

**서명 알고리즘**: HS256 (HMAC-SHA256)
**만료 시간**: 24시간 (86400초)
**사용자 식별자**: `sub` 클레임 = `User.Id` (GUID)

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",  // User.Id (PRIMARY IDENTIFIER)
  "email": "user@gmail.com",
  "name": "Display Name",
  "iat": 1234567890,
  "exp": 1234571490,
  "iss": "arena-server",
  "aud": "arena-client"
}
```

**SignalR UserIdentifier**: `sub` 클레임 사용
```csharp
// Program.cs에서 설정
services.AddSignalR();
services.AddSingleton<IUserIdProvider, SubClaimUserIdProvider>();

// SubClaimUserIdProvider.cs
public string? GetUserId(HubConnectionContext connection)
    => connection.User?.FindFirst("sub")?.Value;
```

**토큰 만료 시 처리**:
- SignalR 연결: 기존 연결 유지 (만료 시점에 즉시 끊지 않음)
- API 호출: 401 Unauthorized 반환
- 클라이언트: 401 수신 시 Google 재로그인 유도
- 게임 중 만료: 게임 완료까지 허용 (세션 유지)

### Required Environment Variables
```bash
# .NET Server (appsettings.json or environment)
Google__ClientId=your_google_client_id
Google__ClientSecret=your_google_client_secret
Jwt__Secret=your_jwt_secret_min_32_chars
Jwt__Issuer=arena-server
Jwt__Audience=arena-client
ConnectionStrings__DefaultConnection=Host=localhost;Database=arena;Username=...;Password=...
```

### Token Refresh Policy
- **MVP 결정**: 리프레시 토큰 **미구현**
- JWT 만료 시간: 24시간
- 만료 시: 사용자가 다시 Google 로그인
- 이유: MVP 단순화, 게임 세션은 보통 짧음

---

## REST API Specification

### Health Check Endpoint (Task 1 검증용)

| Method | Endpoint | Request | Response | Description |
|--------|----------|---------|----------|-------------|
| GET | `/health` | - | `{ status, database, timestamp }` | 서버 상태 확인 |

**응답 스키마**:
```json
// 정상
{
  "status": "Healthy",
  "database": "Connected",
  "timestamp": "2024-01-15T10:30:00Z"
}

// DB 연결 실패
{
  "status": "Unhealthy",
  "database": "Disconnected",
  "error": "Connection refused",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**구현 위치**: `Arena.Server/Program.cs`
```csharp
// Health check 설정
builder.Services.AddHealthChecks()
    .AddNpgSql(connectionString, name: "database");

// Endpoint 매핑
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = WriteHealthCheckResponse
});
```

---

### Authentication Endpoints

| Method | Endpoint | Request | Response | Description |
|--------|----------|---------|----------|-------------|
| POST | `/api/auth/google` | `{ idToken, email, displayName }` | `{ access_token, expires_in, user }` | Google 로그인 |

### User Endpoints (Authorization: Bearer required)

| Method | Endpoint | Request | Response | Description |
|--------|----------|---------|----------|-------------|
| GET | `/api/users/me` | - | `{ id, displayName, email, elo, wins, losses, winRate, gamesPlayed, rank }` | 내 프로필 |

### Ranking Endpoints (Authorization: Bearer required)

| Method | Endpoint | Request | Response | Description |
|--------|----------|---------|----------|-------------|
| GET | `/api/rankings?limit=100` | Query: limit (default 100) | `{ rankings: [{ rank, userId, displayName, elo, wins, losses }], myRank: number }` | Top N 랭킹 + 내 순위 |

### Matchmaking Endpoints (via SignalR, NOT REST)

매칭은 실시간 특성상 REST가 아닌 SignalR로 처리:
- **등록**: SignalR 연결 후 `JoinMatchmaking()` 호출
- **취소**: `LeaveMatchmaking()` 호출
- **결과**: 서버가 `OnMatchFound` 이벤트 푸시

---

## Data Model Specification

### User Entity
```csharp
public class User
{
    public Guid Id { get; set; }  // Primary Key
    public string GoogleId { get; set; }  // UNIQUE, NOT NULL
    public string Email { get; set; }  // UNIQUE, NOT NULL
    public string DisplayName { get; set; }
    public int Elo { get; set; } = 1200;
    public int Wins { get; set; } = 0;
    public int Losses { get; set; } = 0;
    public DateTime CreatedAt { get; set; }
    public DateTime? LastPlayedAt { get; set; }
}

// Unique Constraints:
// - GoogleId: UNIQUE (one account per Google user)
// - Email: UNIQUE (prevent duplicates)
```

### Game Entity
```csharp
public class Game
{
    public Guid Id { get; set; }
    public Guid BlackPlayerId { get; set; }  // FK → User
    public Guid WhitePlayerId { get; set; }  // FK → User
    public Guid? WinnerId { get; set; }  // FK → User, NULL if in progress
    public GameStatus Status { get; set; }  // InProgress, Completed, Abandoned
    public string? CurrentBoardState { get; set; }  // JSON: 15x15 array, for reconnection only
    public DateTime CreatedAt { get; set; }
    public DateTime? EndedAt { get; set; }
    
    // NOTE: Move history is NOT stored for replay.
    // CurrentBoardState is for reconnection support only.
    // After game ends, CurrentBoardState can be cleared.
}

public enum GameStatus { InProgress, Completed, Abandoned }
```

### MatchQueue Entity
```csharp
public class MatchQueue
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }  // FK → User, UNIQUE (one queue entry per user)
    public int Elo { get; set; }  // Snapshot at queue time
    public DateTime QueuedAt { get; set; }
    public string? ConnectionId { get; set; }  // SignalR connection for notification
}

// Storage: DATABASE (PostgreSQL)
// Reason: Persistence across server restarts, ACID transactions for concurrent matching
// Cleanup: Remove entry on match found, timeout (3 min), or user cancel
```

### Matchmaking Queue Implementation
```
Storage: PostgreSQL MatchQueue table (NOT in-memory)
Reason: Server restart 시 대기열 유지, 동시성 안전

Matching Algorithm:
1. Background service runs every 1 second
2. SELECT * FROM MatchQueue ORDER BY QueuedAt
3. For each entry:
   a. Calculate expanded range: ±(200 + 50 * floor(seconds_waiting / 30))
   b. Find opponent within range, closest ELO first
   c. If found: Create Game, remove both from queue, notify via SignalR
4. If waiting > 180 seconds: Match with anyone available

Concurrency: Use SELECT FOR UPDATE to prevent race conditions
```

**서버 재시작 시 대기열 처리**:
```
1. 서버 재시작 후 MatchQueue 테이블의 ConnectionId는 모두 무효화됨
2. 클라이언트는 SignalR 연결 끊김을 감지하고 자동 재연결 시도
3. 재연결 성공 시 클라이언트가 JoinMatchmaking 재호출 필요
4. 서버 시작 시 Cleanup 작업:
   - MatchQueue에서 ConnectionId가 유효하지 않은 항목 삭제 (또는)
   - QueuedAt이 10분 이상 지난 항목 자동 삭제
5. 클라이언트 UX: "연결이 끊어졌습니다. 다시 매칭을 시작해주세요" 표시
```

---

## Work Objectives

### Core Objective
실력 기반 랜덤 매칭으로 렌주룰 오목을 실시간 대전하고, 전적과 랭킹을 관리하는 웹 플랫폼 구축

### Concrete Deliverables
- `/home/cyberprophet/source/arena/server/` - .NET 백엔드
- `/home/cyberprophet/source/arena/client/` - Flutter Web 프론트엔드
- PostgreSQL 스키마 (Users, Games, MatchQueue)
- 배포 가능한 웹 애플리케이션

### Runtime & Version Requirements
| Component | Version | Notes |
|-----------|---------|-------|
| **.NET** | 8.0 (LTS) | `<TargetFramework>net8.0</TargetFramework>` |
| **Flutter** | 3.x (stable channel) | `flutter channel stable` |
| **PostgreSQL** | 15+ | 로컬 또는 Docker |
| **Node.js** | N/A | 불필요 |

**주요 NuGet 패키지**:
- `Microsoft.AspNetCore.SignalR` (built-in .NET 8)
- `Npgsql.EntityFrameworkCore.PostgreSQL` ^8.0
- `Microsoft.AspNetCore.Authentication.JwtBearer` ^8.0
- `Google.Apis.Auth` ^1.64 (ID Token 검증)

**주요 Flutter 패키지**:
- `flutter_riverpod: ^2.4`
- `go_router: ^13.0`
- `signalr_netcore: ^1.3`
- `google_sign_in: ^6.1`
- `flutter_screenutil: ^5.9`

### Definition of Done
- [x] Google 로그인으로 회원가입/로그인 가능
- [x] 매칭 대기열에 등록 후 상대 매칭
- [x] 15×15 보드에서 오목 대전 가능
- [x] 렌주룰 정상 작동 (흑 금지 수 검증)
- [x] 30초 타이머 정상 작동
- [x] 승패에 따른 ELO 변동
- [x] 랭킹 페이지에서 순위 확인 가능
- [x] 모든 핵심 로직 테스트 통과

### Must Have
- Google OAuth 인증
- ELO 기반 매칭
- 렌주룰 (흑: 3-3, 4-4, 장목 금지)
- 30초 턴 타이머
- 실시간 게임 동기화 (SignalR)
- 전적 기록 (승/패/ELO)
- 랭킹 리더보드

### Must NOT Have (Guardrails)
- 친구 초대 / 비공개 방
- 관전 모드
- 인게임 채팅
- 게임 리플레이 저장
- 소셜 로그인 추가 (Kakao, Apple 등)
- 모바일 앱 빌드 (웹만)
- AI 대전 모드
- 사운드 / 음악
- 복잡한 애니메이션 (CSS transition만)
- Redis / 캐싱 레이어
- 마이크로서비스 아키텍처

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: Will be set up
- **User wants tests**: TDD
- **Framework**: xUnit (.NET), flutter_test (Flutter)

### TDD Workflow
각 TODO는 RED-GREEN-REFACTOR:

1. **RED**: 실패하는 테스트 먼저 작성
2. **GREEN**: 테스트 통과하는 최소 코드 구현
3. **REFACTOR**: 리팩토링 (테스트 유지)

### Critical Test Coverage
| 대상 | 테스트 종류 | 필수 |
|------|------------|------|
| Renju Rules | Unit Test | ✅ |
| ELO Calculation | Unit Test | ✅ |
| SignalR GameHub | Integration Test | ✅ |
| Matchmaking | Unit Test | ✅ |
| Flutter Board | Widget Test | ✅ |

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation - Start Immediately):
├── Task 1: 프로젝트 구조 및 개발 환경 설정
├── Task 2: 데이터 모델 설계 (EF Core)
└── Task 3: 게임 로직 - 렌주룰 엔진 (TDD)

Wave 2 (Core Features - After Wave 1):
├── Task 4: SignalR GameHub 구현
├── Task 5: Google OAuth 인증
├── Task 6: 매칭 시스템 구현
└── Task 7: Flutter 기본 구조 및 라우팅

Wave 3 (Integration - After Wave 2):
├── Task 8: Flutter 게임 보드 UI
├── Task 9: Flutter 매칭/로비 UI
├── Task 10: Flutter 전적/랭킹 UI
└── Task 11: 통합 테스트 및 마무리

Critical Path: Task 1 → Task 2 → Task 3 → Task 4 → Task 8 → Task 11
```

### Dependency Matrix

| Task | Depends On | Blocks | Parallel With |
|------|------------|--------|---------------|
| 1 | None | 2, 3, 5, 7 | None |
| 2 | 1 | 4, 5, 5a, 6 | 3 |
| 3 | 1 | 4 | 2 |
| 4 | 2, 3 | 8 | 5, 5a, 6 |
| 5 | 2 | 9 | 4, 5a, 6 |
| 5a | 2 | 9, 10 | 4, 5, 6 |
| 6 | 2 | 9 | 4, 5, 5a |
| 7 | 1 | 8, 9, 10 | 2, 3 |
| 8 | 4, 7 | 11 | 9, 10 |
| 9 | 5, 5a, 6, 7 | 11 | 8, 10 |
| 10 | 5a, 7 | 11 | 8, 9 |
| 11 | 8, 9, 10 | None | None |

---

## TODOs

### Wave 1: Foundation

- [x] 1. 프로젝트 구조 및 개발 환경 설정

  **What to do**:
  
  **1.1 .NET 백엔드 스캐폴딩** (server/ 디렉토리):
  ```bash
  cd /home/cyberprophet/source/arena
  mkdir server && cd server
  
  # 솔루션 생성
  dotnet new sln -n Arena
  
  # 프로젝트 생성
  dotnet new webapi -n Arena.Server -o Arena.Server
  dotnet new classlib -n Arena.Models -o Arena.Models
  dotnet new xunit -n Arena.Tests -o Arena.Tests
  
  # 솔루션에 프로젝트 추가
  dotnet sln add Arena.Server/Arena.Server.csproj
  dotnet sln add Arena.Models/Arena.Models.csproj
  dotnet sln add Arena.Tests/Arena.Tests.csproj
  
  # 프로젝트 간 참조
  dotnet add Arena.Server/Arena.Server.csproj reference Arena.Models/Arena.Models.csproj
  dotnet add Arena.Tests/Arena.Tests.csproj reference Arena.Server/Arena.Server.csproj
  dotnet add Arena.Tests/Arena.Tests.csproj reference Arena.Models/Arena.Models.csproj
  
  # NuGet 패키지 설치 (Arena.Server)
  cd Arena.Server
  dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL --version 8.0.0
  dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 8.0.0
  dotnet add package Google.Apis.Auth --version 1.64.0
  dotnet add package AspNetCore.HealthChecks.NpgSql --version 8.0.0
  
  # NuGet 패키지 설치 (Arena.Models)
  cd ../Arena.Models
  dotnet add package Microsoft.EntityFrameworkCore --version 8.0.0
  dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL --version 8.0.0
  dotnet add package Microsoft.EntityFrameworkCore.Design --version 8.0.0
  
  # EF Core CLI 도구 설치 (전역, 한 번만 실행)
  dotnet tool install --global dotnet-ef
  # 이미 설치된 경우: dotnet tool update --global dotnet-ef
  ```

  **1.2 Flutter 프론트엔드 스캐폴딩** (client/ 디렉토리):
  ```bash
  cd /home/cyberprophet/source/arena
  flutter create client --platforms web
  cd client
  
  # 패키지 설치
  flutter pub add flutter_riverpod
  flutter pub add go_router
  flutter pub add signalr_netcore
  flutter pub add google_sign_in
  flutter pub add flutter_screenutil
  ```

  **1.3 PostgreSQL 설정**:
  - `appsettings.Development.json`에 연결 문자열 추가
  - Health check 엔드포인트 구현 (REST API Specification 섹션 참조)

  **1.4 Git 초기화**:
  ```bash
  cd /home/cyberprophet/source/arena
  git init
  # .gitignore 생성 (dotnet + flutter 패턴)
  ```

  **스캐폴딩 완료 후 생성되는 파일 구조**:
  ```
  /home/cyberprophet/source/arena/
  ├── server/
  │   ├── Arena.sln
  │   ├── Arena.Server/
  │   │   ├── Arena.Server.csproj
  │   │   ├── Program.cs              ← Health check, SignalR 설정
  │   │   ├── appsettings.json
  │   │   ├── appsettings.Development.json
  │   │   ├── Controllers/            ← (Task 5에서 생성)
  │   │   └── Hubs/                   ← (Task 4, 6에서 생성)
  │   ├── Arena.Models/
  │   │   ├── Arena.Models.csproj
  │   │   ├── Entities/               ← (Task 2에서 생성)
  │   │   │   ├── User.cs
  │   │   │   ├── Game.cs
  │   │   │   └── MatchQueue.cs
  │   │   ├── ArenaDbContext.cs       ← (Task 2에서 생성)
  │   │   └── Migrations/             ← (Task 2에서 생성)
  │   └── Arena.Tests/
  │       ├── Arena.Tests.csproj
  │       └── (테스트 파일들 - 각 Task에서 TDD로 생성)
  └── client/
      ├── pubspec.yaml
      ├── lib/
      │   ├── main.dart
      │   ├── providers/              ← (Task 7에서 생성)
      │   ├── screens/                ← (Task 8, 9, 10에서 생성)
      │   ├── services/               ← (Task 7에서 생성)
      │   └── widgets/                ← (Task 8에서 생성)
      ├── web/
      │   └── index.html
      └── test/
  ```

  **NOTE**: Task 1은 스캐폴딩만 수행. 빈 폴더(Controllers/, Hubs/, Entities/ 등)는 후속 Task에서 생성됨.

  **파일 참조 규칙**:
  > 이 계획서의 파일 경로 참조(예: `Arena.Server/Program.cs`)는 **Task 1 완료 후 생성되는 템플릿 파일**입니다.
  > 계획 작성 시점에는 해당 파일이 존재하지 않으며, 스캐폴딩 명령 실행 후 생성됩니다.
  > 참조의 권위적 정의는 **이 계획서 내 스펙 섹션**(SignalR Contract, Data Model 등)입니다.

  **Must NOT do**:
  - Docker 설정 (추후 확장)
  - CI/CD 파이프라인
  - 복잡한 폴더 구조

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 프로젝트 초기 설정은 표준 패턴을 따르는 단순 작업
  - **Skills**: [`git-master`]
    - `git-master`: Git 초기화 및 .gitignore 설정

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (must be first)
  - **Blocks**: 2, 3, 5, 7
  - **Blocked By**: None

  **References**:
  - **Internal References** (이 계획서 내):
    - "REST API Specification - Health Check Endpoint" 섹션의 /health 구현
    - "Runtime & Version Requirements" 섹션의 패키지 버전
  - **External References**:
    - .NET CLI 문서: https://learn.microsoft.com/dotnet/core/tools/
    - Flutter CLI 문서: https://docs.flutter.dev/reference/flutter-cli

  **Acceptance Criteria**:
  
  **1. .NET 빌드 검증**:
  ```bash
  cd /home/cyberprophet/source/arena/server
  dotnet build
  # 기대 결과: "Build succeeded." + exit code 0
  ```

  **2. Flutter 빌드 검증**:
  ```bash
  cd /home/cyberprophet/source/arena/client
  flutter run -d chrome --release
  # 기대 결과: Chrome에서 Flutter 기본 앱 표시
  ```

  **3. PostgreSQL 연결 검증**:
  ```bash
  # 서버 실행
  cd /home/cyberprophet/source/arena/server/Arena.Server
  dotnet run &
  
  # Health check 호출 (5초 대기 후)
  sleep 5
  curl -s http://localhost:5000/health | jq
  # 기대 응답:
  # {
  #   "status": "Healthy",
  #   "database": "Connected",
  #   "timestamp": "..."
  # }
  ```

  **4. Git 초기화 검증**:
  ```bash
  cd /home/cyberprophet/source/arena
  git status
  # 기대 결과: "On branch main" 또는 "On branch master"
  ```

  **Commit**: YES
  - Message: `chore: initialize arena project structure`
  - Files: 전체 프로젝트 구조

---

- [x] 2. 데이터 모델 설계 (EF Core)

  **What to do**:
  - `User` 모델: Id, GoogleId, Email, DisplayName, Elo, Wins, Losses, CreatedAt, LastPlayedAt
  - `Game` 모델: Id, BlackPlayerId, WhitePlayerId, WinnerId, Status, CurrentBoardState, CreatedAt, EndedAt
  - `MatchQueue` 모델: Id, UserId, Elo, QueuedAt, ConnectionId
  - EF Core DbContext 설정
  - Migration 생성 및 적용
  - **Note**: "Data Model Specification" 섹션의 정의를 정확히 따를 것

  **Must NOT do**:
  - 게임 리플레이용 상세 Move 히스토리 저장 (CurrentBoardState는 재연결용)
  - 복잡한 인덱스 최적화 (추후)
  - Soft delete 패턴

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: 표준 EF Core 모델링, 복잡하지 않음
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 3)
  - **Blocks**: 4, 5, 6
  - **Blocked By**: 1

  **References**:
  - **Internal References** (이 계획서 내):
    - "Data Model Specification" 섹션의 User, Game, MatchQueue 엔티티 정의
  - **External References**:
    - EF Core Identity: https://learn.microsoft.com/aspnet/core/security/authentication/identity
    - Npgsql EF Core Provider: https://www.npgsql.org/efcore

  **Acceptance Criteria**:
  
  **1. TDD RED 단계**:
  ```bash
  cd /home/cyberprophet/source/arena/server
  # 테스트 먼저 작성 후 실행
  dotnet test --filter "User"
  # 기대 결과: 테스트 실패 (빨간색)
  ```

  **2. TDD GREEN 단계**:
  ```bash
  # 모델 구현 후 테스트 재실행
  dotnet test --filter "User"
  # 기대 결과: 모든 테스트 통과 (녹색)
  ```

  **3. Migration 생성/적용**:
  
  **전제조건** (Task 1에서 완료):
  - `dotnet-ef` 도구 설치됨 (`dotnet tool list -g`로 확인)
  - `Microsoft.EntityFrameworkCore.Design` 패키지 설치됨
  - `appsettings.Development.json`에 PostgreSQL 연결 문자열 설정됨
  
  ```bash
  cd /home/cyberprophet/source/arena/server
  dotnet ef migrations add InitialCreate \
    --project Arena.Models \
    --startup-project Arena.Server
  # 기대 결과: Arena.Models/Migrations/ 폴더에 파일 생성

  dotnet ef database update \
    --project Arena.Models \
    --startup-project Arena.Server
  # 기대 결과: "Done." 출력, PostgreSQL에 테이블 생성됨
  ```

  **4. DB 테이블 검증**:
  ```bash
  # psql 또는 pgAdmin에서 확인
  # 기대 결과: Users, Games, MatchQueues 테이블 존재
  ```

  **Commit**: YES
  - Message: `feat(models): add User, Game, MatchQueue entities`
  - Files: `Arena.Models/`, migrations

---

- [x] 3. 게임 로직 - 렌주룰 엔진 (TDD)

  **What to do**:
  - `GameEngine` 클래스: 보드 상태 관리, 돌 배치, 승리 판정
  - 렌주룰 검증: 3-3, 4-4, 장목(6+) 금지 (흑만)
  - 5목 승리 판정 (가로, 세로, 대각선)
  - 턴 관리 (흑 선공)

  **Must NOT do**:
  - `IGameEngine` 인터페이스 추상화
  - 다른 룰셋 지원
  - 게임 기록 저장 로직

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: 렌주룰 알고리즘은 복잡한 패턴 인식 필요
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: 4
  - **Blocked By**: 1

  **References**:
  - **Internal References** (이 계획서 내):
    - "Game Rules (Renju) - Precise Definition" 섹션의 금지 수 정의 (이 문서가 권위본)
    - "TDD 테스트 케이스 (필수)" 섹션의 테스트 목록
  - **External References**:
    - 렌주룰 위키피디아: https://en.wikipedia.org/wiki/Renju
    - 오목 위키피디아: https://en.wikipedia.org/wiki/Gomoku

  **Acceptance Criteria**:
  - [x] RED: `GameEngineTests.cs` - 빈 보드 생성 테스트
  - [x] RED: 돌 배치 테스트
  - [x] RED: 5목 승리 판정 테스트 (가로/세로/대각선)
  - [x] RED: 3-3 금지 테스트 (흑)
  - [x] RED: 4-4 금지 테스트 (흑)
  - [x] RED: 장목 금지 테스트 (흑)
  - [x] RED: 백은 금지 수 없음 테스트
  - [x] GREEN: 모든 테스트 통과하는 GameEngine 구현
  - [x] `dotnet test --filter "GameEngine"` → 모든 테스트 PASS

  **Commit**: YES
  - Message: `feat(game): implement Renju rule engine with TDD`
  - Files: `Arena.Server/Game/`, `Arena.Tests/GameEngineTests.cs`

---

### Wave 2: Core Features

- [x] 4. SignalR GameHub 구현

  **What to do**:
  - `GameHub` (`/hubs/game`): JoinGame, PlaceStone, Resign 메서드 구현
  - 게임 방 그룹 관리 (ConnectionId 매핑)
  - 30초 턴 타이머 (서버 관리, Timer 클래스 사용)
  - 연결 끊김 30초 대기 후 자동 패배
  - **Server → Client 이벤트** (계약서 참조):
    - `OnGameStarted`, `OnMoveMade`, `OnMoveRejected`
    - `OnTimerUpdate`, `OnGameEnded`
    - `OnOpponentDisconnected`, `OnOpponentReconnected`

  **Must NOT do**:
  - 채팅 기능
  - 관전자 그룹
  - 복잡한 재연결 로직

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 실시간 통신, 상태 관리, 타이머 등 복합 기능
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6)
  - **Blocks**: 8
  - **Blocked By**: 2, 3

  **References**:
  - **Internal References** (이 계획서 내):
    - "SignalR Contract Specification (AUTHORITATIVE)" 섹션의 GameHub 메서드/이벤트 정의
    - "GameHub State Management (AUTHORITATIVE)" 섹션의 상태 관리 방식
    - "Authentication Flow Specification" 섹션의 JWT 연동 방식
  - **External References**:
    - SignalR Hub 문서: https://learn.microsoft.com/aspnet/core/signalr/hubs
    - SignalR Groups: https://learn.microsoft.com/aspnet/core/signalr/groups

  **Acceptance Criteria**:
  - [ ] RED: Hub 연결/해제 테스트
  - [ ] RED: 게임 방 참가 테스트
  - [ ] RED: 돌 배치 브로드캐스트 테스트
  - [ ] RED: 금지 수 거부 테스트
  - [ ] RED: 승리 판정 및 게임 종료 테스트
  - [ ] RED: 타임아웃 자동 패배 테스트
  - [ ] RED: 게임 종료 시 ELO 업데이트 테스트
  - [ ] GREEN: GameHub 구현
  - [ ] 2개 브라우저 탭으로 수동 통합 테스트
  - [ ] 게임 종료 후 DB에서 승자 ELO 증가, 패자 ELO 감소 확인:
    ```sql
    SELECT "Id", "Elo", "Wins", "Losses", "LastPlayedAt" FROM "Users" WHERE "Id" IN ('{winner}', '{loser}');
    ```

  **Commit**: YES
  - Message: `feat(server): implement SignalR GameHub for real-time play`
  - Files: `Arena.Server/Hubs/GameHub.cs`

---

- [x] 5. Google OAuth 인증

  **What to do**:
  - Google OAuth 2.0 설정 (ID Token 검증 방식)
  - JWT 토큰 발급 (만료: 24시간)
  - `AuthController`: POST `/api/auth/google` 엔드포인트
  - SignalR Hub 인증 연동 (query string access_token)
  - 신규 사용자 자동 생성 (초기 ELO: 1200)

  **Must NOT do**:
  - 다른 OAuth 제공자
  - 이메일/비밀번호 로그인
  - 2FA
  - **리프레시 토큰** (MVP에서 제외, 만료 시 재로그인)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: 표준 OAuth 패턴, 기존 코드 재사용
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6)
  - **Blocks**: 9
  - **Blocked By**: 2

  **References**:
  - **Internal References** (이 계획서 내):
    - "Authentication Flow Specification" 섹션의 OAuth 2.0 Web Flow
    - "Required Environment Variables" 섹션
  - **External References**:
    - Google OAuth for Web: https://developers.google.com/identity/gsi/web
    - .NET JWT Bearer 인증: https://learn.microsoft.com/aspnet/core/security/authentication/

  **Acceptance Criteria**:
  
  **1. Google OAuth 테스트** (수동):
  ```
  1. 브라우저에서 Flutter 앱 열기
  2. Google 로그인 버튼 클릭
  3. Google 계정으로 인증
  4. 기대 결과: 로비 화면으로 이동, 사용자 정보 표시
  ```

  **2. JWT 발급 검증**:
  
  **로컬 개발용 테스트 방법 (2가지)**:
  
  **방법 A: 실제 Google ID Token 사용**
  ```
  1. Flutter 앱에서 Google 로그인 수행
  2. 브라우저 개발자 도구 Network 탭에서 /api/auth/google 요청 확인
  3. Request body의 idToken 복사
  4. curl로 동일 요청 재현
  ```
  
  **방법 B: 개발 환경 전용 우회 (Development Only)**
  ```csharp
  // Program.cs 또는 AuthController.cs
  #if DEBUG
  // 개발 환경에서 "dev_bypass_token"을 idToken으로 전송하면
  // Google API 호출 없이 테스트 사용자로 인증
  if (request.IdToken == "dev_bypass_token")
  {
      return CreateTestUser(request.Email, request.DisplayName);
  }
  #endif
  ```
  
  **개발 환경 테스트 명령**:
  ```bash
  curl -X POST http://localhost:5000/api/auth/google \
    -H "Content-Type: application/json" \
    -d '{"idToken": "dev_bypass_token", "email": "test@gmail.com", "displayName": "Test User"}'
  
  # 기대 응답 (200 OK):
  # {
  #   "access_token": "eyJhbG...",
  #   "expires_in": 86400,
  #   "user": {"id": "...", "elo": 1200, "wins": 0, "losses": 0}
  # }
  ```
  
  **WARNING**: `dev_bypass_token` 우회는 반드시 `#if DEBUG` 또는 환경 변수로 Production에서 비활성화

  **3. SignalR 인증 검증**:
  ```bash
  # 유효한 JWT로 SignalR 연결
  # wscat 또는 SignalR 테스트 클라이언트 사용
  # 기대 결과: 연결 성공

  # 잘못된 JWT로 연결 시도
  # 기대 결과: 401 Unauthorized 또는 연결 거부
  ```

  **4. 신규 사용자 DB 생성 확인**:
  ```sql
  SELECT * FROM "Users" WHERE "Email" = 'test@gmail.com';
  -- 기대 결과: 1개 행, Elo=1200, Wins=0, Losses=0
  ```

  **Commit**: YES
  - Message: `feat(auth): implement Google OAuth with JWT`
  - Files: AuthController.cs, AuthService.cs 등

---

- [x] 5a. REST API 컨트롤러 (Users, Rankings)

  **What to do**:
  - `UsersController.cs`: GET `/api/users/me` - 내 프로필 조회
  - `RankingsController.cs`: GET `/api/rankings` - Top N 랭킹 조회
  - ELO 기반 랭킹 정렬 (동률 시 승수 → 가입일 순)

  **Must NOT do**:
  - 다른 사용자 프로필 조회
  - 프로필 수정 API
  - 무한 스크롤/페이지네이션

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 단순 CRUD API, 복잡한 로직 없음
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6)
  - **Blocks**: 9, 10
  - **Blocked By**: 2

  **References**:
  - **Internal References** (이 계획서 내):
    - "REST API Specification" 섹션의 `/api/users/me`, `/api/rankings`
    - "Ranking & Statistics Rules" 섹션의 정렬/계산 규칙
    - "Data Model Specification" 섹션의 User 엔티티

  **Acceptance Criteria**:
  
  **1. GET /api/users/me 검증**:
  ```bash
  # JWT 토큰으로 API 호출
  curl -s http://localhost:5000/api/users/me \
    -H "Authorization: Bearer {jwt_token}" | jq
  
  # 기대 응답:
  # {
  #   "id": "uuid",
  #   "displayName": "Test User",
  #   "email": "test@gmail.com",
  #   "elo": 1200,
  #   "wins": 5,
  #   "losses": 3,
  #   "winRate": 62.5,       // (5/8)*100
  #   "gamesPlayed": 8,      // 5+3
  #   "rank": 47             // 전체 순위
  # }
  ```
  
  **winRate/gamesPlayed 계산 검증**:
  ```sql
  -- 0경기 사용자
  SELECT * FROM "Users" WHERE "Wins" = 0 AND "Losses" = 0;
  -- API 응답: winRate=0, gamesPlayed=0
  ```

  **2. GET /api/rankings 검증**:
  ```bash
  curl -s "http://localhost:5000/api/rankings?limit=10" \
    -H "Authorization: Bearer {jwt_token}" | jq
  
  # 기대 응답:
  # {
  #   "rankings": [
  #     { "rank": 1, "userId": "...", "displayName": "Top", "elo": 1500, "wins": 30, "losses": 5 },
  #     { "rank": 2, ... }
  #   ],
  #   "myRank": 47
  # }
  ```
  
  **정렬 규칙 검증**: ELO 동률 시 승수 → 가입일 순
  ```sql
  -- 동률 사용자 생성 후 API 호출, 순서 확인
  INSERT INTO "Users" VALUES (..., elo=1300, wins=10, ...);
  INSERT INTO "Users" VALUES (..., elo=1300, wins=15, ...);
  -- 승수 15인 사용자가 상위
  ```

  **Commit**: YES
  - Message: `feat(api): implement users and rankings REST endpoints`
  - Files: UsersController.cs, RankingsController.cs

---

- [x] 6. 매칭 시스템 구현

  **What to do**:
  - `MatchmakingHub` (`/hubs/matchmaking`): JoinMatchmaking, LeaveMatchmaking
  - `MatchmakingService`: 대기열 등록, 매칭 알고리즘 (Background Service)
  - ELO ±200 범위 매칭, 30초마다 ±50 확장, 최대 3분 후 아무나 매칭
  - 매칭 성공 시 Game 생성, `OnMatchFound` 이벤트 전송
  - 대기열: PostgreSQL MatchQueue 테이블 (서버 재시작 시 유지)
  - **Server → Client 이벤트**: `OnMatchFound`, `OnMatchmakingStatus`

  **Must NOT do**:
  - 복잡한 매칭 알고리즘 (MMR, 승률 보정 등)
  - Redis 기반 대기열
  - 매칭 통계 저장

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: 비교적 단순한 매칭 로직
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5)
  - **Blocks**: 9
  - **Blocked By**: 2

  **References**:
  - **Internal References** (이 계획서 내):
    - "ELO Rating System" 섹션의 공식
    - "Matchmaking Queue Implementation" 섹션의 알고리즘
    - "SignalR Contract Specification (AUTHORITATIVE) - MatchmakingHub" 섹션
  - **External References**:
    - ELO Rating 위키: https://en.wikipedia.org/wiki/Elo_rating_system

  **Acceptance Criteria**:
  - [ ] RED: 대기열 등록/취소 테스트
  - [ ] RED: ELO 범위 내 매칭 테스트
  - [ ] RED: 범위 확장 테스트 (30초 후)
  - [ ] RED: ELO 계산 테스트 (K=32)
  - [ ] GREEN: MatchmakingService 구현
  - [ ] `dotnet test --filter "Matchmaking"` → 모든 테스트 PASS

  **Commit**: YES
  - Message: `feat(matchmaking): implement ELO-based matching system`
  - Files: `Arena.Server/Services/MatchmakingService.cs`

---

- [x] 7. Flutter 기본 구조 및 라우팅

  **What to do**:
  - Riverpod 상태 관리 설정
  - GoRouter 라우팅 설정
  - 화면 구조: `/login`, `/lobby`, `/game/:id`, `/ranking`, `/profile`
  - SignalR 클라이언트 연결 서비스
  - 공통 위젯 (AppBar, Loading 등)

  **Must NOT do**:
  - 복잡한 테마 시스템
  - 다국어 지원
  - 반응형 레이아웃 (데스크톱 고정)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Flutter UI 구조 및 라우팅
  - **Skills**: [`frontend-ui-ux`]
    - `frontend-ui-ux`: UI/UX 설계

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1-2 bridge (after Task 1)
  - **Blocks**: 8, 9, 10
  - **Blocked By**: 1

  **References**:
  - **External References**:
    - Riverpod 공식 문서: https://riverpod.dev/docs/introduction/getting_started
    - GoRouter 공식 문서: https://pub.dev/packages/go_router
    - signalr_netcore 패키지: https://pub.dev/packages/signalr_netcore
    - Flutter ScreenUtil: https://pub.dev/packages/flutter_screenutil

  **Acceptance Criteria**:
  - [ ] `flutter run -d chrome` 성공
  - [ ] 각 라우트 네비게이션 동작
  - [ ] SignalR 연결 테스트 (콘솔 로그)
  - [ ] Riverpod Provider 기본 동작

  **Commit**: YES
  - Message: `feat(client): setup Flutter with Riverpod and GoRouter`
  - Files: `client/lib/`

---

### Wave 3: Integration

- [x] 8. Flutter 게임 보드 UI

  **What to do**:
  - 15×15 오목 보드 렌더링
  - 돌 배치 터치/클릭 처리
  - 실시간 상대 돌 표시 (SignalR 연동)
  - 30초 타이머 UI
  - 금지 수 시각적 피드백 (빨간 X)
  - 게임 종료 다이얼로그 (승/패)
  - 기권 버튼

  **Must NOT do**:
  - 복잡한 애니메이션
  - 돌 배치 사운드
  - 게임 기록 표시

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: 게임 보드 UI, 인터랙션 디자인
  - **Skills**: [`frontend-ui-ux`, `playwright`]
    - `frontend-ui-ux`: UI/UX 구현
    - `playwright`: 브라우저 테스트

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 9, 10)
  - **Blocks**: 11
  - **Blocked By**: 4, 7

  **References**:
  - **Internal References** (이 계획서 내):
    - "SignalR Contract Specification (AUTHORITATIVE) - GameHub" 섹션
  - **External References**:
    - Flutter CustomPainter: https://api.flutter.dev/flutter/rendering/CustomPainter-class.html
    - signalr_netcore 패키지: https://pub.dev/packages/signalr_netcore

  **Acceptance Criteria**:
  - [ ] Widget Test: 빈 보드 렌더링
  - [ ] Widget Test: 돌 배치 터치 이벤트
  - [ ] Widget Test: 타이머 카운트다운
  - [ ] 수동 테스트: 2개 탭에서 실시간 대전
  - [ ] 수동 테스트: 금지 수 시 빨간 X 표시
  - [ ] 수동 테스트: 5목 완성 시 승리 다이얼로그

  **Commit**: YES
  - Message: `feat(client): implement game board UI with real-time sync`
  - Files: `client/lib/screens/game/`, `client/lib/widgets/board/`

---

- [x] 9. Flutter 매칭/로비 UI

  **What to do**:
  - 로비 화면: "매칭 찾기" 버튼, 사용자 정보 표시
  - 매칭 대기 UI: 로딩 애니메이션, 취소 버튼, 대기 시간
  - 매칭 성공 시 게임 화면 자동 이동
  - 로그인 화면: Google 로그인 버튼

  **Must NOT do**:
  - 친구 목록
  - 방 생성/참가
  - 복잡한 로비 채팅

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI/UX 화면 구현
  - **Skills**: [`frontend-ui-ux`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 10)
  - **Blocks**: 11
  - **Blocked By**: 5, 6, 7

  **References**:
  - **Internal References** (이 계획서 내):
    - "REST API Specification" 섹션의 `/api/auth/google`, `/api/users/me`
    - "SignalR Contract Specification (AUTHORITATIVE) - MatchmakingHub" 섹션
  - **External References**:
    - google_sign_in 패키지: https://pub.dev/packages/google_sign_in

  **Acceptance Criteria**:
  - [ ] Google 로그인 버튼 동작
  - [ ] 로비에서 사용자 ELO, 전적 표시
  - [ ] "매칭 찾기" 클릭 시 대기 UI
  - [ ] 매칭 성공 시 `/game/:id`로 이동
  - [ ] 매칭 취소 기능 동작

  **Commit**: YES
  - Message: `feat(client): implement lobby and matchmaking UI`
  - Files: `client/lib/screens/login/`, `client/lib/screens/lobby/`

---

- [x] 10. Flutter 전적/랭킹 UI

  **What to do**:
  - 프로필 화면: ELO, 승, 패, 승률, 게임 수
  - 랭킹 화면: Top 100 리더보드
  - 내 순위 표시

  **Must NOT do**:
  - 게임 히스토리 상세
  - 프로필 커스터마이징
  - 무한 스크롤 페이지네이션

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: 데이터 표시 UI
  - **Skills**: [`frontend-ui-ux`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9)
  - **Blocks**: 11
  - **Blocked By**: 2, 7

  **References**:
  - **Internal References** (이 계획서 내):
    - "REST API Specification" 섹션의 `/api/users/me`, `/api/rankings`
  - **External References**:
    - Flutter ListView: https://api.flutter.dev/flutter/widgets/ListView-class.html

  **Acceptance Criteria**:
  - [ ] 프로필에서 내 전적 표시
  - [ ] 랭킹 Top 100 목록 로드
  - [ ] 내 순위 하이라이트
  - [ ] API 에러 시 에러 UI 표시

  **Commit**: YES
  - Message: `feat(client): implement profile and ranking UI`
  - Files: `client/lib/screens/profile/`, `client/lib/screens/ranking/`

---

- [x] 11. 통합 테스트 및 마무리

  **What to do**:
  - End-to-End 시나리오 테스트
  - 버그 수정 및 폴리싱
  - README 작성
  - 환경 변수 정리

  **Must NOT do**:
  - 성능 최적화
  - 배포 자동화
  - 상세 문서화

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: 마무리 작업
  - **Skills**: [`playwright`, `git-master`]
    - `playwright`: E2E 테스트
    - `git-master`: 최종 커밋 정리

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (final)
  - **Blocks**: None
  - **Blocked By**: 8, 9, 10

  **References**: N/A

  **Acceptance Criteria**:
  - [ ] E2E: 회원가입 → 매칭 → 게임 → 결과 확인 시나리오
  - [ ] E2E: 타임아웃 자동 패배 시나리오
  - [ ] E2E: 연결 끊김 재연결 시나리오
  - [ ] 모든 테스트 통과: `dotnet test` && `flutter test`
  - [ ] README.md 작성 완료

  **Commit**: YES
  - Message: `chore: finalize MVP with integration tests and docs`
  - Files: README.md, 테스트 파일들

---

## Commit Strategy

| After Task | Message | Verification |
|------------|---------|--------------|
| 1 | `chore: initialize arena project structure` | `dotnet build && flutter run -d chrome` |
| 2 | `feat(models): add User, Game, MatchQueue entities` | `dotnet test` |
| 3 | `feat(game): implement Renju rule engine with TDD` | `dotnet test --filter "GameEngine"` |
| 4 | `feat(server): implement SignalR GameHub` | Integration test |
| 5 | `feat(auth): implement Google OAuth with JWT` | Manual OAuth flow |
| 6 | `feat(matchmaking): implement ELO-based matching` | `dotnet test --filter "Matchmaking"` |
| 7 | `feat(client): setup Flutter with Riverpod and GoRouter` | `flutter run -d chrome` |
| 8 | `feat(client): implement game board UI` | Widget tests + manual |
| 9 | `feat(client): implement lobby and matchmaking UI` | Manual flow |
| 10 | `feat(client): implement profile and ranking UI` | Manual verification |
| 11 | `chore: finalize MVP with integration tests` | Full test suite |

---

## Success Criteria

### Verification Commands
```bash
# Backend tests
cd /home/cyberprophet/source/arena/server
dotnet test  # Expected: All tests pass

# Frontend tests
cd /home/cyberprophet/source/arena/client
flutter test  # Expected: All tests pass

# Run both
# Terminal 1: dotnet run (server)
# Terminal 2: flutter run -d chrome (client)
# Open 2 browser tabs, login with different Google accounts, play a game
```

### Final Checklist
- [x] Google 로그인 동작
- [x] 랜덤 매칭 동작
- [x] 오목 대전 실시간 동기화
- [x] 렌주룰 정상 작동
- [x] 30초 타이머 동작
- [x] ELO 변동 확인
- [x] 랭킹 페이지 동작
- [x] 모든 테스트 통과

---

## Technical Specifications

### ELO Rating System
- **Initial ELO**: 1200
- **K-Factor**: 32
- **Formula**: 
  - Expected: `E = 1 / (1 + 10^((Rb - Ra) / 400))`
  - New Rating: `Ra' = Ra + K * (S - E)` (S = 1 win, 0 loss)

**ELO 갱신 시점**: 게임 종료 즉시 (OnGameEnded 이벤트 전)
**DB 업데이트 항목**: `User.Elo`, `User.Wins` or `User.Losses`, `User.LastPlayedAt`

**ELO 정수 변환 규칙**:
```csharp
// ELO 계산 결과는 실수 → int로 변환 필요
// 규칙: Math.Round (반올림, MidpointRounding.AwayFromZero)

int newElo = (int)Math.Round(oldElo + K * (S - E), MidpointRounding.AwayFromZero);

// 예시:
// 1200 + 32 * (1 - 0.5) = 1216.0 → 1216
// 1200 + 32 * (1 - 0.6) = 1212.8 → 1213
// 1200 + 32 * (0 - 0.5) = 1184.0 → 1184
```

**동률/무승부 처리**: 렌주에서는 무승부 불가 (항상 승패 결정)
**Abandoned 게임**: ELO 변동 없음 (위 `server_shutdown` 참조)

### Ranking & Statistics Rules

**랭킹 정렬 기준**:
1. ELO 내림차순 (높을수록 상위)
2. 동률 처리: 승리 수 내림차순
3. 여전히 동률: 먼저 가입한 사용자 상위 (CreatedAt 오름차순)

**통계 계산식**:
```
gamesPlayed = wins + losses
winRate = (wins == 0 && losses == 0) ? 0 : (wins / gamesPlayed) * 100
```
- 0경기 사용자: `winRate = 0`, `gamesPlayed = 0`
- 소수점: 1자리까지 표시 (예: 65.3%)

**`/api/rankings` 응답 예시**:
```json
{
  "rankings": [
    { "rank": 1, "userId": "...", "displayName": "Player1", "elo": 1450, "wins": 25, "losses": 10 },
    { "rank": 2, "userId": "...", "displayName": "Player2", "elo": 1420, "wins": 20, "losses": 8 }
  ],
  "myRank": 47
}
```

### Matchmaking
- **Initial Range**: ±200 ELO
- **Expansion**: +50 every 30 seconds
- **Max Wait**: 3 minutes (then match anyone)

### Game Rules (Renju) - Precise Definition

**Board**: 15×15 (좌표: 0-14, 중앙 H8 = (7,7))
**Win Condition**: 정확히 5개의 연속된 돌 (가로, 세로, 대각선)
**First Move**: 흑(Black)이 선공

---

#### 흑(Black) 금지 수 상세 정의 (백은 제한 없음)

**1. 열린 3 (Open Three) 정의**:
```
열린 3: 양 끝에 빈 칸이 있고, 연속 또는 한 칸 띄어진 3개의 돌

패턴 (O=흑돌, _=빈칸, X=막힘):
- 연속형: _OOO_  (양 끝이 빈 칸)
- 띄어진형: _OO_O_, _O_OO_ (한 칸 띄어짐, 양 끝 빈 칸)

열린 3이 아닌 경우:
- XOOO_  (한쪽이 막힘 → 닫힌 3)
- _O_O_O_ (두 칸 띄어짐 → 열린 3 아님)
```

**2. 3-3 (Double Three) 금지**:
```
정의: 한 수로 열린 3이 2개 이상 동시에 생성되는 경우

예시 (O=기존 흑돌, *=금지 수 위치):
    0 1 2 3 4 5
  0 _ _ _ _ _ _
  1 _ _ O _ _ _
  2 _ O * _ _ _  ← (2,2)에 두면 가로 열린3 + 세로 열린3 → 금지
  3 _ _ O _ _ _
  4 _ _ _ _ _ _

검증 로직:
1. 해당 위치에 돌을 가상 배치
2. 8방향 스캔하여 열린 3 개수 카운트
3. 열린 3 >= 2 → 금지
```

**3. 4 (Four) 정의**:
```
4: 연속 4개의 돌 (열린/닫힌 무관)

패턴:
- 열린 4: _OOOO_
- 닫힌 4: XOOOO_, _OOOOX
- 띄어진 4: _OOO_O_, _O_OOO_ (한 칸 띄어져도 4로 인정)
```

**4. 4-4 (Double Four) 금지**:
```
정의: 한 수로 4가 2개 이상 동시에 생성되는 경우

예시:
- 가로 4 + 세로 4 동시 → 금지
- 가로 4 + 대각선 4 동시 → 금지

검증 로직:
1. 해당 위치에 돌을 가상 배치
2. 8방향 스캔하여 4 개수 카운트
3. 4 >= 2 → 금지
```

**5. 장목 (Overline) 금지**:
```
정의: 6개 이상 연속으로 놓이는 경우

예시: OOOOOO (6목), OOOOOOO (7목) → 금지, 승리 아님

검증 로직:
1. 해당 위치에 돌을 가상 배치
2. 4방향(가로/세로/대각2)에서 연속 돌 개수 확인
3. 연속 >= 6 → 금지
```

---

#### 우선순위 및 특수 케이스

**금지수 + 5목 동시 발생**:
```
규칙: 5목이 금지수보다 우선

케이스 1: 3-3/4-4 위치에 두면 정확히 5목 완성
→ 5목 승리 (금지수 무시)

케이스 2: 장목(6+) 위치에 두면 6목 이상 완성
→ 금지수 (승리 아님, 돌 놓이지 않음)

케이스 3: 3-3 위치에 두면 4목 완성 (5목 아님)
→ 금지수 (돌 놓이지 않음)
```

**백(White)의 장목**:
```
백은 6목 이상도 승리로 인정
예: 백이 6연속 → 백 승리
```

---

#### TDD 테스트 케이스 (필수)

```csharp
// GameEngineTests.cs 필수 테스트 케이스

// 기본 테스트
[Fact] void EmptyBoard_IsValid()
[Fact] void PlaceStone_UpdatesBoard()
[Fact] void FiveInRow_Horizontal_BlackWins()
[Fact] void FiveInRow_Vertical_BlackWins()
[Fact] void FiveInRow_Diagonal_BlackWins()

// 3-3 금지 테스트
[Fact] void DoubleThree_Blocked_ForBlack()
[Fact] void DoubleThree_Allowed_ForWhite()
[Fact] void DoubleThree_WithGap_Blocked()  // 띄어진 열린3 포함

// 4-4 금지 테스트
[Fact] void DoubleFour_Blocked_ForBlack()
[Fact] void DoubleFour_OpenAndClosed_Blocked()  // 열린4 + 닫힌4

// 장목 금지 테스트
[Fact] void Overline_Six_Blocked_ForBlack()
[Fact] void Overline_Seven_Blocked_ForBlack()
[Fact] void Overline_Six_Allowed_ForWhite()  // 백은 6목 승리

// 우선순위 테스트
[Fact] void FiveInRow_OverridesDoubleThree()  // 5목 > 3-3
[Fact] void FiveInRow_OverridesDoubleFour()   // 5목 > 4-4
[Fact] void Overline_NotOverriddenByFive()    // 6목은 여전히 금지
```

---

**금지 수 처리**:
- 서버가 검증, 클라이언트에 `OnMoveRejected` 이벤트 전송
- 금지 수는 돌이 놓이지 않음, 플레이어 턴 유지
- 타이머는 계속 흐름 (금지 수로 시간 벌기 불가)

**Turn Timer**: 30 seconds
**Timeout**: Auto-loss (타임아웃 플레이어 패배)
**Disconnect**: 30 seconds grace period, then auto-loss
