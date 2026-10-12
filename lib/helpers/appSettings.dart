import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility settings, applied app-wide by MyApp.
class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  AppSettings._();

  static const double baseFontSize = 16.0;

  static const MaterialColor _brandSwatch = MaterialColor(
    0xFF6994C6,
    {
      50: Color(0xFFE6ECF5),
      100: Color(0xFFC3D3E7),
      200: Color(0xFF9CB7D8),
      300: Color(0xFF759BC8),
      400: Color(0xFF6994C6),
      500: Color(0xFF5A85B9),
      600: Color(0xFF5278A8),
      700: Color(0xFF486895),
      800: Color(0xFF3E5983),
      900: Color(0xFF2E4163),
    },
  );

  bool _textToSpeechEnabled = true;
  double _fontSize = baseFontSize;
  bool _highContrastMode = false;

  bool get textToSpeechEnabled => _textToSpeechEnabled;
  double get fontSize => _fontSize;
  bool get highContrastMode => _highContrastMode;

  /// Multiplier applied on top of the system text scale.
  double get textScale => _fontSize / baseFontSize;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textToSpeechEnabled = prefs.getBool('textToSpeechEnabled') ?? true;
    _fontSize = prefs.getDouble('fontSize') ?? baseFontSize;
    _highContrastMode = prefs.getBool('highContrastMode') ?? false;
    notifyListeners();
  }

  Future<void> setTextToSpeechEnabled(bool value) async {
    _textToSpeechEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('textToSpeechEnabled', value);
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
  }

  Future<void> setHighContrastMode(bool value) async {
    _highContrastMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrastMode', value);
  }

  ThemeData get theme {
    final base = ColorScheme.fromSeed(seedColor: Colors.grey);
    final colorScheme = _highContrastMode
        ? const ColorScheme.light(
            primary: Color(0xFF1F3A5F),
            onPrimary: Colors.white,
            secondary: Color(0xFF1F3A5F),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            error: Color(0xFFB00020),
            onError: Colors.white,
          )
        : ColorScheme.fromSwatch(
            primarySwatch: _brandSwatch,
            backgroundColor: base.surface,
            errorColor: base.error,
          );
    return ThemeData(
      fontFamily: 'GlacialIndifference',
      colorScheme: colorScheme,
    );
  }
}
