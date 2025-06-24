# OCR Number Extractor

A Flutter-based Android application that extracts numbers (5+ digits) from images in ZIP folders using offline OCR technology.

![Build Status](https://github.com/yourusername/ocr-number-extractor/workflows/Build%20Android%20APK/badge.svg)

## Features

- 🔍 **Offline OCR**: Uses Google ML Kit for text recognition (no internet required)
- 📁 **ZIP Folder Processing**: Upload ZIP files containing multiple images
- 🔢 **Smart Number Extraction**: Automatically finds and extracts numbers with 5+ digits
- ⚡ **Batch Processing**: Processes all images in a ZIP folder at once
- 💾 **Results Export**: Saves results in the format: "imagename1 extracted_text     imagename2 extracted_text"
- 📱 **Native Android**: Optimized for mobile devices with touch-friendly interface

## Supported Formats

- **ZIP Files**: For batch processing
- **Images**: JPG, PNG, BMP, TIFF, WebP
- **Output**: Text file with extracted numbers

## Download APK

### Option 1: GitHub Releases
1. Go to [Releases](../../releases)
2. Download the latest APK file
3. Install on your Android device

### Option 2: GitHub Actions Artifacts
1. Go to [Actions](../../actions)
2. Click on the latest successful build
3. Download the "ocr-number-extractor-apk" artifact

## Installation

1. **Download APK** from releases or build artifacts
2. **Enable Unknown Sources** in Android settings if prompted
3. **Install APK** on your Android device
4. **Grant Permissions** for file access when prompted

## Usage

1. **Open the app** on your Android device
2. **Tap "Select ZIP Folder"** to choose a ZIP file containing images
3. **Confirm processing** when prompted
4. **Wait for processing** - progress will be shown
5. **View results** in the results dialog
6. **Save results** to export extracted numbers to a text file

## Output Format

Results are saved exactly as requested:
```
image1.jpg 123456789     image2.png 987654321012     image3.jpg 555666777888
```

Only numbers with more than 5 digits are extracted and included in the results.

## Technical Details

- **Framework**: Flutter
- **OCR Engine**: Google ML Kit Text Recognition
- **Minimum Android Version**: API Level 21 (Android 5.0)
- **File Processing**: Archive library for ZIP extraction
- **Offline Capability**: All processing happens on-device

## Building from Source

### Prerequisites
- Flutter SDK 3.22.0+
- Android SDK
- Java 17+

### Local Build
```bash
cd ocr_number_extractor
flutter pub get
flutter build apk --release
```

### GitHub Actions Build
This repository includes automated APK building via GitHub Actions. Simply push changes to trigger a new build.

## Permissions

The app requires the following permissions:
- **Storage Access**: To read ZIP files and save results
- **File Management**: To extract images from ZIP files

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is open source and available under the MIT License.

## Support

If you encounter any issues or have questions:
1. Check the [Issues](../../issues) section
2. Create a new issue with detailed description
3. Include your Android version and device model