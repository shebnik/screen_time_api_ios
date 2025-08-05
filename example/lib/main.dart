import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';

void main() {
  runZonedGuarded(
    () {
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('Flutter Error: ${details.exceptionAsString()}');
      };
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrintStack(
          label: 'Platform Error',
          stackTrace: stack,
        );
        return true;
      };
      runApp(const MaterialApp(home: HomePage()));
    },
    (error, stackTrace) {
      debugPrintStack(label: error.toString(), stackTrace: stackTrace);
    },
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _screenTimeApiIosPlugin = ScreenTimeApiIos();

  FamilyActivitySelection _selectedApps = FamilyActivitySelection.empty();
  String _authorizationStatus = 'unknown';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationStatus().then((_) {
      _loadDiscouragedApps();
    });
  }

  Future<void> _checkAuthorizationStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await _screenTimeApiIosPlugin.getAuthorizationStatus();
      setState(() {
        _authorizationStatus = response.status.value;
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error checking authorization status: $e',
        stackTrace: s,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAuthorization() async {
    setState(() => _isLoading = true);
    try {
      final response = await _screenTimeApiIosPlugin.requestAuthorization();
      setState(() {
        _authorizationStatus = response.status.value;
      });

      if (response.isSuccess) {
        _showSnackBar('Authorization granted!', Colors.green);
      } else {
        _showSnackBar('Authorization denied or failed', Colors.red);
      }
    } catch (e, s) {
      debugPrintStack(
        label: 'Error requesting authorization: $e',
        stackTrace: s,
      );
      _showSnackBar('Authorization failed: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDiscouragedApps() async {
    try {
      final apps = await _screenTimeApiIosPlugin.getDiscouragedApps();
      _selectedApps = apps;
      setState(() {});
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading discouraged apps: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _selectAppsToDiscourage() async {
    if (_authorizationStatus != 'authorized') {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      _selectedApps = await _screenTimeApiIosPlugin.selectAppsToDiscourage();
      setState(() {});
      _showSnackBar('Apps selected successfully!', Colors.green);
    } catch (e, s) {
      debugPrintStack(
        label: 'Error selecting apps: $e',
        stackTrace: s,
      );
      _showSnackBar('Failed to select apps: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _encourageAll() async {
    setState(() => _isLoading = true);
    try {
      await _screenTimeApiIosPlugin.encourageAll();
      setState(() {
        _selectedApps = FamilyActivitySelection.empty();
      });
      _showSnackBar('All apps encouraged!', Colors.green);
    } catch (e, s) {
      debugPrintStack(
        label: 'Error encouraging all apps: $e',
        stackTrace: s,
      );
      _showSnackBar('Failed to encourage all apps: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
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

  Color _getStatusColor() {
    switch (_authorizationStatus) {
      case 'authorized':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'notDetermined':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  int _getTotalTokenCount() {
    return _selectedApps.totalCount;
  }

  Widget _buildTokenSection(String title, List<dynamic> tokens) {
    if (tokens.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text('$title (${tokens.length})'),
      children: tokens
          .map(
            (token) => ListTile(
              dense: true,
              title: Text(
                token.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time API Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Authorization Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Authorization Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _authorizationStatus.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            children: [
                              ElevatedButton(
                                onPressed: _requestAuthorization,
                                child: const Text('Request Authorization'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _checkAuthorizationStatus,
                                child: const Text('Refresh Status'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Selection Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'App Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            children: [
                              ElevatedButton(
                                onPressed: _authorizationStatus == 'authorized'
                                    ? _selectAppsToDiscourage
                                    : null,
                                child: const Text('Select Apps to Discourage'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _encourageAll,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Encourage All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadDiscouragedApps,
                            child: const Text('Refresh Discouraged Apps'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Apps Display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discouraged Apps (${_getTotalTokenCount()})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedApps.applicationTokens.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ExpansionTile(
                              title: const Text('Selected Applications'),
                              children: _selectedApps.applicationTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenIndex: entry.key,
                                        tokenType: TokenType.application,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedApps.categoryTokens.isNotEmpty) ...[
                            ExpansionTile(
                              title: const Text('Selected Categories'),
                              children: _selectedApps.categoryTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenIndex: entry.key,
                                        tokenType: TokenType.category,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedApps.webDomainTokens.isNotEmpty) ...[
                            ExpansionTile(
                              title: const Text('Selected Web Domains'),
                              children: _selectedApps.webDomainTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenIndex: entry.key,
                                        tokenType: TokenType.webDomain,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedApps.applicationTokens.isEmpty &&
                              _selectedApps.categoryTokens.isEmpty &&
                              _selectedApps.webDomainTokens.isEmpty)
                            const Text(
                              'No apps, categories, or web domains '
                              'selected yet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (_getTotalTokenCount() > 0)
                            ExpansionTile(
                              title: const Text('Raw Tokens (Debug)'),
                              children: [
                                if (_selectedApps.applicationTokens.isNotEmpty)
                                  _buildTokenSection(
                                    'Application Tokens',
                                    _selectedApps.applicationTokens,
                                  ),
                                if (_selectedApps.categoryTokens.isNotEmpty)
                                  _buildTokenSection(
                                    'Category Tokens',
                                    _selectedApps.categoryTokens,
                                  ),
                                if (_selectedApps.webDomainTokens.isNotEmpty)
                                  _buildTokenSection(
                                    'Web Domain Tokens',
                                    _selectedApps.webDomainTokens,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
