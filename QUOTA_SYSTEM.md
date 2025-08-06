# Activity Monitoring and Quota System

This document describes how the activity monitoring and quota system works in the screen_time_api_ios plugin.

## Architecture Overview

The quota system consists of three main components:

1. **Main App (FamilyControlModel)**: Configures quotas and sets up DeviceActivity monitoring
2. **QuotaManager**: Shared class that manages quota data and daily counters using App Groups
3. **DeviceActivityMonitor Extension**: Monitors app usage and enforces quotas in real-time

## How It Works

### 1. Setting Up Quotas

When you call `setAppQuotas()`, the system:

1. Saves quota configuration to UserDefaults with App Group access
2. Separates apps into two categories:
   - **Zero quotas (allowedOpensPerDay = 0)**: Immediately blocked using ManagedSettings
   - **Non-zero quotas**: Set up for DeviceActivity monitoring

3. Creates DeviceActivity schedules to monitor app usage throughout the day

### 2. Monitoring App Usage

The DeviceActivityMonitor extension runs in the background and:

1. **Tracks app opens**: When an app is opened, it increments the daily counter
2. **Checks quotas**: Compares current usage against allowed opens per day
3. **Enforces limits**: Blocks apps that exceed their quota using ManagedSettings
4. **Resets daily**: Automatically resets counters at the start of each day

### 3. Data Sharing

The main app and extension communicate through:

- **App Groups**: Shared UserDefaults container for quota configuration and daily counters
- **Named identifier**: `group.com.example.screenTimeApiIosExample` (update this to match your app group)

## Implementation Details

### App Group Configuration

1. **Create App Group** in Apple Developer Portal
2. **Update identifier** in both QuotaManager.swift and DeviceActivityMonitorExtension.swift:
   ```swift
   private let appGroupIdentifier = "group.com.example.screenTimeApiIosExample"
   ```
3. **Enable App Groups** in your app's capabilities

### Usage Example

```dart
// Configure quotas for selected apps
final quotas = QuotaConfiguration(appQuotas: [
  AppQuota(
    encodedToken: "app_token_1",
    tokenType: "application", 
    allowedOpensPerDay: 5, // Allow 5 opens per day
  ),
  AppQuota(
    encodedToken: "app_token_2",
    tokenType: "application",
    allowedOpensPerDay: 0, // Block completely
  ),
]);

await ScreenTimeApiIos().setAppQuotas(quotas);

// Check current usage
final result = await ScreenTimeApiIos().getAppQuotas();
final dailyCounters = result['dailyCounters'] as Map<String, int>;
```

### Key Features

- ✅ **Real-time monitoring**: Apps are blocked as soon as quota is exceeded
- ✅ **Daily reset**: Counters automatically reset at midnight
- ✅ **Persistent storage**: Quota configuration survives app restarts
- ✅ **Extension communication**: Background monitoring works even when main app is closed
- ✅ **Simple API**: Easy to configure and monitor from Flutter

### Limitations

- Requires iOS 15.0+ for DeviceActivity framework
- App Groups must be configured correctly for data sharing
- Extension has limited debugging capabilities (use NSLog for logs)

### Debugging

To debug the extension:

1. **Check Console.app** for NSLog messages from the extension
2. **Filter by process**: Look for your extension's bundle identifier
3. **Common issues**:
   - App Group not configured correctly
   - Extension not being triggered
   - Token encoding/decoding issues

### Architecture Diagram

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────────┐
│   Flutter App   │    │  FamilyControl   │    │  DeviceActivityMonitor  │
│                 │    │     Model        │    │      Extension          │
├─────────────────┤    ├──────────────────┤    ├─────────────────────────┤
│ setAppQuotas()  │───▶│ Save quotas      │    │ Monitor app opens       │
│ getAppQuotas()  │    │ Setup monitoring │    │ Increment counters      │
└─────────────────┘    │ Apply blocking   │    │ Check quotas            │
                       └──────────────────┘    │ Apply dynamic blocking  │
                                ▲              └─────────────────────────┘
                                │                           │
                                └───────────────────────────┘
                                    App Group UserDefaults
                                  (Shared quota data & counters)
```

This system provides a robust foundation for app quota management while keeping the implementation simple and maintainable.
