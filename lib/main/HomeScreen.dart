import 'dart:async';
import 'dart:convert';
import 'package:allereye/main/AllergenProfiling.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login.dart';
import '../ocr/ocr.dart';
import 'ProfileScreen.dart';
import 'SettingsScreen.dart';
import 'AllergenProfiling.dart'; // Import new screen
import '../helpers/databaseHelper.dart';

class Scan {
  final String productName;
  final List<String> allergensFound;
  final DateTime scanDate;

  Scan({
    required this.productName,
    required this.allergensFound,
    required this.scanDate,
  });

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'allergensFound': allergensFound,
        'scanDate': scanDate.toIso8601String(),
      };

  factory Scan.fromJson(Map<String, dynamic> json) => Scan(
        productName: json['productName'],
        allergensFound: List<String>.from(json['allergensFound']),
        scanDate: DateTime.parse(json['scanDate']),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;
  List<String> _userAllergens = [];
  List<Scan> _recentScans = [];
  String _currentTip = '';
  int _currentTipIndex = 0;
  Timer? _tipTimer;
  final List<String> _tips = [
    'Did you know? Some cereals contain hidden soy.',
    'Check labels for cross-contamination warnings.',
    'Gluten can hide in sauces and dressings.',
    'Always verify "allergen-free" claims.',
  ];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startTipRotation();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
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
          final selectedAllergens = allergensMap.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();

          setState(() {
            _firstName = user['firstName'];
            _userAllergens =
                selectedAllergens.isNotEmpty ? selectedAllergens : ['None'];
            if (scansJson != null) {
              final List<dynamic> scansList = jsonDecode(scansJson);
              _recentScans =
                  scansList.map((json) => Scan.fromJson(json)).toList();
            }
            _currentTip = _tips[_currentTipIndex];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
          _logout();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    } else {
      _logout();
    }
  }

  void _startTipRotation() {
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
        _currentTip = _tips[_currentTipIndex];
      });
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _onScanPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OcrScreen()),
    );
  }

  void _onProfilePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _onSettingsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _onEditAllergensPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AllergenProfileScreen()),
    ).then((_) => _loadUserData()); // Refresh allergens after editing
  }

  void _onSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        _onScanPressed();
        break;
      case 2:
        _onProfilePressed();
        break;
      case 3:
        _onSettingsPressed();
        break;
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

    final bool hasRiskyScan = _recentScans.isNotEmpty &&
        _recentScans.first.allergensFound
            .any((allergen) => _userAllergens.contains(allergen));

    return Theme(
      data: Theme.of(context).copyWith(colorScheme: colorScheme),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          title: const Text(
            'AllerEye',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            semanticsLabel: 'Allergen Scanner Title',
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/img/logo.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                      semanticLabel: 'OCR App Logo',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _firstName != null ? 'Hello, $_firstName!' : 'AllerEye',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                      semanticsLabel: 'Drawer Header Title',
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: colorScheme.primary),
                title: Text(
                  'Home',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                selected: _selectedIndex == 0,
                selectedTileColor: colorScheme.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onNavBarTapped(0);
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: colorScheme.primary),
                title: Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                selected: _selectedIndex == 2,
                selectedTileColor: colorScheme.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onNavBarTapped(2);
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: colorScheme.primary),
                title: Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                selected: _selectedIndex == 3,
                selectedTileColor: colorScheme.primary.withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  _onNavBarTapped(3);
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.primary),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _firstName != null ? 'Welcome, $_firstName!' : 'Welcome!',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                    fontFamily: 'GlacialIndifference',
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.onSurface),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                ),
                style: const TextStyle(fontFamily: 'GlacialIndifference'),
                onSubmitted: _onSearch,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onScanPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Scan Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GlacialIndifference',
                    ),
                    semanticsLabel: 'Scan Product Button',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (hasRiskyScan)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⚠️ You scanned "${_recentScans.first.productName}" with ${_recentScans.first.allergensFound.join(", ")} on ${DateFormat('MMM d').format(_recentScans.first.scanDate)}.',
                          style: TextStyle(
                            fontFamily: 'GlacialIndifference',
                            color: colorScheme.error,
                          ),
                          semanticsLabel: 'Warning Banner',
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Allergen Profile',
                    style: TextStyle(
                      fontFamily: 'GlacialIndifference',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.primary),
                    onPressed: _onEditAllergensPressed,
                    tooltip: 'Edit Allergens',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userAllergens.map((allergen) {
                  final icon = {
                        'Peanuts': '🥜',
                        'Gluten': '🌾',
                        'Dairy': '🥛',
                        'Shellfish': '🦐',
                        'Eggs': '🥚',
                        'Soy': '🌱',
                        'Tree Nuts': '🌰',
                        'Wheat': '🌾',
                        'Fish': '🐟',
                        'Sesame': '🌱',
                        'Mustard': '🌿',
                        'Lupin': '🌸',
                        'Celery': '🥬',
                        'Mollusks': '🦑',
                        'Sulfites': '🍷',
                        'None': '✅',
                      }[allergen] ??
                      '⚠️';
                  return Chip(
                    label: Text(
                      '$icon $allergen',
                      style: const TextStyle(
                        fontFamily: 'GlacialIndifference',
                        fontSize: 14,
                      ),
                    ),
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    side: BorderSide(color: colorScheme.primary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Recent Scans',
                style: TextStyle(
                  fontFamily: 'GlacialIndifference',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _recentScans.isEmpty
                  ? Text(
                      'No recent scans.',
                      style: TextStyle(
                        fontFamily: 'GlacialIndifference',
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentScans.length,
                      itemBuilder: (context, index) {
                        final scan = _recentScans[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              scan.productName,
                              style: const TextStyle(
                                fontFamily: 'GlacialIndifference',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Allergens: ${scan.allergensFound.isEmpty ? "None" : scan.allergensFound.join(", ")}\nScanned: ${DateFormat('MMM d, yyyy').format(scan.scanDate)}',
                              style: const TextStyle(
                                fontFamily: 'GlacialIndifference',
                              ),
                            ),
                            trailing: scan.allergensFound
                                    .any((a) => _userAllergens.contains(a))
                                ? Icon(Icons.warning, color: colorScheme.error)
                                : Icon(Icons.check_circle,
                                    color: colorScheme.primary),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 20),
              Text(
                'Suggested Safe Food',
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
                children: [
                  Chip(
                    label: Text(
                      'Brand A Rice Cakes',
                      style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    ),
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                  Chip(
                    label: Text(
                      'Brand B Fruit Bars',
                      style: const TextStyle(fontFamily: 'GlacialIndifference'),
                    ),
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentTip,
                        style: TextStyle(
                          fontFamily: 'GlacialIndifference',
                          color: colorScheme.onSurface,
                        ),
                        semanticsLabel: 'Safety Tip',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle:
              const TextStyle(fontFamily: 'GlacialIndifference'),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'GlacialIndifference'),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              tooltip: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Scan',
              tooltip: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
              tooltip: 'Settings',
            ),
          ],
          onTap: _onNavBarTapped,
        ),
      ),
    );
  }
}
