import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../helpers/databaseHelper.dart';
import '../auth/login.dart';
import '../main/HomeScreen.dart'; // For Scan class

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  XFile? _image;
  String _recognizedText = '';
  String _productName = '';
  List<String> _foundAllergens = [];
  List<String> _userAllergens = [];
  final Map<String, List<String>> _allergenSynonyms = {
    'Peanuts': ['peanut', 'groundnut'],
    'Gluten': ['gluten', 'wheat', 'barley', 'rye'],
    'Dairy': ['milk', 'cheese', 'yogurt', 'lactose'],
    'Shellfish': ['shrimp', 'crab', 'lobster', 'prawn'],
    'Eggs': ['egg', 'albumin'],
    'Soy': ['soy', 'soya', 'soybean'],
    'Tree Nuts': ['almond', 'walnut', 'cashew', 'hazelnut'],
    'Wheat': ['wheat', 'flour'],
    'Fish': ['fish', 'salmon', 'tuna', 'cod'],
    'Sesame': ['sesame', 'tahini'],
    'Mustard': ['mustard', 'mustard seed'],
    'Lupin': ['lupin', 'lupine'],
    'Celery': ['celery', 'celeriac'],
    'Mollusks': ['clam', 'mussel', 'oyster', 'squid'],
    'Sulfites': ['sulfite', 'sulphite', 'sulfur dioxide'],
  };
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserAllergens();
  }

  @override
  void dispose() {
    _textRecognizer.close();
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
        if (user != null) {
          final allergensMap =
              jsonDecode(user['allergens'] ?? '{}') as Map<String, dynamic>;
          setState(() {
            _userAllergens = allergensMap.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading allergens: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _recognizedText = '';
          _productName = '';
          _foundAllergens = [];
        });
        await _performOcr();
      }
    } catch (e) {
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

      // Detect allergens in recognized text
      final text = recognizedText.text.toLowerCase();
      final foundAllergens = _userAllergens.where((allergen) {
        final synonyms = _allergenSynonyms[allergen] ?? [allergen];
        return synonyms.any((synonym) => text.contains(synonym.toLowerCase()));
      }).toList();

      // Extract product name
      String productName = 'Unknown Product';
      if (recognizedText.blocks.isNotEmpty) {
        productName = recognizedText.blocks.first.text.split('\n').first;
        if (productName.length > 50) {
          productName = productName.substring(0, 50);
        }
      }

      // Create Scan object
      final scan = Scan(
        productName: productName,
        allergensFound: foundAllergens,
        scanDate: DateTime.now(),
      );

      setState(() {
        _recognizedText = recognizedText.text;
        _foundAllergens = foundAllergens;
        _productName = productName;
      });

      // Text-to-speech
      final prefs = await SharedPreferences.getInstance();
      final ttsEnabled = prefs.getBool('textToSpeechEnabled') ?? true;
      if (ttsEnabled) {
        final tts = FlutterTts();
        await tts.setLanguage('en-US');
        await tts.setSpeechRate(0.5);
        await tts.speak(foundAllergens.isEmpty
            ? 'Safe: No allergens detected in $productName'
            : 'Warning: Found ${foundAllergens.join(", ")} in scanned product!');
      }

      // Save scan
      await saveScan(scan);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  Future<void> saveScan(Scan scan) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    print('OcrScreen: Saving scan for email: $email'); // Debug

    if (email != null) {
      try {
        // Save to database
        final db = await DatabaseHelper.instance.database;
        await db.insert('scans', {
          'userEmail': email,
          'productName': scan.productName,
          'allergensFound': jsonEncode(scan.allergensFound),
          'scanDate': scan.scanDate.toIso8601String(),
        });

        // Save to SharedPreferences
        final scansJson = prefs.getString('recentScans');
        List<Scan> scans = [];
        if (scansJson != null) {
          final List<dynamic> scansList = jsonDecode(scansJson);
          scans = scansList
              .map((json) => Scan.fromJson(json))
              .where((scan) => scan != null) // Ensure no null scans
              .toList();
        }
        scans.insert(0, scan);
        if (scans.length > 10) {
          scans = scans.sublist(0, 10);
        }
        await prefs.setString(
          'recentScans',
          jsonEncode(scans
              .where((s) => s != null) // Extra safety for serialization
              .map((s) => s.toJson())
              .toList()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scan: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
                'Checking for: ${_userAllergens.isEmpty ? "No allergens set" : _userAllergens.join(", ")}',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  color: colorScheme.onSurface,
                ),
                semanticsLabel: 'Allergens Being Checked',
              ),
              const SizedBox(height: 8),
              Text(
                'Product: $_productName',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  color: colorScheme.onSurface,
                ),
                semanticsLabel: 'Product Name',
              ),
              const SizedBox(height: 8),
              Text(
                _foundAllergens.isEmpty
                    ? 'Safe: No allergens detected'
                    : 'Warning: Found ${_foundAllergens.join(", ")}',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  color: _foundAllergens.isEmpty
                      ? colorScheme.primary
                      : colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: _foundAllergens.isEmpty
                    ? 'Safe No Allergens'
                    : 'Warning Allergens Found',
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
