# PlanCraft Pro AI — Flutter Web Edition

AI-assisted 2D/3D floor plan architect. **Web only. No APK. 100% offline** after first load.

👉 **Open `guide.html` in a browser for the full setup, deploy, and usage guide** (dark neon theme, step-by-step commands).

Quick start:
```
flutter pub get
flutter run -d chrome
```

Deploy to GitHub Pages:
```
flutter build web --release --base-href "/your-repo-name/"
```
Then push the contents of `build/web` to your `gh-pages` branch, or use the included
`.github/workflows/deploy.yml` GitHub Action (recommended — just edit the base-href
inside it to match your repo name).
