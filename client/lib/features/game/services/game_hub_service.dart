import '../../../shared/services/signalr_service.dart';
import '../../../core/constants/api_constants.dart';

typedef GameEventCallback = void Function(Map<String, dynamic> data);

class GameHubService {
  final SignalRService _signalR;
  
  GameEventCallback? onGameStarted;
  GameEventCallback? onMoveMade;
  GameEventCallback? onMoveRejected;
  GameEventCallback? onGameEnded;
  GameEventCallback? onTimerUpdate;
  GameEventCallback? onOpponentDisconnected;
  GameEventCallback? onOpponentReconnected;
  GameEventCallback? onGameResumed;

  GameHubService() : _signalR = SignalRService(ApiConstants.gameHub);

  void setToken(String? token) {
    _signalR.setToken(token);
  }

  Future<void> connect() async {
    await _signalR.connect();
    _setupListeners();
  }

  Future<void> disconnect() async {
    await _signalR.disconnect();
  }

  void _setupListeners() {
    _signalR.on('OnGameStarted', (args) {
      if (args != null && args.isNotEmpty) {
        onGameStarted?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnMoveMade', (args) {
      if (args != null && args.isNotEmpty) {
        onMoveMade?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnMoveRejected', (args) {
      if (args != null && args.isNotEmpty) {
        onMoveRejected?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnGameEnded', (args) {
      if (args != null && args.isNotEmpty) {
        onGameEnded?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnTimerUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        onTimerUpdate?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnOpponentDisconnected', (args) {
      if (args != null && args.isNotEmpty) {
        onOpponentDisconnected?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnOpponentReconnected', (args) {
      if (args != null && args.isNotEmpty) {
        onOpponentReconnected?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnGameResumed', (args) {
      if (args != null && args.isNotEmpty) {
        onGameResumed?.call(_toMap(args[0]));
      }
    });
  }

  Future<void> joinGame(String gameId) async {
    await _signalR.invoke('JoinGame', [gameId]);
  }

  Future<void> placeStone(String gameId, int x, int y) async {
    await _signalR.invoke('PlaceStone', [gameId, x, y]);
  }

  Future<void> resign(String gameId) async {
    await _signalR.invoke('Resign', [gameId]);
  }

  Map<String, dynamic> _toMap(Object? obj) {
    if (obj is Map) {
      return Map<String, dynamic>.from(obj);
    }
    return {};
  }
}
