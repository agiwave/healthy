import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Localization {
  static Map<String, String>? _localizedStrings;

  static Future<void> load(Locale locale) async {
    String jsonString = await rootBundle.loadString('lib/l10n/${locale.languageCode}.json');
    _localizedStrings = json.decode(jsonString).cast<String, String>();
  }

  static String translate(String key) {
    return _localizedStrings?[key] ?? key;
  }
} 