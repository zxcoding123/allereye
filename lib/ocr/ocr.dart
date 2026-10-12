import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/allergenMatcher.dart';
import '../helpers/appSettings.dart';
import '../helpers/databaseHelper.dart';
import '../auth/login.dart';
import '../main/HomeScreen.dart'; // For Scan class

enum ScanStatus {
  idle,
  noProfile,
  unreadable,
  noIngredientList,
  safe,
  caution,
  danger,
}

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  XFile? _image;
  String _productName = '';
  List<String> _foundAllergens = [];
  List<String> _mayContainAllergens = [];
  List<String> _userAllergens = [];
  List<String> _otherAllergens = [];
  ScanStatus _status = ScanStatus.idle;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadUserAllergens();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadUserAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    print('OcrScreen: loggedInEmail: $email'); // Debug logout issue

    if (email != null) {
      try {
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        print('OcrScreen: user: $user'); // Debug
        if (!mounted) return;
        if (user != null) {
          final allergensMap =
              jsonDecode(user['allergens'] ?? '{}') as Map<String, dynamic>;
          setState(() {
            _userAllergens = allergensMap.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList();
            _otherAllergens =
                AllergenMatcher.parseOtherAllergens(user['otherAllergens']);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
          navigateToLogin(context);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading allergens: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      navigateToLogin(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          _image = pickedFile;
          _productName = '';
          _foundAllergens = [];
          _mayContainAllergens = [];
          _status = ScanStatus.idle;
        });
        await _performOcr();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _performOcr() async {
    if (_image == null) return;

    try {
      final inputImage = InputImage.fromFilePath(_image!.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final result = AllergenMatcher.match(
        recognizedText.text,
        allergens: _userAllergens,
        otherAllergens: _otherAllergens,
      );

      // Extract product name
      String productName = 'Unknown Product';
      if (recognizedText.blocks.isNotEmpty) {
        productName = recognizedText.blocks.first.text.split('\n').first;
        if (productName.length > 50) {
          productName = productName.substring(0, 50);
        }
      }

      if (!mounted) return;
      setState(() {
        _foundAllergens = result.contains;
        _mayContainAllergens = result.mayContain;
        _productName = productName;
        _status = _statusFor(result);
      });

      // Only keep scans whose result can be trusted
      if (_status == ScanStatus.safe ||
          _status == ScanStatus.caution ||
          _status == ScanStatus.danger) {
        await saveScan(Scan(
          productName: productName,
          allergensFound: result.contains,
          mayContain: result.mayContain,
          scanDate: DateTime.now(),
        ));
      }

      if (AppSettings.instance.textToSpeechEnabled && mounted) {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.5);
        await _tts.speak(_resultMessage());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  ScanStatus _statusFor(AllergenMatchResult result) {
    if (_userAllergens.isEmpty && _otherAllergens.isEmpty) {
      return ScanStatus.noProfile;
    }
    if (!result.isReadable) return ScanStatus.unreadable;
    if (result.contains.isNotEmpty) return ScanStatus.danger;
    if (result.mayContain.isNotEmpty) return ScanStatus.caution;
    if (!result.hasIngredientList) return ScanStatus.noIngredientList;
    return ScanStatus.safe;
  }

  String _resultMessage() {
    switch (_status) {
      case ScanStatus.idle:
        return 'Take or choose a photo of the ingredient list.';
      case ScanStatus.noProfile:
        return 'You have not set any allergens yet. '
            'Add them in your allergen profile before scanning.';
      case ScanStatus.unreadable:
        return 'Could not read the label. Retake the photo with the '
            'ingredient list well lit and in focus.';
      case ScanStatus.noIngredientList:
        return 'No allergens found, but no ingredient list was detected. '
            'Make sure the photo shows the ingredients.';
      case ScanStatus.danger:
        final mayAlso = _mayContainAllergens.isEmpty
            ? ''
            : ' May also contain ${_mayContainAllergens.join(", ")}.';
        return 'Warning: Contains ${_foundAllergens.join(", ")}.$mayAlso';
      case ScanStatus.caution:
        return 'Caution: May contain ${_mayContainAllergens.join(", ")}.';
      case ScanStatus.safe:
        return 'No allergens from your profile detected in $_productName. '
            'Always double-check the label.';
    }
  }

  Color _resultColor(ColorScheme colorScheme) {
    switch (_status) {
      case ScanStatus.idle:
        return colorScheme.onSurface;
      case ScanStatus.safe:
        return colorScheme.primary;
      case ScanStatus.caution:
      case ScanStatus.noIngredientList:
        return Colors.orange.shade900;
      case ScanStatus.noProfile:
      case ScanStatus.unreadable:
      case ScanStatus.danger:
        return colorScheme.error;
    }
  }

  Future<void> saveScan(Scan scan) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    print('OcrScreen: Saving scan for email: $email'); // Debug

    if (email != null) {
      try {
        await DatabaseHelper.instance.insertScan(scan.toRow(email));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scan: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      navigateToLogin(context);
    }
  }

  // Home is always underneath this screen, so go back instead of
  // stacking another copy of it.
  void _navigateToHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: const Text(
            'Scan Product',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            semanticsLabel: 'Scan Product Title',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(_image!.path),
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 300,
                          width: double.infinity,
                          color: colorScheme.surface,
                          child: Center(
                            child: Text(
                              'No image selected',
                              style: TextStyle(
                                fontFamily: 'GlacialIndifference',
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              semanticsLabel: 'No Image Selected',
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tip: Ensure the label is well-lit and in focus',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  semanticsLabel: 'Image Capture Tip',
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Camera',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      semanticsLabel: 'Camera Button',
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Gallery',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      semanticsLabel: 'Gallery Button',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Scan Results
              Text(
                'Scan Results',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                semanticsLabel: 'Scan Results Title',
              ),
              const SizedBox(height: 8),
              Text(
                'Checking for: ${_userAllergens.isEmpty && _otherAllergens.isEmpty ? "No allergens set" : [..._userAllergens, ..._otherAllergens].join(", ")}',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Product: $_productName',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _resultMessage(),
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    color: _resultColor(colorScheme),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Back to Home Button
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontFamily: 'GlacialIndifference',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    semanticsLabel: 'Back to Home Button',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
