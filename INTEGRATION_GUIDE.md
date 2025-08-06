# Activity Monitor4. Use identifier: `group.com.example.screenTimeApiIosExample` (or customize based on your bundle ID)ng Setup Guide

This guide explains how to integrate the activity monitoring system for app quotas in your iOS app.

## Prerequisites

- iOS 15.0 or later
- Xcode 13 or later
- Apple Developer account with Family Controls capability

## Step 1: Configure App Groups

### 1.1 Create App Group in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Select "App Groups" under "Identifiers"
4. Click "+" to create a new App Group
5. Use identifier: `group.screen.time.api.ios` (or customize it)

### 1.2 Add App Group to App ID

1. In Developer Portal, go to "App IDs"
2. Select your app's identifier
3. Enable "App Groups" capability
4. Configure it to use the App Group created above

### 1.3 Update Entitlements Files

Main app entitlements (`Runner.entitlements`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.example.screenTimeApiIosExample</string>
</array>
```

Extension entitlements (`DeviceActivityMonitor.entitlements`):
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.example.screenTimeApiIosExample</string>
</array>
```

## Step 2: Update App Group Identifier

If you customize the App Group identifier, update it in:

1. **QuotaManager.swift**:
```swift
private let appGroupIdentifier = "group.com.example.screenTimeApiIosExample"
```

2. **DeviceActivityMonitorExtension.swift**:
```swift
private let appGroupIdentifier = "group.com.example.screenTimeApiIosExample"
```

## Step 3: Device Activity Monitor Extension

### 3.1 Verify Extension Target

Ensure your DeviceActivityMonitor extension is properly configured:

- **Target Name**: DeviceActivityMonitor
- **Bundle Identifier**: `your.app.bundle.id.DeviceActivityMonitor`
- **Extension Point**: `com.apple.deviceactivity.monitor-extension`

### 3.2 Extension Info.plist

Verify `Info.plist` contains:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.deviceactivity.monitor-extension</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).DeviceActivityMonitorExtension</string>
</dict>
```

## Step 4: Build and Test

### 4.1 Build Configuration

1. Build both the main app and extension targets
2. Ensure no compilation errors
3. Deploy to a physical iOS device (required for Screen Time APIs)

### 4.2 Testing the Quota System

```dart
// 1. Request authorization
final authResponse = await ScreenTimeApiIos().requestAuthorization();
if (!authResponse.status.isAuthorized) {
  print('Authorization failed');
  return;
}

// 2. Select apps to monitor
final selection = await ScreenTimeApiIos().showFamilyActivityPicker();

// 3. Configure quotas
final quotas = QuotaConfiguration(appQuotas: [
  // Allow 3 opens per day
  AppQuota(
    encodedToken: selection.applicationTokens.first,
    tokenType: "application",
    allowedOpensPerDay: 3,
  ),
  // Block completely
  AppQuota(
    encodedToken: selection.applicationTokens.last,
    tokenType: "application", 
    allowedOpensPerDay: 0,
  ),
]);

// 4. Apply quotas
final success = await ScreenTimeApiIos().setAppQuotas(quotas);
print('Quotas applied: $success');

// 5. Check usage
final result = await ScreenTimeApiIos().getAppQuotas();
final dailyCounters = result['dailyCounters'] as Map<String, int>;
print('Daily usage: $dailyCounters');
```

## Step 5: Debugging

### 5.1 Check Extension Logs

1. Open Console.app on Mac
2. Connect iOS device
3. Filter by your extension's bundle identifier
4. Look for NSLog messages from the extension

### 5.2 Common Issues

**Extension not loading:**
- Verify bundle identifier matches Info.plist
- Check entitlements are properly configured
- Ensure App Group is correctly set up

**Quotas not enforcing:**
- Verify App Group identifier matches between app and extension
- Check that DeviceActivity monitoring is being set up
- Ensure the extension is receiving events

**Data not syncing:**
- Verify App Groups entitlements
- Check UserDefaults suite name matches App Group identifier
- Ensure both targets have App Groups enabled

### 5.3 Debug Extensions

```swift
// Add to DeviceActivityMonitorExtension
override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    super.eventDidReachThreshold(event, activity: activity)
    NSLog("🔥 Extension Debug: Event triggered - \(event)")
    
    // Your quota logic here...
}
```

## Step 6: Production Considerations

### 6.1 App Store Requirements

- Family Controls capability must be approved by Apple
- Provide clear privacy policy explaining Screen Time usage
- App must have legitimate parental control or productivity use case

### 6.2 Performance

- Extension runs in limited memory environment
- Keep quota logic simple and efficient
- Use NSLog sparingly to avoid performance impact

### 6.3 Privacy

- Screen Time data is sensitive
- Don't transmit token data over network
- Store only necessary quota information

## Architecture Summary

```
┌─────────────────┐    App Groups UserDefaults    ┌─────────────────────────┐
│   Main App      │◄──────────────────────────────►│  DeviceActivity Monitor │
│                 │                                │      Extension          │
│ ┌─────────────┐ │                                │                         │
│ │QuotaManager │ │    Shared Data:                │ ┌─────────────────────┐ │
│ │             │ │    • Quota config              │ │ExtensionQuotaManager│ │
│ │ - Save      │ │    • Daily counters            │ │                     │ │
│ │ - Monitor   │ │    • Reset timestamps          │ │ - Monitor events    │ │
│ │ - Block     │ │                                │ │ - Increment counts  │ │
│ └─────────────┘ │                                │ │ - Apply blocking    │ │
└─────────────────┘                                │ └─────────────────────┘ │
                                                   └─────────────────────────┘
```

The system provides real-time app quota enforcement with minimal setup required!
