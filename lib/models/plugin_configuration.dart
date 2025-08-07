import 'package:flutter/foundation.dart';

/// Configuration model for plugin setup and initialization
@immutable
class PluginConfiguration {
  /// Creates a plugin configuration
  const PluginConfiguration({
    this.appGroupIdentifier,
    this.logFilePath,
    this.isConfigured = false,
    this.error,
  });

  /// Create from a map returned by the platform
  factory PluginConfiguration.fromMap(Map<String, dynamic> map) {
    return PluginConfiguration(
      appGroupIdentifier: map['appGroupIdentifier'] as String?,
      logFilePath: map['logFilePath'] as String?,
      isConfigured: (map['isConfigured'] as bool?) ?? false,
      error: map['error'] as String?,
    );
  }

  /// The app group identifier used for shared data between app and extension
  final String? appGroupIdentifier;

  /// Path where log files are written
  final String? logFilePath;

  /// Whether the plugin has been successfully configured
  final bool isConfigured;

  /// Error message if configuration failed
  final String? error;

  /// Whether the configuration was successful
  bool get isSuccess => isConfigured && error == null;

  /// Whether configuration failed
  bool get isFailure => !isSuccess;

  /// Convert to map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'appGroupIdentifier': appGroupIdentifier,
      'logFilePath': logFilePath,
      'isConfigured': isConfigured,
      'error': error,
    };
  }

  /// Create a copy with optional parameter overrides
  PluginConfiguration copyWith({
    String? appGroupIdentifier,
    String? logFilePath,
    bool? isConfigured,
    String? error,
  }) {
    return PluginConfiguration(
      appGroupIdentifier: appGroupIdentifier ?? this.appGroupIdentifier,
      logFilePath: logFilePath ?? this.logFilePath,
      isConfigured: isConfigured ?? this.isConfigured,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PluginConfiguration &&
        other.appGroupIdentifier == appGroupIdentifier &&
        other.logFilePath == logFilePath &&
        other.isConfigured == isConfigured &&
        other.error == error;
  }

  @override
  int get hashCode {
    return appGroupIdentifier.hashCode ^
        logFilePath.hashCode ^
        isConfigured.hashCode ^
        error.hashCode;
  }

  @override
  String toString() {
    return 'PluginConfiguration(appGroupIdentifier: $appGroupIdentifier, logFilePath: $logFilePath, isConfigured: $isConfigured, error: $error)';
  }
}
