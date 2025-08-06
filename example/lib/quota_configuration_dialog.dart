import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';

class QuotaConfigurationDialog extends StatefulWidget {
  const QuotaConfigurationDialog({
    required this.selectedApps,
    required this.currentQuotas,
    super.key,
  });

  final FamilyActivitySelection selectedApps;
  final QuotaConfiguration currentQuotas;

  @override
  State<QuotaConfigurationDialog> createState() =>
      _QuotaConfigurationDialogState();
}

class _QuotaConfigurationDialogState extends State<QuotaConfigurationDialog> {
  late QuotaConfiguration _workingQuotas;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _workingQuotas = widget.currentQuotas;
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize controllers for all tokens
    final allTokens = [
      ...widget.selectedApps.applicationTokens,
      ...widget.selectedApps.categoryTokens,
      ...widget.selectedApps.webDomainTokens,
    ];

    for (final token in allTokens) {
      final existingQuota = _workingQuotas.getQuotaForToken(token);
      final controller = TextEditingController(
        text: existingQuota?.allowedOpensPerDay.toString() ?? '0',
      );
      _controllers[token] = controller;
    }
  }

  void _saveQuotas() {
    var updatedQuotas = _workingQuotas;

    // Process application tokens
    for (final token in widget.selectedApps.applicationTokens) {
      final controller = _controllers[token];
      if (controller != null) {
        final value = int.tryParse(controller.text) ?? 0;
        final quota = AppQuota(
          encodedToken: token,
          tokenType: 'application',
          allowedOpensPerDay: value,
        );
        updatedQuotas = updatedQuotas.updateQuota(quota);
      }
    }

    // Process category tokens
    for (final token in widget.selectedApps.categoryTokens) {
      final controller = _controllers[token];
      if (controller != null) {
        final value = int.tryParse(controller.text) ?? 0;
        final quota = AppQuota(
          encodedToken: token,
          tokenType: 'category',
          allowedOpensPerDay: value,
        );
        updatedQuotas = updatedQuotas.updateQuota(quota);
      }
    }

    // Process web domain tokens
    for (final token in widget.selectedApps.webDomainTokens) {
      final controller = _controllers[token];
      if (controller != null) {
        final value = int.tryParse(controller.text) ?? 0;
        final quota = AppQuota(
          encodedToken: token,
          tokenType: 'webDomain',
          allowedOpensPerDay: value,
        );
        updatedQuotas = updatedQuotas.updateQuota(quota);
      }
    }

    Navigator.of(context).pop(updatedQuotas);
  }

  Widget _buildAppQuotaItem(String token, String tokenType) {
    final controller = _controllers[token];
    if (controller == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App label view
            SizedBox(
              height: 60,
              child: AppLabelView(
                tokenType: tokenType == 'application'
                    ? TokenType.application
                    : tokenType == 'category'
                    ? TokenType.category
                    : TokenType.webDomain,
                encodedToken: token,
              ),
            ),
            const SizedBox(height: 8),
            // Quota input
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Allowed opens per day:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTokens = [
      ...widget.selectedApps.applicationTokens.map(
        (token) => {'token': token, 'type': 'application'},
      ),
      ...widget.selectedApps.categoryTokens.map(
        (token) => {'token': token, 'type': 'category'},
      ),
      ...widget.selectedApps.webDomainTokens.map(
        (token) => {'token': token, 'type': 'webDomain'},
      ),
    ];

    return AlertDialog(
      title: const Text('Configure App Quotas'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set the maximum number of times each app can be opened per day. '
              'Use 0 to completely block the app.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allTokens.length,
                itemBuilder: (context, index) {
                  final item = allTokens[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildAppQuotaItem(
                      item['token']!,
                      item['type']!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveQuotas,
          child: const Text('Save Quotas'),
        ),
      ],
    );
  }
}
