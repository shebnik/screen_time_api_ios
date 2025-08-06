import 'package:flutter/material.dart';

/// UI customization model for the family activity picker
@immutable
class UICustomization {
  const UICustomization({
    this.navigationTitle,
    this.saveButtonText,
    this.appsCountText,
    this.websitesCountText,
    this.categoriesCountText,
    this.saveButtonColor,
    this.saveButtonTextColor,
    this.countTextColor,
    this.navigationTintColor,
    this.darkTextColor,
    this.saveButtonFontSize,
    this.countTextFontSize,
    this.navigationTitleFontSize,
  });

  /// Create UICustomization from a map of arguments
  factory UICustomization.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UICustomization();

    return UICustomization(
      navigationTitle: map['navigationTitle'] as String?,
      saveButtonText: map['saveButtonText'] as String?,
      appsCountText: map['appsCountText'] as String?,
      websitesCountText: map['websitesCountText'] as String?,
      categoriesCountText: map['categoriesCountText'] as String?,
      saveButtonColor: _colorFromHex(map['saveButtonColor'] as String?),
      saveButtonTextColor: _colorFromHex(map['saveButtonTextColor'] as String?),
      countTextColor: _colorFromHex(map['countTextColor'] as String?),
      navigationTintColor: _colorFromHex(map['navigationTintColor'] as String?),
      darkTextColor: _colorFromHex(map['darkTextColor'] as String?),
      saveButtonFontSize: map['saveButtonFontSize'] as double?,
      countTextFontSize: map['countTextFontSize'] as double?,
      navigationTitleFontSize: map['navigationTitleFontSize'] as double?,
    );
  }

  /// Title for the navigation bar
  final String? navigationTitle;

  /// Text for the save button
  final String? saveButtonText;

  /// Label for apps count
  final String? appsCountText;

  /// Label for websites count
  final String? websitesCountText;

  /// Label for categories count
  final String? categoriesCountText;

  /// Color for save button background
  final Color? saveButtonColor;

  /// Color for save button text
  final Color? saveButtonTextColor;

  /// Color for count labels
  final Color? countTextColor;

  /// Color for navigation icons
  final Color? navigationTintColor;

  /// Color for dark text elements
  final Color? darkTextColor;

  /// Font size for save button
  final double? saveButtonFontSize;

  /// Font size for count labels
  final double? countTextFontSize;

  /// Font size for navigation title
  final double? navigationTitleFontSize;

  /// Helper method to convert hex string to Color
  static Color? _colorFromHex(String? hex) {
    if (hex == null) return null;

    var hexString = hex.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString'; // Add alpha if not provided
    }

    final value = int.tryParse(hexString, radix: 16);
    if (value == null) return null;

    // Extract ARGB components
    final a = (value >> 24) & 0xFF;
    final r = (value >> 16) & 0xFF;
    final g = (value >> 8) & 0xFF;
    final b = value & 0xFF;

    return Color.fromARGB(a, r, g, b);
  }

  /// Helper method to convert Color to hex string
  static String? _colorToHex(Color? color) {
    if (color == null) return null;
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Convert UICustomization to a map for platform channel communication
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (navigationTitle != null) map['navigationTitle'] = navigationTitle;
    if (saveButtonText != null) map['saveButtonText'] = saveButtonText;
    if (appsCountText != null) map['appsCountText'] = appsCountText;
    if (websitesCountText != null) map['websitesCountText'] = websitesCountText;
    if (categoriesCountText != null) {
      map['categoriesCountText'] = categoriesCountText;
    }
    if (saveButtonColor != null) {
      map['saveButtonColor'] = _colorToHex(saveButtonColor);
    }
    if (saveButtonTextColor != null) {
      map['saveButtonTextColor'] = _colorToHex(saveButtonTextColor);
    }
    if (countTextColor != null) {
      map['countTextColor'] = _colorToHex(countTextColor);
    }
    if (navigationTintColor != null) {
      map['navigationTintColor'] = _colorToHex(navigationTintColor);
    }
    if (darkTextColor != null) {
      map['darkTextColor'] = _colorToHex(darkTextColor);
    }
    if (saveButtonFontSize != null) {
      map['saveButtonFontSize'] = saveButtonFontSize;
    }
    if (countTextFontSize != null) map['countTextFontSize'] = countTextFontSize;
    if (navigationTitleFontSize != null) {
      map['navigationTitleFontSize'] = navigationTitleFontSize;
    }

    return map;
  }

  /// Create a copy of this UICustomization with updated values
  UICustomization copyWith({
    String? navigationTitle,
    String? saveButtonText,
    String? appsCountText,
    String? websitesCountText,
    String? categoriesCountText,
    Color? saveButtonColor,
    Color? saveButtonTextColor,
    Color? countTextColor,
    Color? navigationTintColor,
    double? saveButtonFontSize,
    double? countTextFontSize,
    double? navigationTitleFontSize,
  }) {
    return UICustomization(
      navigationTitle: navigationTitle ?? this.navigationTitle,
      saveButtonText: saveButtonText ?? this.saveButtonText,
      appsCountText: appsCountText ?? this.appsCountText,
      websitesCountText: websitesCountText ?? this.websitesCountText,
      categoriesCountText: categoriesCountText ?? this.categoriesCountText,
      saveButtonColor: saveButtonColor ?? this.saveButtonColor,
      saveButtonTextColor: saveButtonTextColor ?? this.saveButtonTextColor,
      countTextColor: countTextColor ?? this.countTextColor,
      navigationTintColor: navigationTintColor ?? this.navigationTintColor,
      saveButtonFontSize: saveButtonFontSize ?? this.saveButtonFontSize,
      countTextFontSize: countTextFontSize ?? this.countTextFontSize,
      navigationTitleFontSize:
          navigationTitleFontSize ?? this.navigationTitleFontSize,
    );
  }

  @override
  String toString() {
    return 'UICustomization('
        'navigationTitle: $navigationTitle, '
        'saveButtonText: $saveButtonText, '
        'appsCountText: $appsCountText, '
        'websitesCountText: $websitesCountText, '
        'categoriesCountText: $categoriesCountText, '
        'saveButtonColor: $saveButtonColor, '
        'saveButtonTextColor: $saveButtonTextColor, '
        'countTextColor: $countTextColor, '
        'navigationTintColor: $navigationTintColor, '
        'saveButtonFontSize: $saveButtonFontSize, '
        'countTextFontSize: $countTextFontSize, '
        'navigationTitleFontSize: $navigationTitleFontSize'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UICustomization &&
        other.navigationTitle == navigationTitle &&
        other.saveButtonText == saveButtonText &&
        other.appsCountText == appsCountText &&
        other.websitesCountText == websitesCountText &&
        other.categoriesCountText == categoriesCountText &&
        other.saveButtonColor == saveButtonColor &&
        other.saveButtonTextColor == saveButtonTextColor &&
        other.countTextColor == countTextColor &&
        other.navigationTintColor == navigationTintColor &&
        other.saveButtonFontSize == saveButtonFontSize &&
        other.countTextFontSize == countTextFontSize &&
        other.navigationTitleFontSize == navigationTitleFontSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      navigationTitle,
      saveButtonText,
      appsCountText,
      websitesCountText,
      categoriesCountText,
      saveButtonColor,
      saveButtonTextColor,
      countTextColor,
      navigationTintColor,
      saveButtonFontSize,
      countTextFontSize,
      navigationTitleFontSize,
    );
  }
}

/// Predefined UI themes for common use cases
class UIThemes {
  /// Default iOS system theme
  static const UICustomization defaultTheme = UICustomization(
    navigationTitle: 'Select Apps',
    saveButtonText: 'Save',
    appsCountText: 'Apps',
    websitesCountText: 'Websites',
    categoriesCountText: 'Categories',
  );

  /// Dark theme with dark colors
  static const UICustomization darkTheme = UICustomization(
    navigationTitle: 'Select Apps',
    saveButtonText: 'Save',
    appsCountText: 'Apps',
    websitesCountText: 'Websites',
    categoriesCountText: 'Categories',
    saveButtonColor: Color(0xFF1C1C1E),
    saveButtonTextColor: Color(0xFFFFFFFF),
    countTextColor: Color(0xFF98989D),
    navigationTintColor: Color(0xFF007AFF),
  );

  /// Orange accent theme
  static const UICustomization orangeTheme = UICustomization(
    navigationTitle: 'Select Apps',
    saveButtonText: 'Save Selection',
    appsCountText: 'Applications',
    websitesCountText: 'Websites',
    categoriesCountText: 'Categories',
    saveButtonColor: Color(0xFFFF6B35),
    saveButtonTextColor: Color(0xFFFFFFFF),
    countTextColor: Color(0xFF6B7280),
    navigationTintColor: Color(0xFFFF6B35),
    saveButtonFontSize: 18,
    countTextFontSize: 16,
  );

  /// Green theme
  static const UICustomization greenTheme = UICustomization(
    navigationTitle: 'Select Apps',
    saveButtonText: 'Save',
    appsCountText: 'Apps',
    websitesCountText: 'Websites',
    categoriesCountText: 'Categories',
    saveButtonColor: Color(0xFF34C759),
    saveButtonTextColor: Color(0xFFFFFFFF),
    countTextColor: Color(0xFF6B7280),
    navigationTintColor: Color(0xFF34C759),
  );

  /// Red theme
  static const UICustomization redTheme = UICustomization(
    navigationTitle: 'Select Apps',
    saveButtonText: 'Save',
    appsCountText: 'Apps',
    websitesCountText: 'Websites',
    categoriesCountText: 'Categories',
    saveButtonColor: Color(0xFFFF3B30),
    saveButtonTextColor: Color(0xFFFFFFFF),
    countTextColor: Color(0xFF6B7280),
    navigationTintColor: Color(0xFFFF3B30),
  );
}

/// Localization helper for different languages
class UILocalizations {
  static const Map<String, UICustomization> _localizations = {
    'en': UICustomization(
      navigationTitle: 'Select Apps',
      saveButtonText: 'Save',
      appsCountText: 'Apps',
      websitesCountText: 'Websites',
      categoriesCountText: 'Categories',
    ),
    'es': UICustomization(
      navigationTitle: 'Seleccionar Apps',
      saveButtonText: 'Guardar',
      appsCountText: 'Apps',
      websitesCountText: 'Sitios Web',
      categoriesCountText: 'Categorías',
    ),
    'fr': UICustomization(
      navigationTitle: 'Sélectionner Apps',
      saveButtonText: 'Enregistrer',
      appsCountText: 'Apps',
      websitesCountText: 'Sites Web',
      categoriesCountText: 'Catégories',
    ),
    'de': UICustomization(
      navigationTitle: 'Apps Auswählen',
      saveButtonText: 'Speichern',
      appsCountText: 'Apps',
      websitesCountText: 'Webseiten',
      categoriesCountText: 'Kategorien',
    ),
    'it': UICustomization(
      navigationTitle: 'Seleziona App',
      saveButtonText: 'Salva',
      appsCountText: 'App',
      websitesCountText: 'Siti Web',
      categoriesCountText: 'Categorie',
    ),
    'pt': UICustomization(
      navigationTitle: 'Selecionar Apps',
      saveButtonText: 'Salvar',
      appsCountText: 'Apps',
      websitesCountText: 'Sites',
      categoriesCountText: 'Categorias',
    ),
    'ja': UICustomization(
      navigationTitle: 'アプリを選択',
      saveButtonText: '保存',
      appsCountText: 'アプリ',
      websitesCountText: 'ウェブサイト',
      categoriesCountText: 'カテゴリ',
    ),
    'ko': UICustomization(
      navigationTitle: '앱 선택',
      saveButtonText: '저장',
      appsCountText: '앱',
      websitesCountText: '웹사이트',
      categoriesCountText: '카테고리',
    ),
    'zh': UICustomization(
      navigationTitle: '选择应用',
      saveButtonText: '保存',
      appsCountText: '应用',
      websitesCountText: '网站',
      categoriesCountText: '类别',
    ),
  };

  /// Get localized UI customization for the given language code
  static UICustomization getLocalization(String languageCode) {
    return _localizations[languageCode] ?? _localizations['en']!;
  }

  /// Get available language codes
  static List<String> get availableLanguages => _localizations.keys.toList();
}
