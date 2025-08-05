import 'package:flutter/foundation.dart';
import 'package:screen_time_api_ios/models/token_type.dart';

/// Represents a daily quota configuration for an app or category
@immutable
class AppQuota {
  const AppQuota({
    required this.index,
    required this.dailyLimit,
    this.usedToday = 0,
    this.tokenType = TokenType.application,
  });

  /// Create an AppQuota from a map
  factory AppQuota.fromMap(Map<String, dynamic> map) {
    return AppQuota(
      index: map['index'] as int,
      dailyLimit: map['dailyLimit'] as int,
      usedToday: map['usedToday'] as int? ?? 0,
      tokenType: TokenType.fromString(
        map['tokenType'] as String? ?? 'application',
      ),
    );
  }

  /// The index in the selection array
  final int index;

  /// Token type: application, category, or webDomain
  final TokenType tokenType;

  /// Daily limit of app opens (0 = blocked completely)
  final int dailyLimit;

  /// Number of times the app has been opened today
  final int usedToday;

  /// Convert the quota to a map
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'tokenType': tokenType.value,
      'dailyLimit': dailyLimit,
      'usedToday': usedToday,
    };
  }

  /// Check if the app has exceeded its daily quota
  bool get isOverQuota => usedToday >= dailyLimit;

  /// Check if the app is allowed to open (under quota)
  bool get canOpen => usedToday < dailyLimit;

  /// Remaining opens for today
  int get remainingOpens => dailyLimit - usedToday;

  /// Create a copy with updated usage
  AppQuota copyWith({
    int? index,
    TokenType? tokenType,
    int? dailyLimit,
    int? usedToday,
  }) {
    return AppQuota(
      index: index ?? this.index,
      tokenType: tokenType ?? this.tokenType,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usedToday: usedToday ?? this.usedToday,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppQuota &&
        other.index == index &&
        other.tokenType == tokenType &&
        other.dailyLimit == dailyLimit &&
        other.usedToday == usedToday;
  }

  @override
  int get hashCode => Object.hash(index, tokenType, dailyLimit, usedToday);

  @override
  String toString() {
    return 'AppQuota(index: $index, type: ${tokenType.value}, limit: $dailyLimit, used: $usedToday)';
  }
}

/// Represents a collection of app quotas
@immutable
class AppQuotaCollection {
  const AppQuotaCollection({
    required this.quotas,
  });

  /// Create an empty collection
  factory AppQuotaCollection.empty() {
    return const AppQuotaCollection(quotas: []);
  }

  /// Create an AppQuotaCollection from a map
  factory AppQuotaCollection.fromMap(Map<String, dynamic> map) {
    final quotasList = (map['quotas'] as List<dynamic>?) ?? [];
    return AppQuotaCollection(
      quotas: quotasList
          .map(
            (quota) =>
                AppQuota.fromMap(Map<String, dynamic>.from(quota as Map)),
          )
          .toList(),
    );
  }

  /// List of individual app quotas
  final List<AppQuota> quotas;

  /// Convert the collection to a map
  Map<String, dynamic> toMap() {
    return {
      'quotas': quotas.map((quota) => quota.toMap()).toList(),
    };
  }

  /// Check if the collection is empty
  bool get isEmpty => quotas.isEmpty;

  /// Check if the collection is not empty
  bool get isNotEmpty => quotas.isNotEmpty;

  /// Get quota for a specific index
  AppQuota? getQuotaForIndex(int index) {
    try {
      return quotas.firstWhere((quota) => quota.index == index);
    } catch (e) {
      return null;
    }
  }

  /// Get all indices that are over quota
  List<int> get overQuotaIndices {
    return quotas
        .where((quota) => quota.isOverQuota)
        .map((quota) => quota.index)
        .toList();
  }

  /// Add or update a quota for an app/category
  AppQuotaCollection updateQuota(AppQuota newQuota) {
    final updatedQuotas =
        quotas.where((q) => q.index != newQuota.index).toList()..add(newQuota);
    return AppQuotaCollection(quotas: updatedQuotas);
  }

  /// Remove quota for an app/category
  AppQuotaCollection removeQuota(int index) {
    final updatedQuotas = quotas.where((q) => q.index != index).toList();
    return AppQuotaCollection(quotas: updatedQuotas);
  }

  /// Reset daily usage for all apps (call this daily)
  AppQuotaCollection resetDailyUsage() {
    final resetQuotas = quotas
        .map((quota) => quota.copyWith(usedToday: 0))
        .toList();
    return AppQuotaCollection(quotas: resetQuotas);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppQuotaCollection && listEquals(other.quotas, quotas);
  }

  @override
  int get hashCode => Object.hashAll(quotas);

  @override
  String toString() {
    return 'AppQuotaCollection(quotas: ${quotas.length})';
  }
}
