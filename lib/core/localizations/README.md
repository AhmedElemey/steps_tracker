# Localization Guide

This app supports two languages: English and Arabic.

## Translation Files

- `app_translations_en.dart` - English translations
- `app_translations_ar.dart` - Arabic translations

## How to Use Translations

### Method 1: Using the helper extension

```dart
// In any widget, you can use:
Text(context.t('welcome'))
Text(context.t('delete_confirmation', params: {'weight': '75'}))

// Or get the service:
final l10n = context.l10n;
Text(l10n.getText('settings'))
```

### Method 2: Using the LocalizedText widget

```dart
LocalizedText('welcome')
LocalizedText('settings', style: TextStyle(fontSize: 18))
LocalizedText('delete_confirmation', params: {'weight': '75'})
```

### Method 3: Using Consumer

```dart
Consumer<LocalizationService>(
  builder: (context, localizationService, child) {
    return Text(localizationService.getText('welcome'));
  },
)
```

## Adding New Translations

1. Add the key and English value to `app_translations_en.dart`
2. Add the key and Arabic value to `app_translations_ar.dart`
3. Use the key throughout the app with any of the methods above

## Switching Languages

The language switcher is in the Settings page. It automatically updates all translated text throughout the app.

## Placeholder Parameters

To use placeholders in translations:

```dart
// In translation file:
'delete_confirmation': 'Are you sure you want to delete this weight entry of {weight} kg?'

// Usage:
context.t('delete_confirmation', params: {'weight': '75'})
```
