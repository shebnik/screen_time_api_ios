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
  FamilyActivitySelection _discouragedApps = FamilyActivitySelection.empty();
  String _authorizationStatus = 'unknown';
  bool _isLoading = false;
  bool _adultWebsiteBlocking = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationStatus().then((_) {
      _loadSelectedApps();
      _loadDiscouragedApps();
      _loadAdultWebsiteBlocking();
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

  Future<void> _loadSelectedApps() async {
    try {
      final apps = await _screenTimeApiIosPlugin.getSelectedApps();
      setState(() {
        _selectedApps = apps;
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading selected apps: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _loadDiscouragedApps() async {
    try {
      final apps = await _screenTimeApiIosPlugin.getDiscouragedApps();
      setState(() {
        _discouragedApps = apps;
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading discouraged apps: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _loadAdultWebsiteBlocking() async {
    try {
      final isBlocked = await _screenTimeApiIosPlugin.getAdultWebsiteBlocking();
      setState(() {
        _adultWebsiteBlocking = isBlocked;
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading adult website blocking status: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _toggleAdultWebsiteBlocking(bool enabled) async {
    if (_authorizationStatus != 'authorized') {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _screenTimeApiIosPlugin.setAdultWebsiteBlocking(
        enabled: enabled,
      );
      setState(() {
        _adultWebsiteBlocking = enabled;
      });
      _showSnackBar(
        enabled ? 'Adult websites blocked' : 'Adult websites unblocked',
        Colors.green,
      );
    } catch (e, s) {
      debugPrintStack(
        label: 'Error toggling adult website blocking: $e',
        stackTrace: s,
      );
      _showSnackBar('Failed to update adult website blocking: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showFamilyActivityPicker() async {
    if (_authorizationStatus != 'authorized') {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      _selectedApps = await _screenTimeApiIosPlugin.showFamilyActivityPicker(
        const UICustomization(
          navigationTitle: 'Выбор приложений',
          saveButtonText: 'Сохранить выбор',
          appsCountText: 'Приложения',
          websitesCountText: 'Веб-сайты',
          categoriesCountText: 'Категории',
          saveButtonFontSize: 18,
          countTextFontSize: 16,
          navigationTitleFontSize: 20,
          countTextColor: Colors.white,
          saveButtonColor: Color(0xFFF4FF5F),
          saveButtonTextColor: Colors.black,
          navigationTintColor: Colors.white,
          darkTextColor: Colors.black,
        ),
      );
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

  Future<void> _discourageSelectedApps() async {
    if (_authorizationStatus != 'authorized') {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    if (_selectedApps.totalCount == 0) {
      _showSnackBar('No apps selected to discourage', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _screenTimeApiIosPlugin.discourageApps(
        _selectedApps,
      );
      if (success) {
        await _loadDiscouragedApps(); // Refresh discouraged apps list
        _showSnackBar('Apps discouraged successfully!', Colors.green);
      } else {
        _showSnackBar('Failed to discourage apps', Colors.red);
      }
    } catch (e, s) {
      debugPrintStack(
        label: 'Error discouraging apps: $e',
        stackTrace: s,
      );
      _showSnackBar('Failed to discourage apps: $e', Colors.red);
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
        _discouragedApps = FamilyActivitySelection.empty();
        _adultWebsiteBlocking =
            false; // Adult website blocking is also disabled
      });
      _showSnackBar(
        'All apps encouraged and restrictions removed!',
        Colors.green,
      );
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
    return _discouragedApps.totalCount;
  }

  int _getSelectedTokenCount() {
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
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: _authorizationStatus == 'authorized'
                                    ? _showFamilyActivityPicker
                                    : null,
                                child: const Text('Select Apps'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    _authorizationStatus == 'authorized' &&
                                        _getSelectedTokenCount() > 0
                                    ? _discourageSelectedApps
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Discourage Selected'),
                              ),
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
                          Row(
                            children: [
                              TextButton(
                                onPressed: _loadSelectedApps,
                                child: const Text('Refresh Selected'),
                              ),
                              TextButton(
                                onPressed: _loadDiscouragedApps,
                                child: const Text('Refresh Discouraged'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Block Adult Websites',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _adultWebsiteBlocking,
                                onChanged: _authorizationStatus == 'authorized'
                                    ? _toggleAdultWebsiteBlocking
                                    : null,
                              ),
                            ],
                          ),
                          if (_authorizationStatus != 'authorized')
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Authorization required to change this setting',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
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
                            'Selected Apps (${_getSelectedTokenCount()})',
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
                                        tokenType: TokenType.application,
                                        encodedToken: entry.value,
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
                                        tokenType: TokenType.category,
                                        encodedToken: entry.value,
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
                                        tokenType: TokenType.webDomain,
                                        encodedToken: entry.value,
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
                              'selected yet. Tap "Select Apps" to choose.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discouraged Apps Display
                  // Discouraged Apps Display
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
                          if (_discouragedApps
                              .applicationTokens
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ExpansionTile(
                              title: const Text('Discouraged Applications'),
                              children: _discouragedApps.applicationTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenType: TokenType.application,
                                        encodedToken: entry.value,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_discouragedApps.categoryTokens.isNotEmpty) ...[
                            ExpansionTile(
                              title: const Text('Discouraged Categories'),
                              children: _discouragedApps.categoryTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenType: TokenType.category,
                                        encodedToken: entry.value,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_discouragedApps.webDomainTokens.isNotEmpty) ...[
                            ExpansionTile(
                              title: const Text('Discouraged Web Domains'),
                              children: _discouragedApps.webDomainTokens
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: AppLabelView(
                                        tokenType: TokenType.webDomain,
                                        encodedToken: entry.value,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_discouragedApps.applicationTokens.isEmpty &&
                              _discouragedApps.categoryTokens.isEmpty &&
                              _discouragedApps.webDomainTokens.isEmpty)
                            const Text(
                              'No apps, categories, or web domains '
                              'are currently discouraged.',
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
                                if (_discouragedApps
                                    .applicationTokens
                                    .isNotEmpty)
                                  _buildTokenSection(
                                    'Application Tokens',
                                    _discouragedApps.applicationTokens,
                                  ),
                                if (_discouragedApps.categoryTokens.isNotEmpty)
                                  _buildTokenSection(
                                    'Category Tokens',
                                    _discouragedApps.categoryTokens,
                                  ),
                                if (_discouragedApps.webDomainTokens.isNotEmpty)
                                  _buildTokenSection(
                                    'Web Domain Tokens',
                                    _discouragedApps.webDomainTokens,
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
