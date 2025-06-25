# OCR Number Extractor

## Overview

Flutter Android application that extracts numbers (5+ digits) from images in ZIP folders using offline OCR. Built with Google ML Kit for text recognition without requiring internet connectivity. Designed for batch processing with smart cropping functionality.

## System Architecture

**Mobile App Framework**: Flutter provides cross-platform development with native Android performance and UI components.

**Offline OCR Engine**: Google ML Kit Text Recognition processes images locally without internet dependency.

**File Processing**: Archive library handles ZIP folder extraction and image file management with proper Android permissions.

## Key Components

### Core Application (`ocr_number_extractor/lib/main.dart`)
- **ZIP File Handler**: Extracts and processes images from ZIP archives
- **OCR Engine**: Google ML Kit processes images for text recognition
- **Crop Functionality**: Define crop area on first image, apply to all images
- **Number Extraction**: Filters extracted text to only numbers with 5+ digits
- **Batch Processing**: Progress tracking for multiple image processing
- **Result Export**: Formats output as "imagename1 numbers imagename2 numbers"

### Supported Features
- Offline processing (no internet required)
- ZIP folder batch processing
- Smart cropping (crop once, apply to all)
- Number filtering (5+ digits only)
- Progress tracking with visual feedback
- File permission handling

### Android Configuration
- **Storage Permissions**: Access to device storage for file selection
- **File Picker Integration**: Native Android file selection interface
- **ML Kit Integration**: Offline text recognition capabilities
- **Target SDK**: Android 12+ compatibility

## Data Flow

1. **ZIP Selection**: User selects ZIP folder containing images
2. **Archive Extraction**: ZIP contents extracted to temporary storage
3. **Image Validation**: Filter for supported image formats
4. **Crop Definition**: User defines crop area on first image
5. **Batch Processing**: Same crop area applied to all images
6. **OCR Processing**: Google ML Kit extracts text from cropped regions
7. **Number Filtering**: Extract only numbers with 5+ digits
8. **Result Formatting**: Export as "imagename1 numbers imagename2 numbers"

## External Dependencies

### Flutter Dependencies
- **Flutter SDK (≥3.22.0)**: Mobile app development framework
- **google_mlkit_text_recognition (^0.10.0)**: Offline OCR processing
- **file_picker (^6.1.1)**: Native file selection interface
- **archive (^3.4.9)**: ZIP file extraction and processing
- **path_provider (^2.1.1)**: File system path management
- **permission_handler (^11.0.1)**: Android permissions management

### Build Dependencies
- **Java 17**: Android compilation requirements
- **Android SDK**: Native Android development tools
- **Flutter Build Tools**: APK generation and optimization

## Deployment Strategy

**Platform**: GitHub Actions automated building
**Build Environment**: Ubuntu with Flutter SDK and Android tools
**APK Generation**: Release mode compilation with optimization
**Distribution**: GitHub Artifacts and Releases for download
**Installation**: Direct APK installation on Android devices

The deployment uses GitHub Actions workflow for automated APK building, eliminating need for local development environment setup.

## User Preferences

Preferred communication style: Simple, everyday language.
User is a beginner with app development - needs step-by-step guidance.
User is using Replit on mobile Android app - needs mobile-specific instructions.

## Recent Changes

- June 25, 2025: Fixed Flutter analysis errors - GitHub Actions build now progressing successfully
- June 24, 2025: Created complete Flutter Android application with offline OCR capabilities
- June 24, 2025: Implemented GitHub Actions workflow for automatic APK building
- June 24, 2025: Added comprehensive documentation and deployment guides
- June 24, 2025: Used Google ML Kit for offline text recognition (no internet required)
- June 24, 2025: Configured batch ZIP processing with number extraction (5+ digits only)

## Changelog

- June 24, 2025. Initial setup with basic OCR
- June 24, 2025. Upgraded to professional OCR with cropping and number extraction