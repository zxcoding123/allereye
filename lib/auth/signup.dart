import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../helpers/databaseHelper.dart';
import '../auth/login.dart'; // Adjust the import based on your project structure

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _otherAllergensController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _visualImpairment;
  String? _bmi; // Store BMI as string for display

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

  final List<String> _impairmentLevels = [
    'None',
    'Mild',
    'Moderate',
    'Severe',
    'Blind'
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to height and weight fields to update BMI dynamically
    _heightController.addListener(_updateBMI);
    _weightController.addListener(_updateBMI);
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateBMI);
    _weightController.removeListener(_updateBMI);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherAllergensController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Update BMI when height or weight changes
  void _updateBMI() {
    setState(() {
      final heightText = _heightController.text;
      final weightText = _weightController.text;

      // Validate height and weight
      final height = double.tryParse(heightText);
      final weight = double.tryParse(weightText);

      if (height != null &&
          weight != null &&
          height >= 100 &&
          height <= 250 &&
          weight >= 30 &&
          weight <= 300) {
        final heightInMeters = height / 100; // Convert cm to m
        final bmi = weight / (heightInMeters * heightInMeters);
        _bmi = bmi.toStringAsFixed(1); // Format to 1 decimal place
      } else {
        _bmi = null; // Clear BMI if inputs are invalid
      }
    });
  }

  void _onSignUpPressed() async {
    if (_formKey.currentState!.validate()) {
      // Check allergen selection
      bool hasAllergen = _allergens.values.any((selected) => selected) ||
          _otherAllergensController.text.isNotEmpty;
      if (!hasAllergen) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please select at least one allergen or specify other')),
        );
        return;
      }

      // Prepare data for storage
      final data = {
        'email': _emailController.text,
        'password': _passwordController.text, // Consider hashing passwords
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'allergens': jsonEncode(_allergens),
        'otherAllergens': _otherAllergensController.text,
        'height': double.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'visualImpairment': _visualImpairment,
      };

      // Save to database
      try {
        await DatabaseHelper.instance.insertSignUpData(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-up saved offline succesfully!'),
          ),
        );

        // Redirect to LoginScreen and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _goBack(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Centered Image (Logo)
                  Image.asset(
                    'lib/assets/img/logo.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    semanticLabel: 'OCR App Logo',
                  ),
                  TextButton.icon(
                    onPressed: () => _goBack(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Go Back',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        color: colorScheme.primary,
                        fontSize: 16,
                      ),
                      semanticsLabel: 'Go Back Link',
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: 'Create Account Title',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please supply every needed information in here!',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Account Details
                  Text(
                    'Account Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
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
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  // Personal Details
                  Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: "First Name",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'First Name',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: "Last Name",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Last Name',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  // Date of Birth
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Date of Birth",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: _dateOfBirth == null
                          ? 'Date of Birth'
                          : DateFormat('yyyy-MM-dd').format(_dateOfBirth!),
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (_dateOfBirth == null) {
                        return 'Please select your date of birth';
                      }
                      if (_dateOfBirth!.isAfter(DateTime.now()
                          .subtract(const Duration(days: 365 * 18)))) {
                        return 'You must be at least 18 years old';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  // Health Information
                  Text(
                    'Health Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Height (for BMI)
                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(
                      labelText: "Height (cm)",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Height (cm)',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
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
                  ),
                  const SizedBox(height: 16),
                  // Weight (for BMI)
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: "Weight (kg)",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Weight (kg)',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
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
                  ),
                  const SizedBox(height: 16),
                  // BMI Display
                  Text(
                    'BMI: ${_bmi ?? 'Enter height and weight to calculate'}',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Visual Impairment
                  DropdownButtonFormField<String>(
                    value: _visualImpairment,
                    decoration: InputDecoration(
                      labelText: "Visual Impairments",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Visual Impairment',
                      hintStyle: TextStyle(
                        color: Colors.black,
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                        fontFamily: 'GlacialIndifference', color: Colors.black),
                    items: _impairmentLevels
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level,
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
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  // Allergen Checkboxes
                  Text(
                    'Allergens',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'GlacialIndifference',
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allergens.keys.map((allergen) {
                      return SizedBox(
                        width: (MediaQuery.of(context).size.width - 56) / 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                allergen,
                                style: const TextStyle(
                                    fontFamily: 'GlacialIndifference'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Checkbox(
                              value: _allergens[allergen],
                              onChanged: (bool? value) {
                                setState(() {
                                  _allergens[allergen] = value ?? false;
                                });
                              },
                              activeColor: colorScheme.primary,
                              checkColor: colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Other Allergens
                  TextFormField(
                    controller: _otherAllergensController,
                    decoration: InputDecoration(
                      labelText: "Other Allergens",
                      labelStyle: TextStyle(color: Colors.black),
                      hintText: 'Other Allergens (if any)',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontFamily: 'GlacialIndifference',
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.onSurface),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: colorScheme.error, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorScheme.primary),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'GlacialIndifference',
                      ),
                      semanticsLabel: 'Create Account Button',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
