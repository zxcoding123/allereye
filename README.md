# AllerEye

AllerEye is a Flutter mobile app that helps people with food allergies check product labels. You take a photo of an ingredient list (or pick one from the gallery). The app reads the text on the device and warns you if it finds any of the allergens in your profile. It is built with accessibility in mind for users with visual impairments: it can read results aloud, and it has adjustable font sizes and a high-contrast mode.

## Features

- **Label scanning (OCR):** Capture or pick an image and extract its text with Google ML Kit Text Recognition. All processing happens on the device.
- **Allergen detection:** Matches the recognized text against the user's allergens, including common synonyms (for example, *Dairy* matches milk, cheese, yogurt and lactose; *Gluten* matches wheat, barley and rye).
- **Text-to-speech results:** Speaks a "Safe" or "Warning" message after each scan. This can be turned off in Settings.
- **Allergen profile:** Choose from 15 allergens (Peanuts, Gluten, Dairy, Shellfish, Eggs, Soy, Tree Nuts, Wheat, Fish, Sesame, Mustard, Lupin, Celery, Mollusks, Sulfites). Each one comes with a description, typical symptoms and the recently scanned products that contained it.
- **User accounts:** Local sign-up and login with "Remember Me". The profile stores date of birth, height and weight (with a BMI calculation), visual impairment level and other allergens.
- **Scan history:** Scans are saved per user, and the 10 most recent ones are shown on the home screen.
- **Accessibility settings:** Font size, high-contrast mode and semantic labels for screen readers.

## Tech Stack

| Area              | Package                                   |
| ----------------- | ----------------------------------------- |
| Text recognition  | `google_mlkit_text_recognition`           |
| Image capture     | `image_picker`, `camera`                  |
| Text-to-speech    | `flutter_tts`                             |
| Local database    | `sqflite`                                 |
| Preferences       | `shared_preferences`                      |
| Permissions       | `permission_handler`                      |
| State / utilities | `flutter_bloc`, `dartz`, `intl`           |

## Project Structure

```
lib/
├── main.dart                   # App entry point and theme
├── auth/
│   ├── login.dart              # Login screen
│   └── signup.dart             # Registration and initial allergen selection
├── main/
│   ├── HomeScreen.dart         # Home, recent scans, Scan model
│   ├── AllergenProfiling.dart  # Allergen profile with info and matched products
│   ├── ProfileScreen.dart      # User profile (personal info, BMI, allergens)
│   ├── SettingsScreen.dart     # TTS, font size, high-contrast mode
│   └── ProductViews.dart
├── ocr/
│   └── ocr.dart                # Image capture, OCR and allergen matching
├── helpers/
│   └── databaseHelper.dart     # SQLite setup (signup and scans tables)
└── assets/
    ├── img/logo.png
    └── fonts/                  # Glacial Indifference
```

## Getting Started

### Prerequisites

- Flutter SDK (Dart `>=2.18.2 <3.0.0`, as set in `pubspec.yaml`)
- Android Studio or Xcode, with an emulator or a physical device
- A physical device is recommended for testing the camera

### Installation

```bash
git clone <repository-url>
cd allereye
flutter pub get
flutter run
```

### Permissions

The app needs access to the camera and the photo library. Make sure these are declared:

- **Android:** `android/app/src/main/AndroidManifest.xml` (`CAMERA`)
- **iOS:** `ios/Runner/Info.plist` (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)

## Usage

1. **Sign up** and select the allergens you need to avoid.
2. On the home screen, open **Scan Product**.
3. Tap **Camera** to photograph an ingredient label, or **Gallery** to pick an existing photo. Make sure the label is well lit and in focus.
4. Read (or listen to) the result: **Safe** if none of your allergens were found, or **Warning** with the allergens that were detected.
5. Review past scans on the home screen and in your **Allergen Profile**.

## Data Storage

All data stays on the device:

- **SQLite (`signup.db`):** `signup` table (user accounts and profiles) and `scans` table (scan history per user)
- **SharedPreferences:** logged-in session, recent scans cache and accessibility settings

## Running Tests

```bash
flutter test
```

## Disclaimer

AllerEye is an assistive tool and is not a medical device. OCR can misread labels, and the synonym list is not exhaustive. Always check the product packaging yourself and talk to a healthcare professional about managing your allergies.
