import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

/// Helper extension to easily access localization in widgets
extension LocalizationExtension on BuildContext {
  LocalizationService get l10n {
    return read<LocalizationService>();
  }
  
  String t(String key, {Map<String, String>? params}) {
    return read<LocalizationService>().getText(key, params: params);
  }
}

/// Helper widget to automatically rebuild when language changes
class LocalizedText extends StatelessWidget {
  final String translationKey;
  final Map<String, String>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.translationKey, {
    super.key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Text(
          localizationService.getText(translationKey, params: params),
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
