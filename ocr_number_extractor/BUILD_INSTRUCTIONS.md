# Build Instructions for OCR Number Extractor Android App

## Prerequisites

1. **Install Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your system PATH

2. **Install Android Studio**
   - Download from: https://developer.android.com/studio
   - Install Android SDK through Android Studio
   - Set up Android emulator or connect physical device

3. **Enable Developer Options** on your Android device (if using physical device)
   - Go to Settings > About Phone > Tap Build Number 7 times
   - Enable USB Debugging in Developer Options

## Build Steps

1. **Clone/Download the project**
   ```bash
   # If you have the project folder
   cd ocr_number_extractor
   ```

2. **Get Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Check Flutter setup**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by flutter doctor.

4. **Build the APK**
   ```bash
   # For release APK
   flutter build apk --release
   
   # For debug APK (larger file, with debugging symbols)
   flutter build apk --debug
   ```

5. **Install on device**
   ```bash
   # Install directly to connected device
   flutter install
   
   # Or manually install the APK file
   # The APK will be at: build/app/outputs/flutter-apk/app-release.apk
   ```

## Alternative: Build AAB for Play Store

If you want to publish to Google Play Store:
```bash
flutter build appbundle --release
```

## Troubleshooting

### Common Issues:

1. **"Android license not accepted"**
   ```bash
   flutter doctor --android-licenses
   ```

2. **"No connected devices"**
   - Enable USB debugging on your phone
   - Or start an Android emulator

3. **"Build failed"**
   - Run `flutter clean` then `flutter pub get`
   - Check that all dependencies are compatible

4. **Permission issues on app**
   - Grant storage permissions when prompted
   - For Android 11+, may need to enable "All files access" in app settings

## Testing the App

1. Install the APK on your Android device
2. Create a ZIP file containing some test images
3. Open the app and select the ZIP file
4. The app will extract numbers with 5+ digits from all images
5. Save the results to view extracted numbers

## Project Structure

- `lib/main.dart` - Main application code
- `android/` - Android-specific configuration
- `pubspec.yaml` - Dependencies and project configuration
- `README.md` - App documentation