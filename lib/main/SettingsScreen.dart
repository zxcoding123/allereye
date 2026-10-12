import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _textToSpeechEnabled = false;
  double _fontSize = 16.0;
  bool _highContrastMode = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _textToSpeechEnabled = prefs.getBool('textToSpeechEnabled') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _highContrastMode = prefs.getBool('highContrastMode') ?? false;
    });
    if (_textToSpeechEnabled) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('textToSpeechEnabled', _textToSpeechEnabled);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('highContrastMode', _highContrastMode);
  }

  Future<void> _testTts() async {
    if (_textToSpeechEnabled) {
      await _tts.speak('Text to speech is enabled. This is a test.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSwatch(
      primarySwatch: MaterialColor(
        0xFF6994C6,
        {
          50: const Color(0xFFE6ECF5),
          100: const Color(0xFFC3D3E7),
          200: const Color(0xFF9CB7D8),
          300: const Color(0xFF759BC8),
          400: const Color(0xFF6994C6),
          500: const Color(0xFF5A85B9),
          600: const Color(0xFF5278A8),
          700: const Color(0xFF486895),
          800: const Color(0xFF3E5983),
          900: const Color(0xFF2E4163),
        },
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      errorColor: Theme.of(context).colorScheme.error,
    );

    final contrastColorScheme = _highContrastMode
        ? ColorScheme.fromSwatch(
            primarySwatch: MaterialColor(
              0xFF6994C6,
              {
                50: const Color(0xFFE6ECF5),
                100: const Color(0xFFC3D3E7),
                200: const Color(0xFF9CB7D8),
                300: const Color(0xFF759BC8),
                400: const Color(0xFF6994C6),
                500: const Color(0xFF5A85B9),
                600: const Color(0xFF5278A8),
                700: const Color(0xFF486895),
                800: const Color(0xFF3E5983),
                900: const Color(0xFF2E4163),
              },
            ),
            backgroundColor: Colors.black,
            errorColor: Colors.red,
            brightness: Brightness.dark,
          )
        : colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: contrastColorScheme),
      child: Scaffold(
        backgroundColor: contrastColorScheme.surface,
        appBar: AppBar(
          backgroundColor: contrastColorScheme.primary,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            semanticsLabel: 'Settings Title',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text-to-Speech
              SwitchListTile(
                title: Text(
                  'Text-to-Speech',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: _fontSize,
                    color: contrastColorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Read scan results aloud',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: _fontSize - 2,
                    color: contrastColorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: _textToSpeechEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _textToSpeechEnabled = value;
                  });
                  _saveSettings();
                  _testTts();
                },
                activeColor: contrastColorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              // Font Size
              Text(
                'Font Size',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: contrastColorScheme.onSurface,
                ),
                semanticsLabel: 'Font Size Title',
              ),
              Slider(
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 6,
                label: _fontSize.round().toString(),
                activeColor: contrastColorScheme.primary,
                onChanged: (double value) {
                  setState(() {
                    _fontSize = value;
                  });
                  _saveSettings();
                },
                semanticFormatterCallback: (double value) =>
                    '${value.round()} point font size',
              ),
              const SizedBox(height: 20),
              // High Contrast Mode
              SwitchListTile(
                title: Text(
                  'High Contrast Mode',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: _fontSize,
                    color: contrastColorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Improve visibility for visual impairments',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: _fontSize - 2,
                    color: contrastColorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: _highContrastMode,
                onChanged: (bool value) {
                  setState(() {
                    _highContrastMode = value;
                  });
                  _saveSettings();
                },
                activeColor: contrastColorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              // Preview Text
              Text(
                'Preview Text',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                  color: contrastColorScheme.onSurface,
                ),
                semanticsLabel: 'Preview Text Title',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This is a sample text to preview the font size and contrast settings.',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: _fontSize,
                    color: contrastColorScheme.onSurface,
                  ),
                  semanticsLabel: 'Preview Text Sample',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
