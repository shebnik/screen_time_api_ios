import 'package:flutter/material.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';

/// Example widget demonstrating quota management functionality
class QuotaManagementExample extends StatefulWidget {
  const QuotaManagementExample({super.key});

  @override
  State<QuotaManagementExample> createState() => _QuotaManagementExampleState();
}

class _QuotaManagementExampleState extends State<QuotaManagementExample> {
  final _plugin = ScreenTimeApiIos();

  FamilyActivitySelection _selectedApps = FamilyActivitySelection.empty();
  QuotaConfiguration _currentQuotas = QuotaConfiguration.empty();
  Map<String, int> _dailyCounters = {};
  bool _isAuthorized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    try {
      final response = await _plugin.getAuthorizationStatus();
      setState(() {
        _isAuthorized = response.status.isAuthorized;
      });

      if (_isAuthorized) {
        await _loadQuotas();
      }
    } catch (e) {
      debugPrint('Error checking authorization: $e');
    }
  }

  Future<void> _requestAuthorization() async {
    setState(() => _isLoading = true);

    try {
      final response = await _plugin.requestAuthorization();
      setState(() {
        _isAuthorized = response.status.isAuthorized;
      });

      if (_isAuthorized) {
        await _loadQuotas();
        _showSnackBar('Screen Time access granted!', Colors.green);
      } else {
        _showSnackBar('Screen Time access denied', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Authorization failed: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectApps() async {
    if (!_isAuthorized) {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selection = await _plugin.showFamilyActivityPicker();
      if (selection != null) {
        setState(() {
          _selectedApps = selection;
        });
        _showSnackBar('Apps selected successfully!', Colors.green);
      } else {
        _showSnackBar('App selection was cancelled', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Failed to select apps: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _configureQuotas() async {
    if (_selectedApps.isEmpty) {
      _showSnackBar('Please select apps first', Colors.orange);
      return;
    }

    final result = await showDialog<List<AppQuota>>(
      context: context,
      builder: (context) => _QuotaConfigDialog(
        selectedApps: _selectedApps,
        currentQuotas: _currentQuotas.appQuotas,
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);

      try {
        final quotaConfig = QuotaConfiguration(appQuotas: result);
        final success = await _plugin.setAppQuotas(quotaConfig);

        if (success) {
          setState(() {
            _currentQuotas = quotaConfig;
          });
          await _loadQuotas(); // Refresh counters
          _showSnackBar('Quotas configured successfully!', Colors.green);
        } else {
          _showSnackBar('Failed to configure quotas', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error configuring quotas: $e', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadQuotas() async {
    try {
      final result = await _plugin.getAppQuotas();
      setState(() {
        _currentQuotas = result;
        final quotaData = result.toMap();
        final countersData = quotaData['dailyCounters'];
        if (countersData is Map) {
          _dailyCounters = Map<String, int>.from(countersData);
        } else {
          _dailyCounters = {};
        }
      });
    } catch (e) {
      debugPrint('Error loading quotas: $e');
    }
  }

  Future<void> _clearAllRestrictions() async {
    setState(() => _isLoading = true);

    try {
      await _plugin.encourageAll();
      setState(() {
        _currentQuotas = QuotaConfiguration.empty();
        _dailyCounters.clear();
        _selectedApps = FamilyActivitySelection.empty();
      });
      _showSnackBar('All restrictions cleared!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to clear restrictions: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quota Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authorization Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isAuthorized ? Icons.check_circle : Icons.error,
                      color: _isAuthorized ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAuthorized ? 'Authorized' : 'Not Authorized',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (!_isAuthorized) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _requestAuthorization,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Request Authorization'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            if (_isAuthorized) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _selectApps,
                icon: const Icon(Icons.apps),
                label: const Text('Select Apps'),
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _configureQuotas,
                icon: const Icon(Icons.settings),
                label: const Text('Configure Quotas'),
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadQuotas,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Usage'),
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearAllRestrictions,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],

            const SizedBox(height: 16),

            // Current Status
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Selected Apps: ${_selectedApps.totalCount}'),
                      Text(
                        'Configured Quotas: ${_currentQuotas.appQuotas.length}',
                      ),
                      const SizedBox(height: 16),

                      if (_dailyCounters.isNotEmpty) ...[
                        Text(
                          'Daily Usage:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _dailyCounters.length,
                            itemBuilder: (context, index) {
                              final entry = _dailyCounters.entries.elementAt(
                                index,
                              );
                              final quota = _currentQuotas.getQuotaForToken(
                                entry.key,
                              );
                              final allowed = quota?.allowedOpensPerDay ?? 0;

                              return ListTile(
                                title: Text('App ${index + 1}'),
                                subtitle: Text(
                                  'Token: ${entry.key.substring(0, 8)}...',
                                ),
                                trailing: Text(
                                  '${entry.value}/$allowed opens',
                                  style: TextStyle(
                                    color: entry.value >= allowed
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        const Text('No usage data available'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaConfigDialog extends StatefulWidget {
  const _QuotaConfigDialog({
    required this.selectedApps,
    required this.currentQuotas,
  });

  final FamilyActivitySelection selectedApps;
  final List<AppQuota> currentQuotas;

  @override
  State<_QuotaConfigDialog> createState() => __QuotaConfigDialogState();
}

class __QuotaConfigDialogState extends State<_QuotaConfigDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final List<AppQuota> _quotas = [];

  @override
  void initState() {
    super.initState();
    _initializeQuotas();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeQuotas() {
    // Initialize for application tokens
    for (final token in widget.selectedApps.applicationTokens) {
      final existing = widget.currentQuotas
          .where((q) => q.encodedToken == token)
          .firstOrNull;

      final controller = TextEditingController(
        text: (existing?.allowedOpensPerDay ?? 3).toString(),
      );
      _controllers[token] = controller;

      _quotas.add(
        AppQuota(
          encodedToken: token,
          tokenType: 'application',
          allowedOpensPerDay: existing?.allowedOpensPerDay ?? 3,
        ),
      );
    }

    // Initialize for category tokens
    for (final token in widget.selectedApps.categoryTokens) {
      final existing = widget.currentQuotas
          .where((q) => q.encodedToken == token)
          .firstOrNull;

      final controller = TextEditingController(
        text: (existing?.allowedOpensPerDay ?? 3).toString(),
      );
      _controllers[token] = controller;

      _quotas.add(
        AppQuota(
          encodedToken: token,
          tokenType: 'category',
          allowedOpensPerDay: existing?.allowedOpensPerDay ?? 3,
        ),
      );
    }
  }

  void _updateQuota(String token, int value) {
    final index = _quotas.indexWhere((q) => q.encodedToken == token);
    if (index != -1) {
      _quotas[index] = _quotas[index].copyWith(allowedOpensPerDay: value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure App Quotas'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: _quotas.length,
          itemBuilder: (context, index) {
            final quota = _quotas[index];
            final controller = _controllers[quota.encodedToken]!;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${quota.tokenType.toUpperCase()} ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Token: ${quota.encodedToken.substring(0, 12)}...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Opens per day: '),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0 = blocked',
                              isDense: true,
                            ),
                            onChanged: (value) {
                              final intValue = int.tryParse(value) ?? 0;
                              _updateQuota(quota.encodedToken, intValue);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_quotas),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
