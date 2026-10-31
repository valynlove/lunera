# Lunera 🌙📱

<div align="center">

<img src="docs/images/logo.png" alt="Lunera Logo" width="130" style="border-radius: 28px;" />

### *Every Phase, Your Own.*
**A Gentle, Elegant & Privacy-Focused Personal Health & Therapy Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.11.4-6C5CE7.svg)](CHANGELOG.md)

[🌐 Visit Landing Page](https://valynlove.github.io/lunera/) • [📥 Download Latest APK](https://github.com/valynlove/lunera/releases/latest) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Lunera** is a modern, privacy-first mobile and desktop application designed to accompany individuals on their personal wellness and hormone therapy journeys. Built with Flutter, Riverpod, and Firebase, Lunera empowers users to understand their physiological rhythms, track dosage schedules, monitor physical transitions, and ensure complete biometric security—all wrapped in a soothing Midnight UI.

---

## ✨ Key Features

- 🔒 **PIN Security & Multi-Device Sync:** Protect your private medical data with a 6-digit salted SHA-256 PIN lock, automatically synchronized across all your devices via Firebase Cloud Firestore.
- 🌌 **Atmospheric Lake Splash & Celestial Theme:** Serene night lake entrance animation (`SplashPage`) with reflective water horizons, celestial orbit ring icons, and smooth transitions.
- 📊 **Pharmacokinetic Level Simulations:** Interactive multi-compartment pharmacokinetic curves for Estradiol and Testosterone with customizable target zones and lab result calibration.
- 💉 **Visual Injection Site Map & Heatmap:** Interactive 2D anatomical silhouette with dual-perspective views (Front and Back), intelligent tissue rest tracking (days since last injection), and automatic site rotation suggestions.
- 📈 **Body Measurements & Progression Curves:** Dual-unit body measurement logging (bust, underbust, waist, hips, thigh, calf, inseam, feet, weight, height) with automatic bra size calculation, clothing fit, and interactive trend charts (`fl_chart`) for WHR and chest progression.
- 📅 **Dual-View Timeline & Schedule:** Interactive calendar picker navigation, rolling interval scheduling, and dose history logs.
- 🔔 **Scheduled Dose Reminders:** Offline-capable native local notifications (`flutter_local_notifications`) with exact alarm receivers and high-importance sound/vibration channels.
- 📖 **Mood & Body Observation Journal:** Daily emotional state logging, physical transition observation notes, and category filters.
- 📦 **Supply & Equipment Tracking:** Manage inventory for vials, syringes, alcohol wipes, and needles with automatic stock deduction upon dose intake.
- 💾 **Dual Local & Cloud Safety:** Completely offline JSON export/import and secure cloud synchronization via Firebase Cloud Firestore.
- 🌐 **Bilingual Localization:** Full native support for English (default) and Bahasa Indonesia with dynamic runtime switching.
- 🎨 **Midnight Design System:** Aesthetic dark theme with customizable accent palettes (`Lunera`, `Moonlight`, `Ocean`, `Rose Quartz`) and smooth animations.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter (Stable Channel) |
| **Language** | Dart 3 |
| **State Management** | Riverpod (`flutter_riverpod`) |
| **Backend & Cloud** | Firebase Core, Firebase Auth, Cloud Firestore |
| **Data Visualization** | `fl_chart` |
| **Local Notifications** | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| **Hardware & Security** | `local_auth` (Biometrics), `shared_preferences` |
| **CI / CD Automation** | GitHub Actions (Auto APK Compilation & GitHub Release) |
| **Landing Page** | HTML5, Modern CSS3, Vanilla JavaScript (GitHub Pages in `/docs`) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.3.0)
- [Android Studio](https://developer.android.com/studio) or VS Code
- Firebase Project configured with Authentication and Cloud Firestore

### Installation
```bash
# Clone the repository
git clone https://github.com/valynlove/lunera.git
cd lunera

# Install dependencies
flutter pub get

# Run on your connected device or emulator
flutter run
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
