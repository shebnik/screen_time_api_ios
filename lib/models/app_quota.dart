import 'package:flutter/foundation.dart';

/// Represents a quota configuration for a specific app
@immutable
class AppQuota {
  const AppQuota({
    required this.encodedToken,
    required this.tokenType,
    required this.allowedOpensPerDay,
  });

  /// Create an AppQuota from a map
  factory AppQuota.fromMap(Map<String, dynamic> map) {
    return AppQuota(
      encodedToken: map['encodedToken'] as String,
      tokenType: map['tokenType'] as String,
      allowedOpensPerDay: map['allowedOpensPerDay'] as int,
    );
  }

  /// The encoded token representing the app, category, or web domain
  final String encodedToken;

  /// The type of token (application, category, webDomain)
  final String tokenType;

  /// Number of times the app can be opened per day (0 = completely blocked)
  final int allowedOpensPerDay;

  /// Convert the quota to a map
  Map<String, dynamic> toMap() {
    return {
      'encodedToken': encodedToken,
      'tokenType': tokenType,
      'allowedOpensPerDay': allowedOpensPerDay,
    };
  }

  /// Create a copy of this quota with updated values
  AppQuota copyWith({
    String? encodedToken,
    String? tokenType,
    int? allowedOpensPerDay,
  }) {
    return AppQuota(
      encodedToken: encodedToken ?? this.encodedToken,
      tokenType: tokenType ?? this.tokenType,
      allowedOpensPerDay: allowedOpensPerDay ?? this.allowedOpensPerDay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppQuota &&
        other.encodedToken == encodedToken &&
        other.tokenType == tokenType &&
        other.allowedOpensPerDay == allowedOpensPerDay;
  }

  @override
  int get hashCode {
    return Object.hash(encodedToken, tokenType, allowedOpensPerDay);
  }

  @override
  String toString() {
    return 'AppQuota(token: $encodedToken, type: $tokenType, '
        'quota: $allowedOpensPerDay)';
  }
}
