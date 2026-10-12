import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../helpers/appSettings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppSettings _settings = AppSettings.instance;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _tts.stop();
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _testTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.speak('Text to speech is enabled. This is a test.');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Settings apply app-wide; MyApp rebuilds the theme on every change.
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'GlacialIndifference',
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
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
                  fontSize: AppSettings.baseFontSize,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Read scan results aloud',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: AppSettings.baseFontSize - 2,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: _settings.textToSpeechEnabled,
              onChanged: (bool value) {
                _settings.setTextToSpeechEnabled(value);
                if (value) _testTts();
              },
              activeThumbColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            // Font Size
            Text(
              'Font Size',
              style: TextStyle(
                fontFamily: 'GlacialIndifference',
                fontSize: AppSettings.baseFontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Slider(
              value: _settings.fontSize,
              min: 12.0,
              max: 24.0,
              divisions: 6,
              label: _settings.fontSize.round().toString(),
              activeColor: colorScheme.primary,
              onChanged: _settings.setFontSize,
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
                  fontSize: AppSettings.baseFontSize,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Improve visibility for visual impairments',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: AppSettings.baseFontSize - 2,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              value: _settings.highContrastMode,
              onChanged: _settings.setHighContrastMode,
              activeThumbColor: colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            // Preview Text
            Text(
              'Preview Text',
              style: TextStyle(
                fontFamily: 'GlacialIndifference',
                fontSize: AppSettings.baseFontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a sample text to preview the font size and contrast settings.',
              style: TextStyle(
                fontFamily: 'GlacialIndifference',
                fontSize: AppSettings.baseFontSize,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
