import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_time_api_ios/screen_time_api_ios.dart';
import 'package:screen_time_api_ios_example/quota_configuration_dialog.dart';

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
  QuotaConfiguration _appQuotas = QuotaConfiguration.empty();
  Map<String, int> _dailyCounters = {}; // Track daily app usage
  AuthorizationStatus _authorizationStatus = AuthorizationStatus.unknown;
  bool _isLoading = false;
  bool _adultWebsiteBlocking = false;
  Timer? _refreshTimer; // Auto-refresh timer

  // Web content blocking settings
  List<String> _blockedDomains = [];
  final TextEditingController _blockedDomainController =
      TextEditingController();

  // Configuration settings
  String _appGroupIdentifier = 'group.com.example.screenTimeApiIosExample';
  String? _configurationStatus;

  @override
  void initState() {
    super.initState();
    _configurePlugin().then((_) {
      _checkAuthorizationStatus();
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_authorizationStatus == AuthorizationStatus.authorized &&
            _appQuotas.isNotEmpty) {
          _loadAppQuotas();
        }
      });
    });
  }

  Future<void> _configurePlugin() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final logFilePath = '${documentsDir.path}/screen_time_plugin.log';

      // Configure both app group identifier and logging
      final result = await _screenTimeApiIosPlugin.configure(
        appGroupIdentifier: _appGroupIdentifier,
        logFilePath: logFilePath,
      );

      setState(() {
        final configuredList = result['configured'] as List<dynamic>?;
        _configurationStatus =
            'Plugin configured successfully. '
            'Configured: ${configuredList?.join(', ') ?? 'none'}. '
            'App Group: ${result['appGroupIdentifier'] ?? 'unknown'}';
      });

      debugPrint('Plugin configured: $result');
      debugPrint('Log file path: $logFilePath');
    } catch (e) {
      setState(() {
        _configurationStatus = 'Configuration failed: $e';
      });
      debugPrint('Failed to configure plugin: $e');
      // Fallback to just configuring logging
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final logFilePath = '${documentsDir.path}/screen_time_plugin.log';

        final success = await _screenTimeApiIosPlugin.configureLogging(
          logFilePath: logFilePath,
        );
        setState(() {
          _configurationStatus = 'Fallback logging configured: $success';
        });
        debugPrint('Fallback logging configured: $success');
      } catch (e2) {
        setState(() {
          _configurationStatus = 'All configuration failed: $e2';
        });
        debugPrint('Failed to configure logging fallback: $e2');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blockedDomainController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorizationStatus() async {
    setState(() => _isLoading = true);
    try {
      final response = await _screenTimeApiIosPlugin.getAuthorizationStatus();
      setState(() {
        _authorizationStatus = response.status;
      });
      if (_authorizationStatus == AuthorizationStatus.authorized) {
        await _loadSelectedApps();
        await _loadDiscouragedApps();
        await _loadAdultWebsiteBlocking();
        await _loadAppQuotas();
      }
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
        _authorizationStatus = response.status;
      });

      if (response.isSuccess) {
        _showSnackBar('Authorization granted!', Colors.green);
        // Load data now that we're authorized
        await Future.wait([
          _loadSelectedApps(),
          _loadDiscouragedApps(),
          _loadAdultWebsiteBlocking(),
          _loadWebContentBlocking(),
          _loadAppQuotas(),
        ]);
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
    if (_authorizationStatus != AuthorizationStatus.authorized) return;

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
    if (_authorizationStatus != AuthorizationStatus.authorized) return;

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
    if (_authorizationStatus != AuthorizationStatus.authorized) return;

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

  Future<void> _loadWebContentBlocking() async {
    if (_authorizationStatus != AuthorizationStatus.authorized) return;

    try {
      final config = await _screenTimeApiIosPlugin.getWebContentBlocking();
      setState(() {
        _adultWebsiteBlocking = config['adultContentEnabled'] as bool? ?? false;
        _blockedDomains = List<String>.from(
          config['blockedDomains'] as List? ?? [],
        );
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading web content blocking configuration: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _loadAppQuotas() async {
    if (_authorizationStatus != AuthorizationStatus.authorized) return;

    try {
      final result = await _screenTimeApiIosPlugin.getAppQuotas();
      setState(() {
        _appQuotas = result;
        _dailyCounters = result.dailyCounters;
      });
    } catch (e, s) {
      debugPrintStack(
        label: 'Error loading app quotas: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _updateWebContentBlocking() async {
    if (_authorizationStatus != AuthorizationStatus.authorized) {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _screenTimeApiIosPlugin.setWebContentBlocking(
        adultContentEnabled: _adultWebsiteBlocking,
        blockedDomains: _blockedDomains,
      );

      _showSnackBar(
        'Web content blocking updated successfully',
        Colors.green,
      );
    } catch (e, s) {
      debugPrintStack(
        label: 'Error updating web content blocking: $e',
        stackTrace: s,
      );
      _showSnackBar('Failed to update web content blocking: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addBlockedDomain() {
    final domain = _blockedDomainController.text.trim();
    if (domain.isEmpty) return;

    if (_blockedDomains.length >= 50) {
      _showSnackBar('Maximum 50 blocked domains allowed', Colors.orange);
      return;
    }

    if (_blockedDomains.contains(domain)) {
      _showSnackBar('Domain already in blocked list', Colors.orange);
      return;
    }

    setState(() {
      _blockedDomains.add(domain);
      _blockedDomainController.clear();
    });
  }

  void _removeBlockedDomain(String domain) {
    setState(() {
      _blockedDomains.remove(domain);
    });
  }

  Future<void> _showFamilyActivityPicker() async {
    if (_authorizationStatus != AuthorizationStatus.authorized) {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      _selectedApps = await _screenTimeApiIosPlugin.showFamilyActivityPicker(
        const UICustomization(
          saveButtonFontSize: 18,
          countTextFontSize: 16,
          navigationTitleFontSize: 20,
          saveButtonColor: Color(0xFFF4FF5F),
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

  Future<void> _configureAppQuotas() async {
    if (_authorizationStatus != AuthorizationStatus.authorized) {
      _showSnackBar('Please authorize first', Colors.orange);
      return;
    }

    if (_selectedApps.totalCount == 0) {
      _showSnackBar('No apps selected to configure', Colors.orange);
      return;
    }

    final result = await showDialog<QuotaConfiguration>(
      context: context,
      builder: (context) => QuotaConfigurationDialog(
        selectedApps: _selectedApps,
        currentQuotas: _appQuotas,
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final success = await _screenTimeApiIosPlugin.setAppQuotas(result);
        if (success) {
          setState(() {
            _appQuotas = result;
          });
          await _loadDiscouragedApps(); // Refresh discouraged apps list
          _showSnackBar('App quotas configured successfully!', Colors.green);
        } else {
          _showSnackBar('Failed to configure app quotas', Colors.red);
        }
      } catch (e, s) {
        debugPrintStack(
          label: 'Error configuring app quotas: $e',
          stackTrace: s,
        );
        _showSnackBar('Failed to configure app quotas: $e', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _encourageAll() async {
    setState(() => _isLoading = true);
    try {
      await _screenTimeApiIosPlugin.encourageAll();
      setState(() {
        _selectedApps = FamilyActivitySelection.empty();
        _discouragedApps = FamilyActivitySelection.empty();
        _appQuotas = QuotaConfiguration.empty();
        _adultWebsiteBlocking =
            false; // Adult website blocking is also disabled
        _blockedDomains = []; // Clear blocked domains
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

  Future<void> _showConfigurationDialog() async {
    final controller = TextEditingController(text: _appGroupIdentifier);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Group Identifier:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'group.com.example.yourapp',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This identifier is used for sharing data between the main app '
              'and device activity extension.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_configurationStatus != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Current Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _configurationStatus!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Apply & Reconfigure'),
          ),
        ],
      ),
    );

    if (result != null && result != _appGroupIdentifier) {
      setState(() {
        _appGroupIdentifier = result;
      });
      await _configurePlugin();
      _showSnackBar(
        'Configuration updated with new app group identifier',
        Colors.green,
      );
    }
  }

  Color _getStatusColor() {
    switch (_authorizationStatus) {
      case AuthorizationStatus.authorized:
        return Colors.green;
      case AuthorizationStatus.denied:
        return Colors.red;
      case AuthorizationStatus.notDetermined:
        return Colors.orange;
      case AuthorizationStatus.unknown:
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showConfigurationDialog,
            tooltip: 'Configuration',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showLogViewer(context),
            tooltip: 'View Logs',
          ),
        ],
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
                                _authorizationStatus.value.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                          if (_configurationStatus != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Configuration Status:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _configurationStatus!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _showFamilyActivityPicker
                                    : null,
                                child: const Text('Select Apps'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    _authorizationStatus ==
                                            AuthorizationStatus.authorized &&
                                        _getSelectedTokenCount() > 0
                                    ? _configureAppQuotas
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Configure Quotas'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _encourageAll
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                                child: const Text('Encourage All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _loadSelectedApps
                                    : null,
                                child: const Text('Refresh Selected'),
                              ),
                              TextButton(
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _loadDiscouragedApps
                                    : null,
                                child: const Text('Refresh Discouraged'),
                              ),
                              TextButton(
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _loadAppQuotas
                                    : null,
                                child: const Text('Refresh Quotas'),
                              ),
                            ],
                          ),
                          // Web Content Blocking & Custom Domains Section
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Adult Content Blocking',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _adultWebsiteBlocking,
                                onChanged:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? (value) {
                                        setState(() {
                                          _adultWebsiteBlocking = value;
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                          if (_authorizationStatus !=
                              AuthorizationStatus.authorized)
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

                          // Custom Domain Blocking Section (Independent of Adult Content)
                          if (_authorizationStatus ==
                              AuthorizationStatus.authorized) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Custom Domain Blocking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Blocked Domains Section
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Blocked Domains',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_blockedDomains.length}/50',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _blockedDomains.length >= 50
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                _blockedDomainController,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Enter domain (e.g., example.com)',
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onSubmitted: (_) =>
                                                _addBlockedDomain(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _addBlockedDomain,
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                    if (_blockedDomains.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: _blockedDomains.map((domain) {
                                          return Chip(
                                            label: Text(domain),
                                            onDeleted: () =>
                                                _removeBlockedDomain(domain),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Apply Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updateWebContentBlocking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Apply Settings'),
                              ),
                            ),
                          ],
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

                  // App Quotas Display
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'App Quotas (${_appQuotas.totalCount})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    _authorizationStatus ==
                                        AuthorizationStatus.authorized
                                    ? _loadAppQuotas
                                    : null,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_appQuotas.isNotEmpty) ...[
                            for (final quota in _appQuotas.appQuotas) ...[
                              Card(
                                color: Colors.grey[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 50,
                                        child: AppLabelView(
                                          tokenType:
                                              quota.tokenType == 'application'
                                              ? TokenType.application
                                              : quota.tokenType == 'category'
                                              ? TokenType.category
                                              : TokenType.webDomain,
                                          encodedToken: quota.encodedToken,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            quota.allowedOpensPerDay == 0
                                                ? Icons.block
                                                : Icons.timer,
                                            size: 16,
                                            color: quota.allowedOpensPerDay == 0
                                                ? Colors.red
                                                : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            quota.allowedOpensPerDay == 0
                                                ? 'Completely blocked'
                                                : '${quota.allowedOpensPerDay} '
                                                      'opens per day',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  quota.allowedOpensPerDay == 0
                                                  ? Colors.red
                                                  : Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Daily usage display
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.analytics_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Builder(
                                            builder: (context) {
                                              final currentUsage =
                                                  _dailyCounters[quota
                                                      .encodedToken] ??
                                                  0;
                                              final isOverQuota =
                                                  quota.allowedOpensPerDay >
                                                      0 &&
                                                  currentUsage >=
                                                      quota.allowedOpensPerDay;
                                              return Text(
                                                'Today: $currentUsage opens'
                                                '${quota.allowedOpensPerDay > 0 ? ' / ${quota.allowedOpensPerDay}' : ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isOverQuota
                                                      ? Colors.red
                                                      : Colors.grey[600],
                                                  fontWeight: isOverQuota
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ] else ...[
                            const Text(
                              'No app quotas configured yet. Select apps and '
                              'tap "Configure Quotas" to set limits.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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

  void _showLogViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LogViewerScreen(plugin: _screenTimeApiIosPlugin),
      ),
    );
  }
}

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({required this.plugin, super.key});
  final ScreenTimeApiIos plugin;

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _logContent = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final content = await widget.plugin.getLogContent();
      setState(() => _logContent = content);
    } catch (e) {
      setState(() => _logContent = 'Error loading logs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearLogs() async {
    final success = await widget.plugin.clearLogs();
    if (mounted) {
      if (success) {
        setState(() => _logContent = '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear logs')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh Logs',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Content:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _logContent.isEmpty
                              ? 'No logs available'
                              : _logContent,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
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
