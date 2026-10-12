import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../auth/login.dart';
import '../helpers/databaseHelper.dart'; // Import DatabaseHelper

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  // Controllers for editable fields
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _otherAllergensController = TextEditingController();
  String _Password = "";

  // Other fields
  DateTime? _dateOfBirth;
  String? _visualImpairment;
  final Map<String, bool> _allergens = {
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
  double? _bmi;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Add listeners for dynamic BMI calculation
    _heightController.addListener(_updateBMI);
    _weightController.addListener(_updateBMI);
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateBMI);
    _weightController.removeListener(_updateBMI);
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _otherAllergensController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');

    if (email != null) {
      try {
        final user = await DatabaseHelper.instance.getUserByEmail(email);
        if (!mounted) return;
        if (user != null) {
          final allergensMap =
              jsonDecode(user['allergens'] ?? '{}') as Map<String, dynamic>;

          setState(() {
            _emailController.text = user['email'] ?? '';
            _firstNameController.text = user['firstName'] ?? '';
            _lastNameController.text = user['lastName'] ?? '';
            _Password = user['password']; // keep this to satisfy NOT NULL
            final dobString = user['dateOfBirth'];
            if (dobString != null) {
              _dateOfBirth = DateTime.parse(dobString);
            }
            _heightController.text =
                user['height'] != null ? user['height'].toStringAsFixed(0) : '';
            _weightController.text =
                user['weight'] != null ? user['weight'].toStringAsFixed(1) : '';
            _visualImpairment = user['visualImpairment'];
            for (var allergen in _allergens.keys) {
              _allergens[allergen] = allergensMap[allergen] ?? false;
            }
            _otherAllergensController.text = user['otherAllergens'] ?? '';
            _updateBMI(); // Calculate initial BMI
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
          SnackBar(content: Text('Error loading profile: $e')),
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

  void _updateBMI() {
    final heightText = _heightController.text;
    final weightText = _weightController.text;

    final height = double.tryParse(heightText);
    final weight = double.tryParse(weightText);

    if (height != null &&
        weight != null &&
        height >= 100 &&
        height <= 250 &&
        weight >= 30 &&
        weight <= 300) {
      final heightInMeters = height / 100; // Convert cm to m
      setState(() {
        _bmi = weight / (heightInMeters * heightInMeters);
      });
    } else {
      setState(() {
        _bmi = null;
      });
    }
  }

  Future<void> updateSignUpData() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('loggedInEmail');

    if (email != null) {
      try {
        final data = {
          'email': _emailController.text.trim(),
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'password': _Password,
          'height': double.tryParse(_heightController.text) ?? 0.0,
          'weight': double.tryParse(_weightController.text) ?? 0.0,
          'visualImpairment': _visualImpairment,
          'allergens': jsonEncode(_allergens),
          'otherAllergens': _otherAllergensController.text,
          // Password is not updated here; handle separately if needed
        };

        await DatabaseHelper.instance.updateSignUpData(data);
        if (!mounted) return;

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
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
            'Profile',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            semanticsLabel: 'Profile Title',
          ),
          actions: [
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              color: colorScheme.onPrimary,
              onPressed: () {
                if (_isEditing) {
                  updateSignUpData();
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                _isEditing
                    ? TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      )
                    : _buildReadOnlyField('Email', _emailController.text),
                const SizedBox(height: 16),
                // First Name
                _isEditing
                    ? TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration('First Name'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      )
                    : _buildReadOnlyField(
                        'First Name', _firstNameController.text),
                const SizedBox(height: 16),
                // Last Name
                _isEditing
                    ? TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration('Last Name'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      )
                    : _buildReadOnlyField(
                        'Last Name', _lastNameController.text),
                const SizedBox(height: 16),
                // Date of Birth
                _isEditing
                    ? InputDecorator(
                        decoration: _inputDecoration('Date of Birth'),
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Text(
                            _dateOfBirth != null
                                ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                                : 'Select Date',
                            style: TextStyle(
                              fontFamily: 'GlacialIndifference',
                              color: _dateOfBirth != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      )
                    : _buildReadOnlyField(
                        'Date of Birth',
                        _dateOfBirth != null
                            ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                            : 'Not specified'),
                const SizedBox(height: 16),
                // Height
                _isEditing
                    ? TextFormField(
                        controller: _heightController,
                        decoration: _inputDecoration('Height (cm)'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Enter a valid height';
                          }
                          if (height < 100 || height > 250) {
                            return 'Height must be between 100 and 250 cm';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      )
                    : _buildReadOnlyField(
                        'Height', '${_heightController.text} cm'),
                const SizedBox(height: 16),
                // Weight
                _isEditing
                    ? TextFormField(
                        controller: _weightController,
                        decoration: _inputDecoration('Weight (kg)'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Enter a valid weight';
                          }
                          if (weight < 30 || weight > 300) {
                            return 'Weight must be between 30 and 300 kg';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      )
                    : _buildReadOnlyField(
                        'Weight', '${_weightController.text} kg'),
                const SizedBox(height: 16),
                // BMI
                _buildReadOnlyField('BMI',
                    _bmi != null ? _bmi!.toStringAsFixed(1) : 'Not calculated'),
                const SizedBox(height: 16),
                // Visual Impairment
                _isEditing
                    ? DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Visual Impairment'),
                        value: _visualImpairment,
                        items: ['None', 'Mild', 'Moderate', 'Severe', 'Blind']
                            .map((impairment) => DropdownMenuItem(
                                  value:
                                      impairment == 'None' ? null : impairment,
                                  child: Text(
                                    impairment,
                                    style: const TextStyle(
                                        fontFamily: 'GlacialIndifference'),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _visualImpairment = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your visual impairment level';
                          }
                          return null;
                        },
                      )
                    : _buildReadOnlyField(
                        'Visual Impairment', _visualImpairment ?? 'None'),
                const SizedBox(height: 16),
                // Allergens
                Text(
                  'Allergens',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  semanticsLabel: 'Allergens Title',
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
                        onChanged: _isEditing
                            ? (bool? value) {
                                setState(() {
                                  _allergens[entry.key] = value ?? false;
                                });
                              }
                            : null,
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
                const SizedBox(height: 8),
                // Other Allergens
                _isEditing
                    ? TextFormField(
                        controller: _otherAllergensController,
                        decoration:
                            _inputDecoration('Other Allergens (Optional)'),
                        style:
                            const TextStyle(fontFamily: 'GlacialIndifference'),
                        textInputAction: TextInputAction.done,
                      )
                    : _buildReadOnlyField(
                        'Other Allergens',
                        _otherAllergensController.text.isEmpty
                            ? 'None'
                            : _otherAllergensController.text),
                const SizedBox(height: 20),
                // Cancel Button (Edit Mode)
                if (_isEditing)
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'GlacialIndifference'),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'GlacialIndifference',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: 'GlacialIndifference'),
          semanticsLabel: '$label: $value',
        ),
      ],
    );
  }
}
