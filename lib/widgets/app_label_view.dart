import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLabelView extends StatelessWidget {
  const AppLabelView({
    required this.tokenIndex,
    required this.tokenType,
    super.key,
  });

  final int tokenIndex;
  final String tokenType; // 'application', 'category', or 'webDomain'

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60, // Reduced height since we're showing only one label
      child: defaultTargetPlatform == TargetPlatform.iOS
          ? UiKitView(
              viewType: 'app_label_view',
              creationParams: <String, dynamic>{
                'tokenIndex': tokenIndex,
                'tokenType': tokenType,
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
                  '${_getDisplayName()} #$tokenIndex',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }

  Color _getBackgroundColor() {
    switch (tokenType) {
      case 'application':
        return Colors.grey[200]!;
      case 'category':
        return Colors.blue[100]!;
      case 'webDomain':
        return Colors.green[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _getDisplayName() {
    switch (tokenType) {
      case 'application':
        return 'App';
      case 'category':
        return 'Category';
      case 'webDomain':
        return 'Web Domain';
      default:
        return 'Token';
    }
  }
}
