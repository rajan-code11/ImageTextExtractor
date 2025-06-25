# OCR Number Extractor

## Overview

Clean Flutter Android application that extracts numbers (5+ digits) from images in ZIP folders using offline OCR. Built with Google ML Kit for text recognition without requiring internet connectivity. Simplified from scratch for reliable builds.

## System Architecture

**Mobile App Framework**: Flutter provides cross-platform development with native Android performance.

**Offline OCR Engine**: Google ML Kit Text Recognition processes images locally without internet dependency.

**File Processing**: Archive library handles ZIP folder extraction and image file management.

## Key Components

### Core Application (`ocr_extractor/lib/main.dart`)
- **ZIP File Handler**: Extracts and processes images from ZIP archives
- **OCR Engine**: Google ML Kit processes images for text recognition  
- **Number Extraction**: Filters extracted text to only numbers with 5+ digits
- **Result Export**: Formats output as "imagename1 numbers     imagename2 numbers"
- **Simple UI**: Clean interface without complex features

### Supported Features
- Offline processing (no internet required)
- ZIP folder batch processing
- Number filtering (5+ digits only)
- Progress tracking
- File permission handling
- Result saving

## External Dependencies

### Flutter Dependencies
- **Flutter SDK (≥3.22.0)**: Mobile app development framework
- **google_mlkit_text_recognition (^0.10.0)**: Offline OCR processing
- **file_picker (^6.1.1)**: Native file selection interface
- **archive (^3.4.9)**: ZIP file extraction and processing
- **path_provider (^2.1.1)**: File system path management
- **permission_handler (^11.0.1)**: Android permissions management

## Deployment Strategy

**Platform**: GitHub Actions automated building
**Build Environment**: Ubuntu with Flutter SDK and Android tools
**APK Generation**: Release mode compilation
**Distribution**: GitHub Artifacts for download

## User Preferences

Preferred communication style: Simple, everyday language.
User is a beginner with app development - needs step-by-step guidance.
User is using Replit on mobile Android app - needs mobile-specific instructions.

## Recent Changes

- June 25, 2025: Created clean Flutter app from scratch - removed all complex features
- June 25, 2025: Simplified code structure for reliable GitHub Actions builds
- June 25, 2025: Focused on core OCR functionality only