import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_time_api_ios/models/token_type.dart';

class AppLabelView extends StatelessWidget {
  const AppLabelView({
    required this.tokenType,
    required this.encodedToken,
    super.key,
  });

  final TokenType tokenType;
  final String encodedToken;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // Reduced height since we're showing only one label
      child: defaultTargetPlatform == TargetPlatform.iOS
          ? UiKitView(
              viewType: 'app_label_view',
              creationParams: <String, dynamic>{
                'tokenType': tokenType.value,
                'encodedToken': encodedToken,
              },
              creationParamsCodec: const StandardMessageCodec(),
            )
          : Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_getDisplayName()} ${encodedToken.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  Color _getBackgroundColor() {
    switch (tokenType) {
      case TokenType.application:
        return Colors.grey[200]!;
      case TokenType.category:
        return Colors.blue[100]!;
      case TokenType.webDomain:
        return Colors.green[100]!;
    }
  }

  String _getDisplayName() {
    switch (tokenType) {
      case TokenType.application:
        return 'App';
      case TokenType.category:
        return 'Category';
      case TokenType.webDomain:
        return 'Web Domain';
    }
  }
}
