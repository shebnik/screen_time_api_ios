# Daily Quota System Implementation

This document explains the new daily quota system that has been added to the Screen Time API iOS plugin.

## Overview

The daily quota system introduces a flexible approach to app and category management where:

1. **Apps and categories start with 0 allowed opens per day by default**
2. **Users can configure individual quotas for each app or category**
3. **Apps/categories are only blocked when they exceed their daily quota**
4. **No immediate blocking occurs during app/category selection**

## Key Changes

### New Models

#### `AppQuota`
Represents a daily quota configuration for a single app or category:
```dart
class AppQuota {
  final String appToken;       // App/category identifier
  final String tokenType;      // 'app' or 'category'
  final int dailyLimit;        // Maximum opens per day
  final int usedToday;         // Current usage count
  
  bool get isOverQuota;        // Whether quota is exceeded
  bool get canOpen;            // Whether app can still be opened
  int get remainingOpens;      // Remaining opens for today
}
```

#### `AppQuotaCollection`
Manages a collection of app and category quotas:
```dart
class AppQuotaCollection {
  final List<AppQuota> quotas;
  
  AppQuota? getQuotaForApp(String appToken);
  List<String> get overQuotaApps;
  AppQuotaCollection updateQuota(AppQuota newQuota);
  AppQuotaCollection resetDailyUsage();
}
```

### New API Methods

#### `selectAppsForQuotaConfiguration()`
Replaces the immediate blocking behavior of `selectAppsToDiscourage()`:
```dart
// Select apps and categories without immediately blocking them
final selectedApps = await screenTime.selectAppsForQuotaConfiguration();
```

#### `setAppQuotas(AppQuotaCollection quotas)`
Configure daily quotas for selected apps and categories:
```dart
// Set quotas (does not immediately apply blocking)
await screenTime.setAppQuotas(quotaCollection);
```

#### `applyQuotaSettings()`
Apply quota-based blocking to apps/categories that have exceeded their limits:
```dart
// Only blocks apps/categories that are over their daily quota
await screenTime.applyQuotaSettings();
```

#### `getAppQuotas()`
Retrieve current quota configuration and usage:
```dart
// Get current quotas with usage statistics
final quotas = await screenTime.getAppQuotas();
```

## Implementation Details

### iOS Side

#### `QuotaManager`
New singleton class that handles:
- Quota storage and persistence
- Daily usage tracking
- Automatic daily reset
- Quota-based blocking logic

#### `FamilyControlModel` Updates
- Added `selectionForQuotaConfiguration` property
- Maintains separation between immediate blocking and quota-based selection

#### `ScreenTimeApiIosPlugin` Updates
- New method handlers for quota operations
- Mode switching between immediate and quota-based selection
- Integration with `QuotaManager`

### Flutter Side

#### Platform Interface Updates
- New method signatures for quota operations
- Backward compatibility maintained

#### Method Channel Updates
- Serialization/deserialization for quota data
- Error handling for quota operations

## Usage Example

Here's the complete workflow for implementing the daily quota system:

```dart
class QuotaWorkflow {
  final _screenTime = ScreenTimeApiIos();

  Future<void> setupDailyQuotas() async {
    // Step 1: Select apps and categories (no immediate blocking)
    final selectedApps = await _screenTime.selectAppsForQuotaConfiguration();
    
    // Step 2: Create quotas with default limits (0 = blocked)
    List<AppQuota> quotaList = [];
    
    // Add quotas for selected apps
    for (String appToken in selectedApps.applicationTokens) {
      quotaList.add(AppQuota(
        appToken: appToken,
        tokenType: 'app',
        dailyLimit: 0, // Start with 0 opens
        usedToday: 0,
      ));
    }
    
    // Add quotas for selected categories
    for (String categoryToken in selectedApps.categoryTokens) {
      quotaList.add(AppQuota(
        appToken: categoryToken,
        tokenType: 'category',
        dailyLimit: 0, // Start with 0 opens
        usedToday: 0,
      ));
    }
    
    // Step 3: Save quotas (still no blocking)
    await _screenTime.setAppQuotas(AppQuotaCollection(quotas: quotaList));
    
    // Step 4: Apply quota-based blocking
    await _screenTime.applyQuotaSettings();
  }

  Future<void> updateAppQuota(String appToken, int newLimit) async {
    // Get current quotas
    final quotas = await _screenTime.getAppQuotas();
    
    // Update specific app/category quota
    final existingQuota = quotas.getQuotaForApp(appToken);
    if (existingQuota != null) {
      final updatedQuota = existingQuota.copyWith(dailyLimit: newLimit);
      final updatedCollection = quotas.updateQuota(updatedQuota);
      
      // Save and apply changes
      await _screenTime.setAppQuotas(updatedCollection);
      await _screenTime.applyQuotaSettings();
    }
  }
}
```

## Migration Guide

### From Immediate Blocking to Quota System

**Old Approach:**
```dart
// Apps are blocked immediately after selection
final apps = await screenTime.selectAppsToDiscourage();
```

**New Approach:**
```dart
// 1. Select apps without blocking
final apps = await screenTime.selectAppsForQuotaConfiguration();

// 2. Configure quotas
final quotas = AppQuotaCollection(quotas: [
  AppQuota(appToken: apps.applicationTokens.first, dailyLimit: 5),
  // ... more quotas
]);

// 3. Save configuration
await screenTime.setAppQuotas(quotas);

// 4. Apply quota-based blocking
await screenTime.applyQuotaSettings();
```

### Backward Compatibility

The original methods (`selectAppsToDiscourage()`, `encourageAll()`) continue to work as before, maintaining backward compatibility.

## Daily Reset Mechanism

The quota system automatically resets daily usage counters:

1. **Automatic Reset**: Triggered on app startup if a new day is detected
2. **Manual Reset**: Can be triggered programmatically if needed
3. **Persistence**: Usage data is stored in `UserDefaults` and survives app restarts

## Error Handling

The quota system includes comprehensive error handling:

- Invalid quota configurations are rejected
- Network/storage errors are gracefully handled
- Fallback behaviors maintain app stability

## Testing

The implementation includes updated test coverage:

- Unit tests for quota models
- Integration tests for quota workflows
- Mock implementations for testing

## Example App

A complete example implementation is provided in `example/lib/quota_example.dart` demonstrating:

- App selection workflow
- Quota configuration UI
- Real-time quota updates
- Error handling patterns

This demonstrates the full capabilities of the daily quota system and serves as a reference implementation.
