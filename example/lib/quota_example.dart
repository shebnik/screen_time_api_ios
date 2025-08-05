import 'package:flutter/material.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';

/// Example implementation of the daily quota system
class QuotaExample extends StatefulWidget {
  const QuotaExample({super.key});

  @override
  State<QuotaExample> createState() => _QuotaExampleState();
}

class _QuotaExampleState extends State<QuotaExample> {
  final _screenTime = ScreenTimeApiIos();
  FamilyActivitySelection _selectedApps = FamilyActivitySelection.empty();
  AppQuotaCollection _quotas = AppQuotaCollection.empty();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentQuotas();
  }

  Future<void> _loadCurrentQuotas() async {
    setState(() => _isLoading = true);
    try {
      final quotas = await _screenTime.getAppQuotas();
      setState(() {
        _quotas = quotas;
      });
    } catch (e) {
      _showSnackBar('Error loading quotas: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAppsForQuotaConfiguration() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Select apps (does not immediately block them)
      final selectedApps = await _screenTime.selectAppsForQuotaConfiguration();

      setState(() {
        _selectedApps = selectedApps;
      });

      _showSnackBar('Apps selected! Now configure quotas below.', Colors.green);
    } catch (e) {
      _showSnackBar('Error selecting apps: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndApplyQuotas() async {
    if (_selectedApps.isEmpty) {
      _showSnackBar('Please select apps first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Step 2: Create quotas with default limits using indices
      List<AppQuota> quotaList = [];

      // Create quota for each selected app with 0 daily opens by default
      for (int i = 0; i < _selectedApps.applicationTokens.length; i++) {
        quotaList.add(
          AppQuota(
            index: i,
            tokenType: TokenType.application,
            dailyLimit: 0, // Start with 0 - user will configure
            usedToday: 0,
          ),
        );
      }

      // Create quota for each selected category with 0 daily opens by default
      // Continue indexing from where apps left off
      for (int i = 0; i < _selectedApps.categoryTokens.length; i++) {
        quotaList.add(
          AppQuota(
            index: i,
            tokenType: TokenType.category,
            dailyLimit: 0, // Start with 0 - user will configure
            usedToday: 0,
          ),
        );
      }

      final quotaCollection = AppQuotaCollection(quotas: quotaList);

      // Step 3: Save the quotas
      await _screenTime.setAppQuotas(quotaCollection);

      // Step 4: Apply the quota-based blocking
      await _screenTime.applyQuotaSettings();

      setState(() {
        _quotas = quotaCollection;
      });

      _showSnackBar(
        'Quotas applied! Apps and categories are now managed by quota system.',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('Error applying quotas: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAppQuota(int index, int newLimit) async {
    setState(() => _isLoading = true);
    try {
      // Find the existing quota and update it
      final existingQuota = _quotas.getQuotaForIndex(index);
      if (existingQuota != null) {
        final updatedQuota = existingQuota.copyWith(dailyLimit: newLimit);
        final updatedCollection = _quotas.updateQuota(updatedQuota);

        // Save the updated quotas
        await _screenTime.setAppQuotas(updatedCollection);

        // Reapply settings to reflect the changes
        await _screenTime.applyQuotaSettings();

        setState(() {
          _quotas = updatedCollection;
        });

        _showSnackBar('Quota updated and applied!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error updating quota: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAllQuotas() async {
    setState(() => _isLoading = true);
    try {
      await _screenTime.encourageAll();
      setState(() {
        _selectedApps = FamilyActivitySelection.empty();
        _quotas = AppQuotaCollection.empty();
      });
      _showSnackBar('All quotas removed!', Colors.green);
    } catch (e) {
      _showSnackBar('Error removing quotas: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateUsage(int index) async {
    try {
      await _screenTime.simulateAppUsage(index);
      // Reload quotas to see updated usage
      _loadCurrentQuotas();
      _showSnackBar('Usage simulated! Check if blocking applies.', Colors.blue);
    } catch (e) {
      _showSnackBar('Error simulating usage: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quota System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How to use the Daily Quota System:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Select apps/categories you want to manage',
                          ),
                          const Text('2. Configure daily quotas (0 = blocked)'),
                          const Text(
                            '3. Press "Save & Apply" to enforce quotas',
                          ),
                          const Text(
                            '4. Apps/categories exceeding quotas will be blocked',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _selectAppsForQuotaConfiguration,
                                child: const Text('1. Select Apps'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _selectedApps.isNotEmpty
                                    ? _saveAndApplyQuotas
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('3. Save & Apply'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Apps and Categories
                  if (_selectedApps.isNotEmpty) ...[
                    Text(
                      'Selected Items '
                      '(${_selectedApps.totalTokenCount}):',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedApps.applicationTokens.isNotEmpty)
                              Text(
                                '${_selectedApps.applicationTokens.length} apps selected',
                              ),
                            if (_selectedApps.categoryTokens.isNotEmpty)
                              Text(
                                '${_selectedApps.categoryTokens.length} categories selected',
                              ),
                            if (_selectedApps.webDomainTokens.isNotEmpty)
                              Text(
                                '${_selectedApps.webDomainTokens.length} web domains selected',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Current Quotas
                  const Text(
                    '2. Configure Daily Quotas:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_quotas.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No quotas configured yet. Select apps first.',
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _quotas.quotas.length,
                        itemBuilder: (context, index) {
                          final quota = _quotas.quotas[index];
                          return Card(
                            child: ListTile(
                              title: AppLabelView(
                                tokenType: quota.tokenType,
                                tokenIndex: quota.index,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: ${quota.tokenType.value.toUpperCase()}',
                                  ),
                                  Text(
                                    'Daily Limit: ${quota.dailyLimit} opens',
                                  ),
                                  Text('Used Today: ${quota.usedToday}'),
                                  if (quota.isOverQuota)
                                    const Text(
                                      'BLOCKED (Over quota)',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: quota.dailyLimit > 0
                                        ? () => _updateAppQuota(
                                            quota.index,
                                            quota.dailyLimit - 1,
                                          )
                                        : null,
                                  ),
                                  Text('${quota.dailyLimit}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateAppQuota(
                                      quota.index,
                                      quota.dailyLimit + 1,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    tooltip: 'Test Usage',
                                    onPressed: () =>
                                        _simulateUsage(quota.index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Remove all button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _removeAllQuotas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Remove All Quotas'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
