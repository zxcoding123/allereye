import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../helpers/databaseHelper.dart';
import '../main/HomeScreen.dart'; // For Scan class
import '../auth/login.dart';

class AllergenProfileScreen extends StatefulWidget {
  const AllergenProfileScreen({super.key});

  @override
  _AllergenProfileScreenState createState() => _AllergenProfileScreenState();
}

class _AllergenProfileScreenState extends State<AllergenProfileScreen> {
  bool _isEditing = false;
  Map<String, bool> _allergens = {
    'Peanuts': false,
    'Gluten': false,
    'Dairy': false,
    'Shellfish': false,
    'Eggs': false,
    'Soy': false,
    'Tree Nuts': false,
    'Wheat': false,
    'Fish': false,
    'Sesame': false,
    'Mustard': false,
    'Lupin': false,
    'Celery': false,
    'Mollusks': false,
    'Sulfites': false,
  };
  List<Scan> _recentScans = [];

  // Allergen information (description, symptoms)
  final Map<String, Map<String, String>> _allergenInfo = {
    'Peanuts': {
      'description': 'Proteins found in peanuts and peanut-derived products.',
      'symptoms': 'Hives, swelling, difficulty breathing, anaphylaxis.'
    },
    'Gluten': {
      'description': 'Proteins in wheat, barley, rye, and some oats.',
      'symptoms': 'Bloating, diarrhea, fatigue, skin rash.'
    },
    'Dairy': {
      'description': 'Milk and milk-derived products like cheese and yogurt.',
      'symptoms': 'Nausea, bloating, diarrhea, skin rash.'
    },
    'Shellfish': {
      'description':
          'Crustaceans (shrimp, crab) and mollusks (clams, oysters).',
      'symptoms': 'Itching, swelling, respiratory distress, anaphylaxis.'
    },
    'Eggs': {
      'description': 'Proteins in egg whites or yolks.',
      'symptoms': 'Hives, nasal congestion, digestive issues.'
    },
    'Soy': {
      'description': 'Proteins in soybeans and soy products.',
      'symptoms': 'Itching, hives, swelling, breathing difficulty.'
    },
    'Tree Nuts': {
      'description': 'Nuts like almonds, walnuts, cashews, and hazelnuts.',
      'symptoms': 'Hives, swelling, anaphylaxis.'
    },
    'Wheat': {
      'description': 'Proteins in wheat grains, distinct from gluten.',
      'symptoms': 'Rash, digestive issues, respiratory problems.'
    },
    'Fish': {
      'description': 'Proteins in finned fish like salmon, tuna, cod.',
      'symptoms': 'Hives, swelling, nausea, anaphylaxis.'
    },
    'Sesame': {
      'description': 'Seeds used in oils, tahini, and baked goods.',
      'symptoms': 'Hives, swelling, breathing difficulty.'
    },
    'Mustard': {
      'description': 'Seeds used in condiments and spices.',
      'symptoms': 'Rash, swelling, anaphylaxis.'
    },
    'Lupin': {
      'description': 'Legume used in flour and snacks.',
      'symptoms': 'Hives, digestive issues, respiratory distress.'
    },
    'Celery': {
      'description': 'Vegetable used in soups, salads, and spices.',
      'symptoms': 'Itching, swelling, anaphylaxis.'
    },
    'Mollusks': {
      'description': 'Seafood like clams, mussels, oysters, squid.',
      'symptoms': 'Hives, swelling, respiratory issues.'
    },
    'Sulfites': {
      'description':
          'Preservatives in wine, dried fruits, and processed foods.',
      'symptoms': 'Asthma, hives, digestive issues.'
    },
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');
    final scansJson = prefs.getString('recentScans');

    if (email != null) {
      try {
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user != null) {
          final allergensMap =
              jsonDecode(user['allergens'] ?? '{}') as Map<String, dynamic>;
          setState(() {
            for (var allergen in _allergens.keys) {
              _allergens[allergen] = allergensMap[allergen] ?? false;
            }
            if (scansJson != null) {
              final List<dynamic> scansList = jsonDecode(scansJson);
              _recentScans =
                  scansList.map((json) => Scan.fromJson(json)).toList();
            }
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
          SnackBar(content: Text('Error loading allergen profile: $e')),
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

  Future<void> _saveAllergens() async {
    if (_allergens.values.every((value) => !value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one allergen')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');

    if (email != null) {
      try {
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (user != null) {
          final data = {
            'email': email,
            'firstName': user['firstName'],
            'lastName': user['lastName'],
            'password': user['password'],
            'dateOfBirth': user['dateOfBirth'],
            'height': user['height'],
            'weight': user['weight'],
            'visualImpairment': user['visualImpairment'],
            'allergens': jsonEncode(_allergens),
            'otherAllergens': user['otherAllergens'],
          };

          await DatabaseHelper.instance.insertSignUpData(data);

          setState(() {
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Allergen profile updated')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving allergens: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found')),
      );
      Navigator.pushReplacementNamed(context, '/login');
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

    final selectedAllergens = _allergens.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: const Text(
            'Allergen Profile',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            semanticsLabel: 'Allergen Profile Title',
          ),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              color: colorScheme.onPrimary,
              onPressed: () {
                if (_isEditing) {
                  _saveAllergens();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              tooltip: _isEditing ? 'Save' : 'Edit',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Your Allergens' : 'Your Allergen Profile',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              if (_isEditing) ...[
                // Edit Mode: Checkbox list for all allergens
                Text(
                  'Select Allergens',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allergens.entries.map((entry) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 40) / 2,
                      child: CheckboxListTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                              fontFamily: 'GlacialIndifference'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: entry.value,
                        onChanged: (bool? value) {
                          setState(() {
                            _allergens[entry.key] = value ?? false;
                          });
                        },
                        activeColor: colorScheme.primary,
                        checkColor: colorScheme.onPrimary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                      _loadUserData(); // Reset to saved data
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.error),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      semanticsLabel: 'Cancel Button',
                    ),
                  ),
                ),
              ] else ...[
                // View Mode: Display selected allergens with details
                if (selectedAllergens.isEmpty)
                  Text(
                    'No allergens selected.',
                    style: TextStyle(
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedAllergens.map((allergen) {
                      final info = _allergenInfo[allergen] ??
                          {
                            'description': 'No description available.',
                            'symptoms': 'No symptoms information.'
                          };
                      // Find products containing this allergen
                      final products = _recentScans
                          .where(
                              (scan) => scan.allergensFound.contains(allergen))
                          .map((scan) =>
                              '${scan.productName} (Scanned: ${DateFormat('MMM d, yyyy').format(scan.scanDate)})')
                          .toList();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allergen,
                                style: TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${info['description']}',
                                style: const TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Symptoms: ${info['symptoms']}',
                                style: const TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Found in Recent Scans:',
                                style: TextStyle(
                                  fontFamily: 'GlacialIndifference',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              products.isEmpty
                                  ? Text(
                                      'No products found.',
                                      style: TextStyle(
                                        fontFamily: 'GlacialIndifference',
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    )
                                  : Column(
                                      children: products
                                          .map((product) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2.0),
                                                child: Text(
                                                  '• $product',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'GlacialIndifference',
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
