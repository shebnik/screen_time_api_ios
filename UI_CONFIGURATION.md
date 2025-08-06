# UI Configuration Documentation

## Overview
The Screen Time API iOS plugin now supports customizable UI elements including colors, texts, and fonts. This allows for localization and theming from the Flutter side.

## Available Methods

### 1. selectAppsToDiscourage([uiConfig])
Present the app selection UI with optional configuration for customization and localization.

### 2. showFamilyActivityPicker([uiConfig]) 
Alternative method name that matches the iOS implementation. Same functionality as selectAppsToDiscourage().

### 3. getSelectedApps()
Get the currently saved/selected apps and categories (persistent selection).

### 4. getTempSelection()
Get the temporary selection (current picker state before saving).

### 5. discourageApps(tokenData)
Apply restrictions to specific apps using provided token data.

## Configuration Parameters

When calling `selectAppsToDiscourage()` or `showFamilyActivityPicker()`, you can pass an optional configuration map:

```dart
await ScreenTimeApiIos().selectAppsToDiscourage({
  // Text Configuration
  'navigationTitle': 'Select Apps',
  'saveButtonText': 'Save',
  'appsCountText': 'Apps',
  'websitesCountText': 'Websites', 
  'categoriesCountText': 'Categories',
  
  // Color Configuration (hex strings)
  'saveButtonColor': '#007AFF',        // Blue
  'saveButtonTextColor': '#FFFFFF',    // White
  'countTextColor': '#8E8E93',         // Secondary gray
  'navigationTintColor': '#007AFF',    // Navigation icons color
  
  // Font Configuration
  'saveButtonFontSize': 16.0,
  'countTextFontSize': 14.0,
  'navigationTitleFontSize': 17.0,
});
```

## Parameters Details

### Text Parameters
- `navigationTitle` (String): Title shown in navigation bar
- `saveButtonText` (String): Text displayed on save button
- `appsCountText` (String): Label for apps count display
- `websitesCountText` (String): Label for websites count display
- `categoriesCountText` (String): Label for categories count display

### Color Parameters
All colors should be provided as hex strings (e.g., "#FF0000" for red):
- `saveButtonColor`: Background color of save button
- `saveButtonTextColor`: Text color of save button
- `countTextColor`: Color of count text labels
- `navigationTintColor`: Color of navigation bar icons

### Font Parameters
- `saveButtonFontSize` (Double): Font size for save button text
- `countTextFontSize` (Double): Font size for count labels
- `navigationTitleFontSize` (Double): Font size for navigation title

## Default Values
If no configuration is provided, the following defaults are used:
- Navigation Title: "Select Apps"
- Save Button: "Save" (Blue background, white text)
- Count Labels: "Apps", "Websites", "Categories" (Secondary gray color)
- Fonts: System default sizes

## Localization Example

```dart
// English
await ScreenTimeApiIos().showFamilyActivityPicker({
  'navigationTitle': 'Select Apps',
  'saveButtonText': 'Save',
  'appsCountText': 'Apps',
  'websitesCountText': 'Websites',
  'categoriesCountText': 'Categories',
});

// Spanish
await ScreenTimeApiIos().showFamilyActivityPicker({
  'navigationTitle': 'Seleccionar Apps',
  'saveButtonText': 'Guardar',
  'appsCountText': 'Apps',
  'websitesCountText': 'Sitios Web',
  'categoriesCountText': 'Categorías',
});

// French
await ScreenTimeApiIos().showFamilyActivityPicker({
  'navigationTitle': 'Sélectionner Apps',
  'saveButtonText': 'Enregistrer',
  'appsCountText': 'Apps',
  'websitesCountText': 'Sites Web',
  'categoriesCountText': 'Catégories',
});
```

## Theme Example

```dart
// Dark theme
await ScreenTimeApiIos().showFamilyActivityPicker({
  'saveButtonColor': '#1C1C1E',
  'saveButtonTextColor': '#FFFFFF',
  'countTextColor': '#98989D',
  'navigationTintColor': '#007AFF',
});

// Custom brand theme
await ScreenTimeApiIos().showFamilyActivityPicker({
  'saveButtonColor': '#FF6B35',        // Orange
  'saveButtonTextColor': '#FFFFFF',
  'countTextColor': '#6B7280',         // Gray
  'navigationTintColor': '#FF6B35',
});
```
