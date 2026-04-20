import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'user_pin';
  static const _pinEnabledKey = 'pin_enabled';

  static Future<bool> isPinEnabled() async {
    final enabled = await _storage.read(key: _pinEnabledKey);
    return enabled == 'true';
  }

  static Future<void> setPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hashedPin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  static Future<void> disablePin() async {
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _storage.delete(key: _pinKey);
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
