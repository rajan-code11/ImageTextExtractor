# OCR Number Extractor

Clean Flutter Android app that extracts numbers (5+ digits) from images in ZIP folders using offline OCR.

## Features

- Offline OCR using Google ML Kit (no internet required)
- Process ZIP folders containing multiple images  
- Extract only numbers with more than 5 digits
- Save results in specified format: "image1.jpg numbers     image2.jpg numbers"
- Simple, clean interface

## Download APK

1. Go to [Actions](../../actions) tab
2. Click latest successful build
3. Download "ocr-extractor-apk" artifact
4. Extract and install APK on Android device

## Usage

1. Open app and grant storage permissions
2. Tap "Select ZIP File" 
3. Choose ZIP containing images
4. Wait for processing
5. View and save results

## Build from Source

```bash
cd ocr_extractor
flutter pub get
flutter build apk --release
```

APK will be in `build/app/outputs/flutter-apk/app-release.apk`