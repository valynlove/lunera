# Lunera 🌙📱

<div align="center">

<img src="docs/images/readme_banner.jpg" alt="Lunera — A Little Moment Banner" width="100%" />

<br /><br />

### _Every Phase, Your Own._

**A Gentle, Elegant & Privacy-Focused Personal Health & Therapy Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-8065E8?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-A58BFF?logo=dart&logoColor=white)](https://dart.dev)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-D76ABF?logo=firebase&logoColor=white)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-7DE2C7?labelColor=11102B)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.2.35-F2A17C?labelColor=11102B)](CHANGELOG.md)

[🌐 Visit Landing Page](https://valynlove.github.io/lunera/) • [📥 Direct Download APK](https://github.com/valynlove/lunera/releases/latest/download/Lunera.apk) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Lunera** is a modern, offline-first, privacy-focused mobile and desktop application designed to accompany individuals on their personal wellness and hormone therapy journeys. Built with Flutter, Riverpod, and optional Firebase sync, Lunera empowers users to understand their physiological rhythms, track dosage schedules, prepare for clinician visits, monitor physical transitions, and stay supported with an empathetic companion—all wrapped in the soothing **Eternal Dusk** twilight sanctuary design system.

---

## 🆕 Recent Highlights (`v2.2.35`)

- **Scaled Companion & Coach Mascots:** Refined `CompanionAvatar` and `CoachAvatar` sizing across cards, headers, empty states, guided injection, voice warm-up, Movement Coach screens, and the 2×2 Android Movement Coach widget (`50dp × 58dp`) for clear visual presence without crowding compact layouts.
- **HRT-Aware Movement Coach (`v2.2.34`):** Guilt-free personal trainer inside Twilight Sanctuary featuring 4 HRT-aware preset programs, Custom Routine Builder, 2-pose animated exercise diagrams, injection-site & trough-window adaptation, zero-streak-penalty *Ease Back In* flow, and a 2×2 Android Home Screen widget.
- **Responsive Showcase & Split-ABI Releases (`v2.2.32–v2.2.33`):** Per-ABI Android APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) for smaller downloads plus an accessible mobile/tablet navigation drawer on the landing page.

---

## 🎨 Eternal Dusk Theme Palette

Lunera combines **Midnight Aurora** depth with **Vice City Sunset** warmth across both the mobile app (`lib/theme.dart`) and the web landing page (`docs/`):

| Token         | Hex       | Role                                                  |
| :------------ | :-------- | :---------------------------------------------------- |
| **Void**      | `#090817` | Deepest obsidian void canvas & cold-launch backdrop   |
| **Midnight**  | `#11102B` | Primary nocturnal canvas                              |
| **Deep Card** | `#171436` | Layered dark card surface                             |
| **Nebula**    | `#292052` | Elevated cosmic plum surface                          |
| **Aurora**    | `#8065E8` | Primary electric aurora violet                        |
| **Violet**    | `#A58BFF` | Luminous violet highlight                             |
| **Lavender**  | `#C7B8FF` | Soft lavender rim & active icon accent                |
| **Magenta**   | `#D76ABF` | Dusk sunset magenta gradient accent                   |
| **Rose**      | `#F09ABF` | Warm twilight rose (Estradiol E2 series)              |
| **Coral**     | `#F2A17C` | Horizon sunset coral (Progesterone P4 & stock alerts) |
| **Mint**      | `#7DE2C7` | Completed doses, adherence & in-range clinical states |

---

## ✨ Key Features

### 🩺 Clinical Tracking, Scheduling & Insights
- 📊 **Pharmacokinetic Level Simulations:** Multi-compartment pharmacokinetic curves for Estradiol and Testosterone (including long-acting esters & transdermal gel profiles), customizable target bands, upcoming scheduled dose projections, peak/trough estimates, and lab calibration with `<` / `>` censored comparators and `ng/L` / `µg/L` units.
- 💉 **Visual Injection Site Map & Syringe Calculator:** Interactive Front & Back Lunera body diagram with tissue rest tracking, smart site rotation suggestions, Guided Calm Injection mode, and a live `mg` → `mL` / `U-100` draw-volume calculator in `DoseSheet`.
- 📅 **Pharmacokinetic-Aware Timeline & Smart Care Alerts:** Week/month calendar grid with dose, trough lab window, journal, supply depletion, and appointment indicators, paired with a unified Smart Reminder Drawer (`CareAlertsSheet`).
- 🩺 **Smart Consultation Prep & Doctor Visit Reports:** 90-day symptom clustering correlated with dose/trough rhythms, pre-visit document checklists, and one-tap Markdown or A4 PDF clinician summaries (automatically excluding private notes, journal entries, supplies, and measurements).
- 📦 **Predictive Supply & Refill Horizon:** Inventory tracking for vials, syringes, wipes, and needles with automatic deduction upon dose intake and tiered refill forecasts (depleted, critical `<=7d`, reorder window `8–14d`).
- 🔔 **Precision Offline Notifications:** Native local reminders (`flutter_local_notifications`) with exact alarm receivers, *"Mark taken"* & 15/30-minute snooze actions, optional trough bloodwork reminders, and discreet wellness masking by default.

### 🌙 Companion, Sanctuary & Personal Journey
- 💜 **Empathetic Ambient Companion & Sporty Coach Mascots:** 20-mood `CompanionAvatar` on Home (contextual greetings, imminent-dose & post-dose care, tap-to-cycle affirmations, reduced-motion support) plus 8-mood `CoachAvatar` in Movement Coach.
- 🏃 **HRT-Aware Movement Coach:** Offline-first personal trainer inside Twilight Sanctuary with 4 preset programs (*Feminizing Focus*, *Masculinizing Focus*, *Bone & Heart Care*, *Low-Energy / Trough Recovery*), Custom Routine Builder, baseline calibration, active rest/hold timers, and 2-pose animated diagrams.
- ✨ **Twilight Sanctuary Mini-Experiences:** Touch-ripple 4-4-6 breathing canvas (*Starlight Ripples*), 5-question *Safety & Dosing Sense* practice quiz, zero-punishment daily *Moonlight Lantern*, and unlockable *Voice Pitch Studio* (in-RAM YIN pitch + FFT spectral resonance/vocal weight analysis with zero audio saved, 4-step SOVTE warm-up, pitch pipe, and reading passages).
- 📖 **Journal, Body Progress, Moments & Milestones:** Structured symptom check-ins & mood journal, dual-unit body measurement tracking with bra-size & WHR/chest trend charts (`fl_chart`), *Lunera Moments* visual scrapbook, and private local-only transition milestones behind biometric/PIN lock.
- 📚 **Care & HRT Guides Library:** 14 offline-first, bilingual (EN/ID) evidence-informed educational & harm-reduction articles with full-text search, category filters, and trusted references.

### 🔒 Privacy, Widgets & Ecosystem
- 🔐 **Biometric / PIN Security & Decoy Mode:** 6-digit salted SHA-256 PIN lock (`flutter_secure_storage` + biometric `local_auth`), Decoy Calculator camouflage, and per-UID local data isolation.
- 💾 **Encrypted Backups & Dual Safety:** Offline plain JSON, passphrase-protected AES-256-GCM + PBKDF2-HMAC-SHA256 (`.enc.json`) encrypted backups, standalone CSV/JSON history export, and optional Firebase Cloud Firestore sync.
- 📱 **4 Android Home Screen Widgets:** Celestial-backdrop glanceable widgets for **Schedule**, **HRT Cycle Dial**, **Hormone Levels Chart**, and **2×2 Movement Coach** with quick **Start** / **Rest** actions and `widgetHide` privacy masking.
- 🌐 **Bilingual & Multi-Device Ready:** Full English and Bahasa Indonesia localization with runtime switching and responsive mobile/tablet layout constraints.

---

## 🛠️ Technology Stack

| Layer                   | Technology                                                          |
| :---------------------- | :------------------------------------------------------------------ |
| **Framework**           | Flutter (Stable Channel)                                            |
| **Language**            | Dart 3                                                              |
| **UI & Typography**     | Eternal Dusk Design System (`google_fonts`, `lucide_icons_flutter`) |
| **State Management**    | Riverpod (`flutter_riverpod`)                                       |
| **Backend & Cloud**     | Firebase Core, Firebase Auth, Cloud Firestore (optional sync)       |
| **Data Visualization**  | `fl_chart`                                                          |
| **Local Notifications** | `flutter_local_notifications`, `timezone`, `flutter_timezone`       |
| **Hardware & Security** | `local_auth`, `flutter_secure_storage`, `cryptography`, `record`    |
| **Home Screen Widgets** | `home_widget` + native Kotlin `AppWidgetProvider` / `RemoteViews`   |
| **CI / CD Automation**  | GitHub Actions (Split-ABI APK Builds, Releases & GitHub Pages)      |
| **Landing Page**        | HTML5, Modern CSS3, Vanilla JavaScript (GitHub Pages in `/docs`)    |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>= 3.3.0 < 4.0.0`)
- [Android Studio](https://developer.android.com/studio) or VS Code
- *(Optional)* Firebase Project configured with Authentication and Cloud Firestore for cloud sync

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
