# Lunera 🌙📱

<div align="center">

<img src="docs/images/logo.png" alt="Lunera Logo" width="130" style="border-radius: 28px;" />

### _Every Phase, Your Own._

**A Gentle, Elegant & Privacy-Focused Personal Health & Therapy Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-8065E8?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-A58BFF?logo=dart&logoColor=white)](https://dart.dev)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-D76ABF?logo=firebase&logoColor=white)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-7DE2C7?labelColor=11102B)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.2.0-F2A17C?labelColor=11102B)](CHANGELOG.md)

[🌐 Visit Landing Page](https://valynlove.github.io/lunera/) • [📥 Direct Download APK](https://github.com/valynlove/lunera/releases/latest/download/Lunera.apk) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Lunera** is a modern, privacy-first mobile and desktop application designed to accompany individuals on their personal wellness and hormone therapy journeys. Built with Flutter, Riverpod, and Firebase, Lunera empowers users to understand their physiological rhythms, track dosage schedules, monitor physical transitions, and ensure complete biometric security—all wrapped in the soothing **Eternal Dusk** twilight sanctuary design system.

---

## 🎨 Eternal Dusk Theme Palette

Lunera combines **Midnight Aurora** depth with **Vice City Sunset** warmth across both the mobile app (`lib/theme.dart`) and the web landing page (`docs/`):

| Token | Hex | Role |
| :--- | :--- | :--- |
| **Void** | `#090817` | Deepest obsidian void canvas & cold-launch backdrop |
| **Midnight** | `#11102B` | Primary nocturnal canvas |
| **Deep Card** | `#171436` | Layered dark card surface |
| **Nebula** | `#292052` | Elevated cosmic plum surface |
| **Aurora** | `#8065E8` | Primary electric aurora violet |
| **Violet** | `#A58BFF` | Luminous violet highlight |
| **Lavender** | `#C7B8FF` | Soft lavender rim & active icon accent |
| **Magenta** | `#D76ABF` | Dusk sunset magenta gradient accent |
| **Rose** | `#F09ABF` | Warm twilight rose (Estradiol E2 series) |
| **Coral** | `#F2A17C` | Horizon sunset coral (Progesterone P4 & stock alerts) |
| **Mint** | `#7DE2C7` | Completed doses, adherence & in-range clinical states |

---

## ✨ Key Features

- 🔒 **PIN Security & Multi-Device Sync:** Protect your private medical data with a 6-digit salted SHA-256 PIN lock (`flutter_secure_storage` + Keystore/Keychain), Decoy Calculator camouflage, and encrypted multi-device sync via Firebase Cloud Firestore.
- 🌌 **Eternal Dusk Splash & Twilight Sanctuary:** Dual-controller staged entrance animation (`SplashPage`) with layered atmospheric backdrop (`eternal_dusk_splash_bg.jpg` + `eternal_dusk_overlay.png`), pulsing Aurora/Magenta/Coral emblem halo, `Instrument Serif` display typography, and `Plus Jakarta Sans` UI clarity.
- 🎯 **Unified Lucide Icon System:** Clean, consistent `lucide_icons_flutter` outline iconography across the app paired with the Eternal Dusk orbital crescent emblem.
- 📊 **Pharmacokinetic Level Simulations:** Interactive multi-compartment pharmacokinetic curves for Estradiol and Testosterone with customizable target zones and lab result calibration.
- 💉 **Visual Injection Site Map & Heatmap:** Interactive 2D anatomical silhouette with dual-perspective views (Front and Back), intelligent tissue rest tracking (days since last injection), and automatic site rotation suggestions.
- 📈 **Body Measurements & Progression Curves:** Dual-unit body measurement logging (bust, underbust, waist, hips, thigh, calf, inseam, feet, weight, height) with automatic bra size calculation, clothing fit, and interactive trend charts (`fl_chart`) for WHR and chest progression.
- 📅 **Dual-View Timeline & Schedule:** Interactive calendar picker navigation, rolling interval scheduling, and dose history logs.
- 🔔 **Scheduled Dose Reminders:** Offline-capable native local notifications (`flutter_local_notifications`) with exact alarm receivers and high-importance sound/vibration channels.
- 📖 **Mood & Body Observation Journal:** Daily emotional state logging, physical transition observation notes, and category filters.
- 📚 **Care & HRT Guides:** Offline-first, bilingual (EN/ID) educational and harm-reduction library (14 guides) covering dosing math, lab units, safe injection & rotation, voice training basics, medical red flags, and non-judgmental starting guidance.
- ✨ **Twilight Sanctuary:** Calming touch-ripple 4-4-6 breathing canvas, interactive safety & dosing quiz, no-punishment daily Moonlight Lantern companion, and an unlockable Voice Pitch Studio (on-device Hz checks & prompts without saving audio).
- 📦 **Supply & Equipment Tracking:** Manage inventory for vials, syringes, alcohol wipes, and needles with automatic stock deduction upon dose intake.
- 💾 **Dual Local & Cloud Safety:** Completely offline JSON export/import, standalone CSV/JSON dose history export, and secure cloud synchronization via Firebase Cloud Firestore.
- 🌐 **Bilingual Localization:** Full native support for English (default) and Bahasa Indonesia with dynamic runtime switching.

---

## 🛠️ Technology Stack

| Layer                   | Technology                                                       |
| :---------------------- | :--------------------------------------------------------------- |
| **Framework**           | Flutter (Stable Channel)                                         |
| **Language**            | Dart 3                                                           |
| **UI & Typography**     | Eternal Dusk Design System (`google_fonts`, `lucide_icons_flutter`) |
| **State Management**    | Riverpod (`flutter_riverpod`)                                    |
| **Backend & Cloud**     | Firebase Core, Firebase Auth, Cloud Firestore                    |
| **Data Visualization**  | `fl_chart`                                                       |
| **Local Notifications** | `flutter_local_notifications`, `timezone`, `flutter_timezone`    |
| **Hardware & Security** | `local_auth`, `flutter_secure_storage`, `shared_preferences`     |
| **CI / CD Automation**  | GitHub Actions (Auto APK Compilation & GitHub Release)           |
| **Landing Page**        | HTML5, Modern CSS3, Vanilla JavaScript (GitHub Pages in `/docs`) |

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
