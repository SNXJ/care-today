import 'package:flutter/services.dart';

class SecureTokenStore {
  const SecureTokenStore();
  static const _channel = MethodChannel('com.caretoday.app/secure_storage');

  Future<String?> read() => _channel.invokeMethod<String>('read');
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', {'value': value});
  Future<void> delete() => _channel.invokeMethod<void>('delete');
}
