# GitHub Actions Setup for OCR Number Extractor APK

## Quick Setup Guide

### 1. Create GitHub Repository
```bash
# Create new repository on GitHub.com
# Name: ocr-number-extractor (or any name you prefer)
```

### 2. Upload Project Files
Upload these files to your GitHub repository:

**Root directory:**
- `.github/workflows/build-apk.yml` (GitHub Actions workflow)
- `GITHUB_SETUP.md` (this file)
- `ANDROID_APP_SUMMARY.md`
- `README.md`

**Flutter project directory:**
- `ocr_number_extractor/` (entire folder with all contents)

### 3. File Structure Should Look Like:
```
your-repo/
├── .github/
│   └── workflows/
│       └── build-apk.yml
├── ocr_number_extractor/
│   ├── lib/
│   │   └── main.dart
│   ├── android/
│   ├── pubspec.yaml
│   └── ... (all Flutter files)
├── GITHUB_SETUP.md
├── ANDROID_APP_SUMMARY.md
└── README.md
```

### 4. Trigger Build
Once uploaded, the GitHub Action will automatically:
- **Trigger on**: Push to main/master branch, pull requests, or manual trigger
- **Build process**: Setup Flutter, get dependencies, build APK
- **Output**: APK file available as downloadable artifact

### 5. Download Your APK

**Option A: From Actions Tab**
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Click on the latest successful build
4. Scroll down to "Artifacts" section
5. Download "ocr-number-extractor-apk"

**Option B: From Releases**
1. Go to your repository on GitHub
2. Click "Releases" on the right sidebar
3. Download the APK from the latest release

## Manual Trigger
You can manually trigger a build:
1. Go to "Actions" tab
2. Click "Build Android APK" workflow
3. Click "Run workflow" button
4. Select branch and click "Run workflow"

## Troubleshooting

### If Build Fails:
1. Check the Actions log for error details
2. Most common issues:
   - **Dependency conflicts**: Update pubspec.yaml versions
   - **Flutter version**: Workflow uses Flutter 3.22.0
   - **Java issues**: Workflow uses Java 17

### If You Need to Modify:
- Edit files in `ocr_number_extractor/`
- Push changes to trigger automatic rebuild
- APK will be generated with your changes

## Security Notes
- This workflow only builds APK, no secrets required
- APK is uploaded as public artifact (downloadable by anyone with repo access)
- For private repos, artifacts are only accessible to repo members

## Customization
You can modify `.github/workflows/build-apk.yml` to:
- Change Flutter version
- Add code signing (requires secrets setup)
- Modify build triggers
- Change artifact retention period

The workflow will automatically build your APK whenever you push changes to the Flutter project!