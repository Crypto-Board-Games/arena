enum GameStatus {
  initial,
  connecting,
  waitingForOpponent,
  inProgress,
  ended,
  error,
}

class GameState {
  final String? gameId;
  final GameStatus status;
  final List<List<int>> board;
  final String? myColor;
  final String? currentTurn;
  final int remainingSeconds;
  final String? opponentName;
  final int? opponentElo;
  final String? winnerId;
  final String? endReason;
  final int? eloChange;
  final bool opponentConnected;
  final String? errorMessage;

  GameState({
    this.gameId,
    this.status = GameStatus.initial,
    List<List<int>>? board,
    this.myColor,
    this.currentTurn,
    this.remainingSeconds = 30,
    this.opponentName,
    this.opponentElo,
    this.winnerId,
    this.endReason,
    this.eloChange,
    this.opponentConnected = true,
    this.errorMessage,
  }) : board = board ?? List.generate(15, (_) => List.filled(15, 0));

  GameState copyWith({
    String? gameId,
    GameStatus? status,
    List<List<int>>? board,
    String? myColor,
    String? currentTurn,
    int? remainingSeconds,
    String? opponentName,
    int? opponentElo,
    String? winnerId,
    String? endReason,
    int? eloChange,
    bool? opponentConnected,
    String? errorMessage,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      status: status ?? this.status,
      board: board ?? this.board,
      myColor: myColor ?? this.myColor,
      currentTurn: currentTurn ?? this.currentTurn,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      opponentName: opponentName ?? this.opponentName,
      opponentElo: opponentElo ?? this.opponentElo,
      winnerId: winnerId ?? this.winnerId,
      endReason: endReason ?? this.endReason,
      eloChange: eloChange ?? this.eloChange,
      opponentConnected: opponentConnected ?? this.opponentConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isMyTurn => currentTurn == myColor;
  
  bool get isGameOver => status == GameStatus.ended;
}
