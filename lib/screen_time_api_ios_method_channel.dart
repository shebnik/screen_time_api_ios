import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_time_api_ios/screen_time_api_ios_platform_interface.dart';

/// An implementation of [ScreenTimeApiIosPlatform] that uses method channels.
class MethodChannelScreenTimeApiIos extends ScreenTimeApiIosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_time_api_ios');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<String, dynamic>> requestAuthorization() async {
    final result = await methodChannel.invokeMethod('requestAuthorization');
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {'status': 'unknown'};
  }

  @override
  Future<Map<String, dynamic>> getAuthorizationStatus() async {
    final result = await methodChannel.invokeMethod('getAuthorizationStatus');
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return {'status': 'unknown'};
  }

  @override
  Future<List<String>> selectAppsToDiscourage() async {
    final result = await methodChannel.invokeMethod('selectAppsToDiscourage');
    if (result is List) {
      return result.cast<String>();
    }
    return [];
  }

  @override
  Future<List<String>> getDiscouragedApps() async {
    final result = await methodChannel.invokeMethod('getDiscouragedApps');
    if (result is List) {
      return result.cast<String>();
    }
    return [];
  }

  @override
  Future<void> encourageAll() async {
    await methodChannel.invokeMethod('encourageAll');
  }
}
