enum MatchmakingStatus { idle, connecting, searching, found, error }

class MatchmakingState {
  final MatchmakingStatus status;
  final String? gameId;
  final String? opponentName;
  final int? opponentElo;
  final String? myColor;
  final int waitingSeconds;
  final int currentRange;
  final String? errorMessage;

  const MatchmakingState({
    this.status = MatchmakingStatus.idle,
    this.gameId,
    this.opponentName,
    this.opponentElo,
    this.myColor,
    this.waitingSeconds = 0,
    this.currentRange = 200,
    this.errorMessage,
  });

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    String? gameId,
    String? opponentName,
    int? opponentElo,
    String? myColor,
    int? waitingSeconds,
    int? currentRange,
    String? errorMessage,
  }) {
    return MatchmakingState(
      status: status ?? this.status,
      gameId: gameId ?? this.gameId,
      opponentName: opponentName ?? this.opponentName,
      opponentElo: opponentElo ?? this.opponentElo,
      myColor: myColor ?? this.myColor,
      waitingSeconds: waitingSeconds ?? this.waitingSeconds,
      currentRange: currentRange ?? this.currentRange,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isSearching => status == MatchmakingStatus.searching;
  bool get isMatchFound => status == MatchmakingStatus.found;
}
