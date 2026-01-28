import 'package:signalr_netcore/signalr_client.dart';
import '../../core/constants/api_constants.dart';

class SignalRService {
  HubConnection? _connection;
  final String _hubPath;
  String? _token;
  bool _isConnected = false;

  SignalRService(this._hubPath);

  bool get isConnected => _isConnected;

  void setToken(String? token) {
    _token = token;
  }

  Future<void> connect() async {
    if (_connection != null && _isConnected) {
      return;
    }

    final url = '${ApiConstants.baseUrl}$_hubPath?access_token=$_token';
    
    _connection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _connection!.onclose(({Exception? error}) {
      _isConnected = false;
    });

    _connection!.onreconnecting(({Exception? error}) {
      _isConnected = false;
    });

    _connection!.onreconnected(({String? connectionId}) {
      _isConnected = true;
    });

    try {
      await _connection!.start();
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      _isConnected = false;
    }
  }

  void on(String methodName, void Function(List<Object?>? args) handler) {
    _connection?.on(methodName, handler);
  }

  void off(String methodName) {
    _connection?.off(methodName);
  }

  Future<void> invoke(String methodName, [List<Object>? args]) async {
    if (_connection == null || !_isConnected) {
      throw Exception('Not connected to SignalR hub');
    }
    await _connection!.invoke(methodName, args: args);
  }
}
