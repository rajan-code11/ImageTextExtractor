# OCR Number Extractor - Android App

A Flutter-based Android application that extracts numbers (5+ digits) from images in ZIP folders using offline OCR.

## Features

- **Offline OCR**: Uses Google ML Kit for text recognition (works without internet)
- **ZIP Folder Processing**: Upload ZIP files containing multiple images
- **Number Extraction**: Automatically finds and extracts numbers with 5+ digits
- **Batch Processing**: Processes all images in a ZIP folder at once
- **Results Export**: Saves results in the format: "imagename1 extracted_text     imagename2 extracted_text"

## How to Use

1. **Install the APK** on your Android device
2. **Grant Permissions** for file access when prompted
3. **Select ZIP Folder** containing your images
4. **Process Images** - the app will extract numbers from all images
5. **Save Results** - export the extracted numbers to a text file

## Supported Image Formats

- JPG/JPEG
- PNG
- BMP
- TIFF
- WebP

## Building from Source

### Prerequisites
- Flutter SDK
- Android SDK
- Android Studio or VS Code with Flutter extension

### Build Steps
```bash
# Get dependencies
flutter pub get

# Build APK
flutter build apk --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

## Permissions Required

- **Storage Access**: To read ZIP files and save results
- **File Management**: To extract images from ZIP files

## Technical Details

- **Framework**: Flutter
- **OCR Engine**: Google ML Kit Text Recognition
- **Minimum Android Version**: API Level 21 (Android 5.0)
- **File Processing**: Archive library for ZIP extraction
- **Offline Capability**: All processing happens on-device

## Output Format

Results are saved in the specified format:
```
imagename1.jpg extracted_numbers     imagename2.png extracted_numbers
```

Only numbers with more than 5 digits are extracted and included in the results.