import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF007AFF), // iOS 蓝色
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true, // iOS 风格居中标题
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF007AFF)),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS 背景色
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: Color(0xFF007AFF),
      ),
    );
  }
} 