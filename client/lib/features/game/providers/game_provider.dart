import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../auth/providers/auth_provider.dart';
import '../services/game_hub_service.dart';
import 'game_state.dart';

final gameHubServiceProvider = Provider<GameHubService>((ref) {
  final authState = ref.watch(authProvider);
  final service = GameHubService();
  service.setToken(authState.token);
  return service;
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final hubService = ref.watch(gameHubServiceProvider);
  return GameNotifier(hubService);
});

class GameNotifier extends StateNotifier<GameState> {
  final GameHubService _hubService;

  GameNotifier(this._hubService) : super(GameState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _hubService.onGameStarted = (data) {
      state = state.copyWith(
        gameId: data['gameId'] as String?,
        status: GameStatus.inProgress,
        myColor: data['yourColor'] as String?,
        currentTurn: 'black',
        remainingSeconds: 30,
      );
    };

    _hubService.onMoveMade = (data) {
      final x = data['x'] as int;
      final y = data['y'] as int;
      final color = data['color'] as String;
      final remainingTime = data['remainingTime'] as int?;

      final newBoard = List<List<int>>.from(
        state.board.map((row) => List<int>.from(row)),
      );
      newBoard[y][x] = color == 'black' ? 1 : 2;

      state = state.copyWith(
        board: newBoard,
        currentTurn: color == 'black' ? 'white' : 'black',
        remainingSeconds: remainingTime ?? 30,
      );
    };

    _hubService.onMoveRejected = (data) {
      state = state.copyWith(errorMessage: data['reason'] as String?);
    };

    _hubService.onGameEnded = (data) {
      final eloChangeData = data['eloChange'] as Map<String, dynamic>?;
      final myColorIsWinner =
          state.winnerId != null &&
          ((state.myColor == 'black' && data['winnerId'] == state.gameId) ||
              (state.myColor == 'white' && data['winnerId'] != state.gameId));

      state = state.copyWith(
        status: GameStatus.ended,
        winnerId: data['winnerId'] as String?,
        endReason: data['reason'] as String?,
        eloChange: myColorIsWinner
            ? (eloChangeData?['winner'] as int?)
            : eloChangeData?['loser'] as int?,
      );
    };

    _hubService.onTimerUpdate = (data) {
      state = state.copyWith(
        currentTurn: data['currentPlayer'] as String?,
        remainingSeconds: data['remainingSeconds'] as int? ?? 30,
      );
    };

    _hubService.onOpponentDisconnected = (data) {
      state = state.copyWith(opponentConnected: false);
    };

    _hubService.onOpponentReconnected = (data) {
      state = state.copyWith(opponentConnected: true);
    };

    _hubService.onGameResumed = (data) {
      final boardData = data['board'] as List<dynamic>?;
      if (boardData != null) {
        final newBoard = List.generate(
          15,
          (y) => List.generate(15, (x) => boardData[y * 15 + x] as int),
        );
        state = state.copyWith(
          board: newBoard,
          status: GameStatus.inProgress,
          myColor: data['yourColor'] as String?,
          currentTurn: data['currentTurn'] as String?,
          remainingSeconds: data['remainingSeconds'] as int? ?? 30,
          opponentConnected: data['opponentConnected'] as bool? ?? true,
        );
      }
    };
  }

  Future<void> joinGame(String gameId) async {
    state = state.copyWith(gameId: gameId, status: GameStatus.connecting);

    try {
      await _hubService.connect();
      await _hubService.joinGame(gameId);
    } catch (e) {
      state = state.copyWith(
        status: GameStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> placeStone(int x, int y) async {
    if (state.gameId == null || !state.isMyTurn || state.isGameOver) {
      return;
    }

    try {
      await _hubService.placeStone(state.gameId!, x, y);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> resign() async {
    if (state.gameId == null || state.isGameOver) {
      return;
    }

    try {
      await _hubService.resign(state.gameId!);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> leaveGame() async {
    await _hubService.disconnect();
    state = GameState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
