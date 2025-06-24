# OCR Text Extractor

## Overview

This is a Streamlit-based OCR (Optical Character Recognition) application that extracts text from uploaded image files. The application uses Python with Tesseract OCR engine to process various image formats and convert them to readable text. It's designed to handle single images or batch processing of multiple image files.

## System Architecture

The application follows a simple single-tier architecture:

**Frontend & Backend**: Streamlit framework serves as both the web interface and application logic layer, providing an integrated solution for file upload, image processing, and result display.

**OCR Processing**: Pytesseract library interfaces with the Tesseract OCR engine to extract text from images.

**Image Processing**: PIL (Python Imaging Library) handles image format conversion and preprocessing before OCR analysis.

## Key Components

### Core Application (`app.py`)
- **File Upload Handler**: Manages multiple image file uploads with format validation
- **OCR Engine**: Processes images using Tesseract with English language support
- **Text Processor**: Cleans and formats extracted text, removing excessive whitespace
- **Progress Tracking**: Provides real-time feedback during batch processing
- **Result Display**: Shows extracted text with download capabilities

### Image Format Support
- PNG, JPG, JPEG, BMP, TIFF, TIF, WEBP
- Automatic RGB conversion for compatibility
- Error handling for unsupported or corrupted files

### Configuration
- **Streamlit Config**: Custom server settings for deployment (port 5000, headless mode)
- **Page Configuration**: Wide layout with custom title and icon
- **Replit Integration**: Configured for autoscale deployment with proper workflow setup

## Data Flow

1. **File Upload**: Users upload single or multiple image files through Streamlit interface
2. **Format Validation**: System checks file extensions against supported formats
3. **Image Processing**: PIL opens and converts images to RGB format if needed
4. **OCR Extraction**: Pytesseract processes each image to extract text content
5. **Text Cleaning**: Extracted text is cleaned and formatted for readability
6. **Result Display**: Processed text is displayed with options for download
7. **Batch Processing**: Progress tracking for multiple file processing

## External Dependencies

### Core Libraries
- **Streamlit (≥1.46.0)**: Web application framework and UI
- **Pytesseract (≥0.3.13)**: Python wrapper for Tesseract OCR engine
- **Pillow (≥11.2.1)**: Image processing and format handling
- **Pathlib (≥1.0.1)**: File system path operations

### System Dependencies (Nix packages)
- **Tesseract**: OCR engine for text extraction
- **Image Libraries**: freetype, lcms2, libimagequant, libjpeg, libtiff, libwebp, openjpeg
- **System Libraries**: zlib, libxcrypt, tcl, tk

## Deployment Strategy

**Platform**: Replit with Nix environment management
**Runtime**: Python 3.11 with stable Nix channel (24_05)
**Scaling**: Autoscale deployment target for handling variable loads
**Port Configuration**: Application runs on port 5000 with external access
**Startup Command**: `streamlit run app.py --server.port 5000`

The deployment uses Replit's workflow system with parallel task execution, ensuring reliable startup and port binding for web access.

## User Preferences

Preferred communication style: Simple, everyday language.

## Recent Changes

- June 24, 2025: Created complete Flutter Android application with offline OCR capabilities
- June 24, 2025: Implemented GitHub Actions workflow for automatic APK building
- June 24, 2025: Added comprehensive documentation and deployment guides
- June 24, 2025: Used Google ML Kit for offline text recognition (no internet required)
- June 24, 2025: Configured batch ZIP processing with number extraction (5+ digits only)

## Changelog

- June 24, 2025. Initial setup with basic OCR
- June 24, 2025. Upgraded to professional OCR with cropping and number extraction