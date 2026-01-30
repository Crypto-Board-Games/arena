import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../models/google_user.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _deviceIdKey = 'device_id';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<({String token, UserModel user})?> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return null;
      }

      final deviceId = await _getOrCreateDeviceId();

      final googleUser = GoogleUser(
        id: googleAccount.id,
        email: googleAccount.email,
        verifiedEmail: true,
        name: googleAccount.displayName,
        picture: googleAccount.photoUrl,
        deviceId: deviceId,
      );

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authGoogle}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(googleUser.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Authentication failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);

      await _saveAuthData(token, user);

      return (token: token, user: user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _clearAuthData();
  }

  Future<({String token, UserModel user})?> getStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token == null || userJson == null) {
      return null;
    }

    try {
      final user = UserModel.fromJson(jsonDecode(userJson));
      return (token: token, user: user);
    } catch (_) {
      await _clearAuthData();
      return null;
    }
  }

  Future<UserModel?> refreshUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMe}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final user = UserModel.fromJson(jsonDecode(response.body));
      await _saveUser(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs();
    final platform = Platform.operatingSystem;
    return '${platform}_${timestamp}_$random';
  }

  Future<void> _saveAuthData(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
