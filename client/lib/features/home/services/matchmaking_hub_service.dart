import '../../../shared/services/signalr_service.dart';
import '../../../core/constants/api_constants.dart';

typedef MatchEventCallback = void Function(Map<String, dynamic> data);

class MatchmakingHubService {
  final SignalRService _signalR;
  
  MatchEventCallback? onQueueJoined;
  MatchEventCallback? onQueueLeft;
  MatchEventCallback? onMatchFound;
  MatchEventCallback? onError;

  MatchmakingHubService() : _signalR = SignalRService(ApiConstants.matchmakingHub);

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
    _signalR.on('OnQueueJoined', (args) {
      if (args != null && args.isNotEmpty) {
        onQueueJoined?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnQueueLeft', (args) {
      if (args != null && args.isNotEmpty) {
        onQueueLeft?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnMatchFound', (args) {
      if (args != null && args.isNotEmpty) {
        onMatchFound?.call(_toMap(args[0]));
      }
    });

    _signalR.on('OnError', (args) {
      if (args != null && args.isNotEmpty) {
        onError?.call(_toMap(args[0]));
      }
    });
  }

  Future<void> joinQueue() async {
    await _signalR.invoke('JoinQueue');
  }

  Future<void> leaveQueue() async {
    await _signalR.invoke('LeaveQueue');
  }

  Map<String, dynamic> _toMap(Object? obj) {
    if (obj is Map) {
      return Map<String, dynamic>.from(obj);
    }
    return {};
  }
}
