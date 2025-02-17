import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../utils/localization.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.translate('change_language')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('English'),
            onTap: () {
              _changeLanguage(context, const Locale('en'));
            },
          ),
          ListTile(
            title: const Text('中文'),
            onTap: () {
              _changeLanguage(context, const Locale('zh'));
            },
          ),
          ListTile(
            title: const Text('日本語'),
            onTap: () {
              _changeLanguage(context, const Locale('ja'));
            },
          ),
          ListTile(
            title: const Text('한국어'),
            onTap: () {
              _changeLanguage(context, const Locale('ko'));
            },
          ),
        ],
      ),
    );
  }

  void _changeLanguage(BuildContext context, Locale locale) {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
    Localization.load(locale); // Load the new locale
    Navigator.pop(context); // Go back to the previous screen
  }
}