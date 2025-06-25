# Shell Commands to Push OCR Project to GitHub

## Step 1: Create GitHub Repository First
1. Go to **github.com** on your phone browser
2. Click **"New repository"** 
3. Repository name: `ocr-number-extractor`
4. Make it **Public** (for free GitHub Actions)
5. **DO NOT** initialize with README (your project already has files)
6. Click **"Create repository"**
7. **Copy the repository URL** (like: https://github.com/yourusername/ocr-number-extractor.git)

## Step 2: Run These Commands in Replit Shell

Replace `YOUR_USERNAME` with your actual GitHub username:

```bash
# Add all files to git
git add .

# Commit your project
git commit -m "Complete OCR Android app with offline number extraction"

# Add GitHub as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/ocr-number-extractor.git

# Push to GitHub
git push -u origin main
```

## Alternative: If you get branch errors
```bash
# Check current branch
git branch

# If not on main, create and switch to main
git checkout -b main

# Then push
git push -u origin main
```

## Step 3: After Pushing
1. **Check your GitHub repository** - files should appear
2. **GitHub Actions** will automatically start building APK
3. **Wait 10 minutes** for build to complete
4. **Go to Actions tab** → **Latest workflow** → **Download APK**

## If Git Push Asks for Login:
```bash
# Set your GitHub credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Quick Copy-Paste Commands:
```bash
git add .
git commit -m "OCR Android app ready"
git remote add origin https://github.com/YOUR_USERNAME/ocr-number-extractor.git
git push -u origin main
```

Just replace `YOUR_USERNAME` with your GitHub username and run these in Replit shell!