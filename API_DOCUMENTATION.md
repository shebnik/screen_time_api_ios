# Screen Time API iOS

A Flutter plugin that provides access to iOS Screen Time API for managing app usage restrictions.

## Features

- ✅ Request Screen Time API authorization
- ✅ Check authorization status
- ✅ Select apps to discourage (restrict)
- ✅ Get list of currently restricted apps
- ✅ Remove all restrictions (encourage all apps)
- ✅ Proper error handling and authorization flow

## Getting Started

### Prerequisites

- iOS 13.0 or later
- Xcode 12 or later
- Flutter 2.5 or later

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  screen_time_api_ios: ^0.1.0
```

### iOS Setup

Add the following capability to your iOS app's `Runner.entitlements` file:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

Also add the usage description to your `Info.plist`:

```xml
<key>NSFamilyControlsUsageDescription</key>
<string>This app uses Screen Time API to help manage app usage.</string>
```

## Usage

### Basic Example

```dart
import 'package:screen_time_api_ios/screen_time_api_ios.dart';

class ScreenTimeManager {
  final _plugin = ScreenTimeApiIos();

  // Check if already authorized
  Future<bool> checkAuthorization() async {
    return await _plugin.isAuthorized();
  }

  // Request authorization
  Future<bool> requestAuthorization() async {
    final response = await _plugin.requestAuthorization();
    return response.status.isSuccess;
  }

  // Show Family Activity Picker
  Future<FamilyActivitySelection?> showFamilyActivityPicker() async {
    try {
      return await _plugin.showFamilyActivityPicker();
    } catch (e) {
      print('Error showing family activity picker: $e');
      return null;
    }
  }

  // Restrict Apps by FamilyActivitySelection
  Future<bool> restrictApps(FamilyActivitySelection selection) async {
    return await _plugin.discourage(selection);
  }

  // Get currently restricted apps
  Future<FamilyActivitySelection> getRestrictedApps() async {
    return await _plugin.getDiscouragedApps();
  }

  // Remove all restrictions
  Future<void> removeAllRestrictions() async {
    await _plugin.encourageAll();
  }
}
```

## API Reference

### Authorization Methods

#### `requestAuthorization()`
Requests permission to use Screen Time API.
- **Returns**: `Future<AuthorizationResponse>`
- **Throws**: `PlatformException` if the request fails

#### `getAuthorizationStatus()`
Gets the current authorization status.
- **Returns**: `Future<AuthorizationResponse>`

#### `isAuthorized()`
Checks if the app is currently authorized.
- **Returns**: `Future<bool>`

### App Management Methods

#### `selectAppsToDiscourage()`
Presents the native iOS app selection interface.
- **Returns**: `Future<List<String>>` - List of selected app/category tokens
- **Requires**: Authorization must be granted first
- **Throws**: `PlatformException` if not authorized

#### `getDiscouragedApps()`
Gets the list of currently restricted apps.
- **Returns**: `Future<List<String>>` - List of app/category tokens

#### `encourageAll()`
Removes all app restrictions.
- **Returns**: `Future<void>`

## Models

### AuthorizationStatus
Represents the authorization state:
- `notDetermined` - User hasn't been asked yet
- `denied` - User denied permission
- `authorized` - User granted permission
- `unknown` - Unknown state

### AuthorizationResponse
Contains the result of authorization operations:
- `status` - The `AuthorizationStatus`
- `error` - Error message if failed
- `isSuccess` - Whether the operation succeeded
- `isFailure` - Whether the operation failed

## Error Handling

The plugin throws `PlatformException` with specific error codes:

- `AUTHORIZATION_FAILED` - Failed to get authorization
- `NOT_AUTHORIZED` - Attempted to use features without authorization

```dart
try {
  final apps = await screenTime.selectAppsToDiscourage();
} on PlatformException catch (e) {
  if (e.code == 'NOT_AUTHORIZED') {
    // Handle authorization error
    await screenTime.requestAuthorization();
  }
}
```

## Limitations

- iOS only (Screen Time API is not available on Android)
- Requires iOS 13.0 or later
- App must be signed with proper entitlements
- Cannot identify specific apps from tokens (Apple privacy restriction)

## Contributing

Contributions are welcome! Please read our contributing guide and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
