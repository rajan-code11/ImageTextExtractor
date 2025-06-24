# Complete Deployment Guide - OCR Number Extractor

## Step-by-Step GitHub Setup

### 1. Create GitHub Account & Repository
1. Go to [GitHub.com](https://github.com) and create account (if needed)
2. Click "New repository" (green button)
3. Repository name: `ocr-number-extractor` 
4. Make it Public (for free GitHub Actions)
5. Initialize with README: ✅ Check this box
6. Click "Create repository"

### 2. Upload Project Files

**Method A: Web Interface (Easiest)**
1. In your new repository, click "uploading an existing file"
2. Upload these files/folders:

**Root Level Files:**
- `.github/workflows/build-apk.yml`
- `GITHUB_SETUP.md`
- `ANDROID_APP_SUMMARY.md`
- `DEPLOYMENT_GUIDE.md`
- `README.md`

**Flutter Project Folder:**
- Upload the entire `ocr_number_extractor/` folder with all its contents

**Method B: Git Commands (if you use Git)**
```bash
git clone https://github.com/yourusername/ocr-number-extractor.git
cd ocr-number-extractor
# Copy all files from this project
git add .
git commit -m "Add OCR Number Extractor app"
git push origin main
```

### 3. File Structure Verification
Your repository should look like this:
```
ocr-number-extractor/
├── .github/
│   └── workflows/
│       └── build-apk.yml          ← GitHub Actions workflow
├── ocr_number_extractor/           ← Flutter app folder
│   ├── lib/
│   │   └── main.dart              ← Main app code (341 lines)
│   ├── android/
│   │   └── app/src/main/AndroidManifest.xml
│   ├── pubspec.yaml               ← Dependencies
│   └── ... (all other Flutter files)
├── GITHUB_SETUP.md
├── ANDROID_APP_SUMMARY.md
├── DEPLOYMENT_GUIDE.md
└── README.md
```

### 4. Automatic Build Trigger
Once files are uploaded:
1. GitHub Actions will automatically detect the workflow
2. Build will start automatically (takes 5-10 minutes)
3. You can watch progress in "Actions" tab

### 5. Download Your APK

**Wait for Build to Complete:**
- Green checkmark ✅ = Success
- Red X ❌ = Failed (check logs)

**Download Options:**

**Option A: From Artifacts**
1. Click "Actions" tab in your repository
2. Click on the completed build (green checkmark)
3. Scroll down to "Artifacts" section
4. Click "ocr-number-extractor-apk" to download ZIP
5. Extract ZIP to get your APK file

**Option B: From Releases (Automatic)**
1. Click "Releases" on right side of repository
2. Download APK from latest release
3. File will be named something like `app-release.apk`

### 6. Install APK on Android

1. **Transfer APK** to your Android device
2. **Enable Unknown Sources**:
   - Settings → Security → Unknown Sources → Enable
   - Or Settings → Apps → Special Access → Install Unknown Apps
3. **Install APK** by tapping the file
4. **Grant Permissions** for storage access

## Manual Build Trigger

You can trigger builds manually:
1. Go to "Actions" tab
2. Click "Build Android APK" 
3. Click "Run workflow"
4. Select "main" branch
5. Click green "Run workflow" button

## Troubleshooting

### Build Failures
Common issues and solutions:

**1. "No pubspec.yaml found"**
- Ensure `ocr_number_extractor/pubspec.yaml` exists
- Check folder structure matches guide above

**2. "Flutter dependencies failed"**
- Dependencies are automatically resolved
- Usually temporary - try re-running workflow

**3. "Build failed with exit code 1"**
- Check build logs in Actions tab
- Usually dependency version conflicts

### APK Installation Issues

**1. "App not installed"**
- Enable "Install from unknown sources"
- Check available storage space

**2. "Parse error"**
- APK file may be corrupted during download
- Re-download from GitHub

**3. Permissions not working**
- Go to App Settings → Permissions
- Enable Storage permissions manually

## Updating the App

To make changes and rebuild:
1. Edit files in your repository (click pencil icon on GitHub)
2. Commit changes (green "Commit changes" button)
3. New build will trigger automatically
4. Download updated APK from new build

## Cost & Limits

- **GitHub Actions**: 2,000 free minutes/month for public repos
- **Each build**: Takes ~8-12 minutes
- **Storage**: 500MB free for artifacts
- **Releases**: Unlimited for public repos

## Next Steps After APK

1. **Test thoroughly** on your Android device
2. **Share with others** by sending the APK file
3. **Update as needed** by modifying code and rebuilding
4. **Consider Play Store** publishing for wider distribution

Your APK will be a fully functional offline OCR number extractor that works exactly like the web version!