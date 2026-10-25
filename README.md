# 🌙 Lunera

> **Every Phase, Your Own.**  
> A gentle, elegant, and privacy-focused personal health and hormone therapy (HRT) tracker built with Flutter.

---

## 🌟 Overview

**Lunera** is a modern, privacy-first mobile and web application designed to accompany individuals on their hormone therapy and health journeys. Built with Flutter and Firebase, Lunera empowers users to understand their bodies, track dosage schedules, monitor physical changes, and maintain biometric security—all wrapped in a soothing, customizable Midnight UI.

---

## ✨ Features

- 🔒 **Biometric Security**: Protect your private health data with Fingerprint / Face ID lock (`local_auth`).
- 📊 **Hormone Level Simulations**: Interactive pharmacokinetic curves for Estradiol and Testosterone with customizable target zones.
- 📅 **Calendar & Timeline**: Complete schedule tracking, date picker navigation, and dose history logs.
- 📖 **Mood & Body Journal**: Daily emotional state logging, physical observation notes, and category filters.
- 📦 **Supplies & Equipment Tracking**: Manage stock levels for vials, syringes, alcohol wipes, needles, and expiration alerts.
- 🌐 **Cloud & File Backup**: Offline JSON export/import and Firebase cloud backup for complete data safety.
- 🎨 **Midnight Design System**: Aesthetic dark theme with custom accent choices, avatar cropping, and smooth animations.

---

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Backend & Database**: [Firebase Auth](https://firebase.google.com/products/auth) & [Cloud Firestore](https://firebase.google.com/products/firestore)
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Security**: [local_auth](https://pub.dev/packages/local_auth) & [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Localizations**: Standard Universal English (EN) default

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- Android Studio / VS Code
- Firebase Project configured via FlutterFire CLI (`flutterfire configure`)

### Local Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/lunera.git
   cd lunera
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🌐 Deploy to GitHub Pages

Lunera is fully compatible with **GitHub Pages**! A pre-configured GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically builds and deploys Flutter Web to GitHub Pages whenever you push code to the `main` or `master` branch.

### Enabling GitHub Pages in Repository Settings:

1. Push your code to GitHub.
2. Navigate to your repository on GitHub.
3. Go to **Settings** ➔ **Pages**.
4. Under **Build and deployment** ➔ **Source**, select **Deploy from a branch**.
5. Choose **`gh-pages`** branch and `/ (root)` folder, then click **Save**.
6. Your web application will be live at: `https://YOUR_USERNAME.github.io/YOUR_REPO_NAME/`

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
