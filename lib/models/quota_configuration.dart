import 'package:flutter/foundation.dart';
import 'package:screen_time_api_ios/models/app_quota.dart';

/// Represents a collection of app quotas for different applications
@immutable
class QuotaConfiguration {
  const QuotaConfiguration({
    required this.appQuotas,
    this.dailyCounters = const {},
  });

  /// Create a QuotaConfiguration from a map
  factory QuotaConfiguration.fromMap(Map<String, dynamic> map) {
    final quotaList =
        (map['appQuotas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        [];
    final appQuotas = quotaList.map(AppQuota.fromMap).toList();

    // Handle daily counters from the native side
    final countersData = map['dailyCounters'];
    final dailyCounters = <String, int>{};
    if (countersData is Map) {
      countersData.forEach((key, value) {
        if (key is String && value is num) {
          dailyCounters[key] = value.toInt();
        }
      });
    }

    return QuotaConfiguration(
      appQuotas: appQuotas,
      dailyCounters: dailyCounters,
    );
  }

  /// Create an empty quota configuration
  factory QuotaConfiguration.empty() {
    return const QuotaConfiguration(
      appQuotas: [],
    );
  }

  /// List of individual app quotas
  final List<AppQuota> appQuotas;

  /// Daily usage counters for each app token
  final Map<String, int> dailyCounters;

  /// Convert the configuration to a map
  Map<String, dynamic> toMap() {
    return {
      'appQuotas': appQuotas.map((quota) => quota.toMap()).toList(),
      'dailyCounters': dailyCounters,
    };
  }

  /// Check if the configuration is empty
  bool get isEmpty => appQuotas.isEmpty;

  /// Check if the configuration has any quotas
  bool get isNotEmpty => !isEmpty;

  /// Get the total number of apps with quotas
  int get totalCount => appQuotas.length;

  /// Get quota for a specific token
  AppQuota? getQuotaForToken(String encodedToken) {
    try {
      return appQuotas.firstWhere(
        (quota) => quota.encodedToken == encodedToken,
      );
    } catch (e) {
      return null;
    }
  }

  /// Add or update a quota for a specific app
  QuotaConfiguration updateQuota(AppQuota newQuota) {
    final updatedQuotas = List<AppQuota>.from(appQuotas);
    final existingIndex = updatedQuotas.indexWhere(
      (quota) => quota.encodedToken == newQuota.encodedToken,
    );

    if (existingIndex != -1) {
      updatedQuotas[existingIndex] = newQuota;
    } else {
      updatedQuotas.add(newQuota);
    }

    return QuotaConfiguration(
      appQuotas: updatedQuotas,
      dailyCounters: dailyCounters,
    );
  }

  /// Remove a quota for a specific token
  QuotaConfiguration removeQuota(String encodedToken) {
    final updatedQuotas = appQuotas
        .where((quota) => quota.encodedToken != encodedToken)
        .toList();

    return QuotaConfiguration(
      appQuotas: updatedQuotas,
      dailyCounters: dailyCounters,
    );
  }

  /// Get quotas grouped by token type
  Map<String, List<AppQuota>> get quotasByType {
    final grouped = <String, List<AppQuota>>{};

    for (final quota in appQuotas) {
      grouped.putIfAbsent(quota.tokenType, () => []).add(quota);
    }

    return grouped;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuotaConfiguration &&
        _listEquals(other.appQuotas, appQuotas) &&
        _mapEquals(other.dailyCounters, dailyCounters);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(appQuotas),
      Object.hashAll(dailyCounters.entries),
    );
  }

  @override
  String toString() {
    return 'QuotaConfiguration(count: ${appQuotas.length})';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper method to compare maps
  bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
