import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/matchmaking_hub_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'matchmaking_state.dart';

final matchmakingHubServiceProvider = Provider<MatchmakingHubService>((ref) {
  final authState = ref.watch(authProvider);
  final service = MatchmakingHubService();
  service.setToken(authState.token);
  return service;
});

final matchmakingProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>((ref) {
      final hubService = ref.watch(matchmakingHubServiceProvider);
      return MatchmakingNotifier(hubService);
    });

class MatchmakingNotifier extends StateNotifier<MatchmakingState> {
  final MatchmakingHubService _hubService;

  MatchmakingNotifier(this._hubService) : super(const MatchmakingState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _hubService.onMatchmakingStatus = (data) {
      state = state.copyWith(
        status: MatchmakingStatus.searching,
        waitingSeconds:
            (data['waitingSeconds'] as int?) ?? state.waitingSeconds,
        currentRange: (data['currentRange'] as int?) ?? state.currentRange,
      );
    };

    _hubService.onMatchFound = (data) {
      state = state.copyWith(
        status: MatchmakingStatus.found,
        gameId: data['gameId'] as String?,
        opponentName: data['opponentName'] as String?,
        myColor: data['yourColor'] as String?,
      );
    };

    _hubService.onError = (data) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: data['message'] as String?,
      );
    };
  }

  Future<void> startSearching() async {
    state = state.copyWith(status: MatchmakingStatus.connecting);

    try {
      await _hubService.connect();
      await _hubService.joinMatchmaking();
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelSearch() async {
    try {
      await _hubService.leaveMatchmaking();
      await _hubService.disconnect();
      state = const MatchmakingState();
    } catch (e) {
      state = state.copyWith(
        status: MatchmakingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const MatchmakingState();
  }
}
