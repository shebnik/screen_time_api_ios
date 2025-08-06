import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_time_api_ios/models/family_activity_selection.dart';
import 'package:screen_time_api_ios/models/quota_configuration.dart';
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
  Future<Map<String, dynamic>> configure({
    String? appGroupIdentifier,
    String? logFilePath,
  }) async {
    try {
      final arguments = <String, dynamic>{};

      if (appGroupIdentifier != null) {
        arguments['appGroupIdentifier'] = appGroupIdentifier;
      }

      if (logFilePath != null) {
        arguments['logFilePath'] = logFilePath;
      }

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'configure',
        arguments.isNotEmpty ? arguments : null,
      );

      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      debugPrint('Error in configure: $e');
      return {'error': e.toString()};
    }
  }

  @override
  Future<bool> configureLogging({required String logFilePath}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'configureLogging',
        {'logFilePath': logFilePath},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error in configureLogging: $e');
      return false;
    }
  }

  @override
  Future<String> getLogContent() async {
    try {
      final result = await methodChannel.invokeMethod<String>('getLogContent');
      return result ?? 'No log content available';
    } catch (e) {
      debugPrint('Error in getLogContent: $e');
      return 'Error retrieving log content: $e';
    }
  }

  @override
  Future<bool> clearLogs() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('clearLogs');
      return result ?? false;
    } catch (e) {
      debugPrint('Error in clearLogs: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> requestAuthorization() async {
    try {
      final result = await methodChannel.invokeMethod('requestAuthorization');
      if (result is Map<Object?, Object?>) {
        return _convertToStringDynamicMap(result);
      } else if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'status': 'unknown'};
    } catch (e) {
      debugPrint('Error in requestAuthorization: $e');
      return {'status': 'unknown'};
    }
  }

  @override
  Future<Map<String, dynamic>> getAuthorizationStatus() async {
    try {
      final result = await methodChannel.invokeMethod('getAuthorizationStatus');
      if (result is Map<Object?, Object?>) {
        return _convertToStringDynamicMap(result);
      } else if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'status': 'unknown'};
    } catch (e) {
      debugPrint('Error in getAuthorizationStatus: $e');
      return {'status': 'unknown'};
    }
  }

  @override
  Future<FamilyActivitySelection> showFamilyActivityPicker([
    Map<String, dynamic>? uiConfig,
  ]) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'showFamilyActivityPicker',
        uiConfig,
      );
      if (result != null) {
        final convertedMap = _convertToStringDynamicMap(result);
        return FamilyActivitySelection.fromMap(convertedMap);
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in showFamilyActivityPicker: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<FamilyActivitySelection> getSelectedApps() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getSelectedApps',
      );
      if (result != null) {
        final convertedMap = _convertToStringDynamicMap(result);
        return FamilyActivitySelection.fromMap(convertedMap);
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in getSelectedApps: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<bool> discourageApps(FamilyActivitySelection selection) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'discourageApps',
        selection.toMap(),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error in discourageApps: $e');
      return false;
    }
  }

  @override
  Future<FamilyActivitySelection> getDiscouragedApps() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getDiscouragedApps',
      );
      if (result != null) {
        final convertedMap = _convertToStringDynamicMap(result);
        return FamilyActivitySelection.fromMap(convertedMap);
      }
      return FamilyActivitySelection.empty();
    } catch (e) {
      debugPrint('Error in getDiscouragedApps: $e');
      return FamilyActivitySelection.empty();
    }
  }

  @override
  Future<void> encourageAll() async {
    await methodChannel.invokeMethod('encourageAll');
  }

  @override
  Future<void> setAdultWebsiteBlocking({required bool enabled}) async {
    await methodChannel.invokeMethod('setAdultWebsiteBlocking', {
      'enabled': enabled,
    });
  }

  @override
  Future<bool> getAdultWebsiteBlocking() async {
    final result = await methodChannel.invokeMethod<bool>(
      'getAdultWebsiteBlocking',
    );
    return result ?? false;
  }

  @override
  Future<void> setWebContentBlocking({
    required bool adultContentEnabled,
    List<String> blockedDomains = const [],
  }) async {
    await methodChannel.invokeMethod('setWebContentBlocking', {
      'adultContentEnabled': adultContentEnabled,
      'blockedDomains': blockedDomains,
    });
  }

  @override
  Future<Map<String, dynamic>> getWebContentBlocking() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getWebContentBlocking',
      );
      if (result != null) {
        return _convertToStringDynamicMap(result);
      }
      return {};
    } catch (e) {
      debugPrint('Error in getWebContentBlocking: $e');
      return {};
    }
  }

  @override
  Future<bool> setAppQuotas(QuotaConfiguration quotaConfig) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'setAppQuotas',
        quotaConfig.toMap(),
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error in setAppQuotas: $e');
      return false;
    }
  }

  /// Helper method to safely convert nested Map objects
  Map<String, dynamic> _convertToStringDynamicMap(Map<Object?, Object?> map) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      final stringKey = key.toString();

      if (value is Map<Object?, Object?>) {
        result[stringKey] = _convertToStringDynamicMap(value);
      } else if (value is List) {
        result[stringKey] = value.map((item) {
          if (item is Map<Object?, Object?>) {
            return _convertToStringDynamicMap(item);
          }
          return item;
        }).toList();
      } else {
        result[stringKey] = value;
      }
    });

    return result;
  }

  @override
  Future<QuotaConfiguration> getAppQuotas() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getAppQuotas',
      );
      if (result != null) {
        final convertedMap = _convertToStringDynamicMap(result);
        return QuotaConfiguration.fromMap(convertedMap);
      }
      return QuotaConfiguration.empty();
    } catch (e) {
      debugPrint('Error in getAppQuotas: $e');
      return QuotaConfiguration.empty();
    }
  }
}
