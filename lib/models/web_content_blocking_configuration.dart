import 'package:flutter/foundation.dart';

/// Configuration model for web content blocking settings
@immutable
class WebContentBlockingConfiguration {
  /// Creates a web content blocking configuration
  const WebContentBlockingConfiguration({
    required this.adultContentBlocked,
    this.blockedDomains = const [],
  });

  /// Create from a map returned by the platform
  factory WebContentBlockingConfiguration.fromMap(Map<String, dynamic> map) {
    return WebContentBlockingConfiguration(
      adultContentBlocked: (map['adultContentBlocked'] as bool?) ?? false,
      blockedDomains:
          (map['blockedDomains'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Whether adult content filtering is blocked
  final bool adultContentBlocked;

  /// List of specifically blocked domains
  final List<String> blockedDomains;

  /// Convert to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'adultContentBlocked': adultContentBlocked,
      'blockedDomains': blockedDomains,
    };
  }

  /// Create a copy with optional parameter overrides
  WebContentBlockingConfiguration copyWith({
    bool? adultContentBlocked,
    List<String>? blockedDomains,
  }) {
    return WebContentBlockingConfiguration(
      adultContentBlocked: adultContentBlocked ?? this.adultContentBlocked,
      blockedDomains: blockedDomains ?? this.blockedDomains,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebContentBlockingConfiguration &&
        other.adultContentBlocked == adultContentBlocked &&
        listEquals(other.blockedDomains, blockedDomains);
  }

  @override
  int get hashCode {
    return adultContentBlocked.hashCode ^ blockedDomains.hashCode;
  }

  @override
  String toString() {
    return 'WebContentBlockingConfiguration(adultContentBlocked: $adultContentBlocked, blockedDomains: $blockedDomains)';
  }
}
