enum MatchmakingStatus {
  idle,
  connecting,
  searching,
  found,
  error,
}

class MatchmakingState {
  final MatchmakingStatus status;
  final String? gameId;
  final String? opponentName;
  final int? opponentElo;
  final String? myColor;
  final String? errorMessage;

  const MatchmakingState({
    this.status = MatchmakingStatus.idle,
    this.gameId,
    this.opponentName,
    this.opponentElo,
    this.myColor,
    this.errorMessage,
  });

  MatchmakingState copyWith({
    MatchmakingStatus? status,
    String? gameId,
    String? opponentName,
    int? opponentElo,
    String? myColor,
    String? errorMessage,
  }) {
    return MatchmakingState(
      status: status ?? this.status,
      gameId: gameId ?? this.gameId,
      opponentName: opponentName ?? this.opponentName,
      opponentElo: opponentElo ?? this.opponentElo,
      myColor: myColor ?? this.myColor,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isSearching => status == MatchmakingStatus.searching;
  bool get isMatchFound => status == MatchmakingStatus.found;
}
