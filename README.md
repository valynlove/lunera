# Lunera 🌙📱

<div align="center">

<img src="docs/images/readme_banner.jpg" alt="Lunera — A Little Moment Banner" width="100%" />

### _Every Phase, Your Own._

**A Gentle, Elegant & Privacy-Focused Personal Health & Therapy Tracker**

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-8065E8?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-A58BFF?logo=dart&logoColor=white)](https://dart.dev)
[![Cloud](https://img.shields.io/badge/Cloud-Firebase%20Auth%20%26%20Firestore-D76ABF?logo=firebase&logoColor=white)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-7DE2C7?labelColor=11102B)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.3.0-F2A17C?labelColor=11102B)](CHANGELOG.md)

[🌐 Visit Landing Page](https://valynlove.github.io/lunera/) • [📥 Direct Download APK](https://github.com/valynlove/lunera/releases/latest/download/Lunera.apk) • [📋 Changelog](CHANGELOG.md)

</div>

---

## 🌟 Overview

**Lunera** is a modern, offline-first, privacy-focused mobile and desktop application designed to accompany individuals on their personal wellness and hormone therapy journeys. Built with Flutter, Riverpod, and optional Firebase sync, Lunera empowers users to understand their physiological rhythms, track dosage schedules, prepare for clinician visits, monitor physical transitions, and stay supported with an empathetic companion—all wrapped in the soothing **Eternal Dusk** twilight sanctuary design system.

---


## 🆕 Recent Highlights (`v2.3.0`)

- **Cycle-Aware Insights, Smart Vial Radar, Companion Daily Ritual & Journey Timeline (`v2.3.0`):** Added Peak/Mid/Trough hormone-phase correlation with mood & symptoms, open-vial beyond-use & syringe dead-space tracking, custom bloodwork countdowns, 60-second Daily Check-in Ritual & Bond Tier Perks, customizable Starlight Breathing presets with phase haptics, 30-day voice pitch trend summaries, Travel & Timezone dose-shift helper, Quick Clinic Care Card, and a unified chronological Journey Timeline.
- **Interactive Companion Ecosystem & Widget Gallery (`v2.2.45`):** Added a new 2×2 interactive Android Companion home screen widget (poke, pat, and cozy chats with 14 mascot expressions), connected `♥` affection bond milestones & daily hydration (`💧`) check-ins between the home screen widget and in-app `AmbientCompanionCard`, added a **Browse & Pin Widgets** gallery in Settings, moved/enlarged the Movement Coach widget mascot into the middle-right area, expanded the landing page showcase to all 5 widgets, and resolved all remaining analyzer lints.
- **Android App Launcher Fix (`v2.2.44`):** Restored the original **Lunera** wordmark launcher artwork across Android mipmaps (distinct from the in-app emblem) with clean transparent legacy corners and seamless adaptive layers so no black corners appear.
- **Celestial Reverie Theme & Artwork Refresh (`v2.2.43`):** Adopted the Celestial Reverie color tokens (`#170B3D`–`#FFE2C8`) with verified WCAG AA contrast alongside refreshed cosmic backdrop, splash, overlay, avatar frame, and profile banner artwork.
- **Audit Polish, Bug Fixes & Asset Cleanup (`v2.2.42`):** Switched desktop sidebar & PIN/Biometric lock screen to `lunera_text.png` (removing the lock-screen emblem circle), fixed injection site rotation date sorting and `BodyPage` layout collapse, removed the HRT Time-Lapse mini-game plus unused legacy assets, and regenerated full-bleed Android launcher icons without black corners.
- **Wordmark Branding (`v2.2.41`):** Updated the landing page header/footer branding, Flutter splash screen wordmark, and About Lunera showcase wordmark to use `lunera_text.png`.

- **Adaptive Multi-Device Layout & Visual System (`v2.2.40`):** Added window-first responsive navigation (Bottom Bar on phones, Navigation Rail on tablets, Persistent Sidebar with `Alt+1–5` shortcuts on desktop), split views, responsive grids, adaptive modal dialogs, tabular numerals, `Reduce Motion` support, and `48×48dp` accessible touch targets across screens.
- **Companion Asset Organization (`v2.2.39`):** Organized the 20 regular companion mascot sprites into `assets/images/companion/regular/` alongside `assets/images/companion/coach/`.
- **16 Sporty Coach Expressions & Interactive Guidance (`v2.2.38`):** Expanded `CoachMood` to 16 expressions (`ready`, `focus`, `breathe`, `stretch`, `gentle`, `effort`, `rest`, `listen` + original 8), paired with interactive _Body check-in_ chips on Movement Coach and dynamic live-session cues.
- **Interactive Ambient Companion (`v2.2.37`):** Long-press _Quiet Hugs_, rapid-tap _Playful Moment_ reactions across 20 `CompanionMood` expressions, and offline _Calm me_, _Care tip_, and _Smile_ topic chips with direct shortcuts to Starlight Breathing and Care Guides.
- **New Eternal Dusk App Launcher & Orbital Emblem (`v2.2.36`):** Refreshed the Android/iOS/macOS/Windows launcher icons (including Android 8+ adaptive icons) with the glowing _Lunera_ crescent crest, and updated the in-app `MoonLogo`, Web/PWA icons, and showcase logos to the new orbital crescent emblem.
- **Scaled Companion & Coach Mascots (`v2.2.35`):** Refined `CompanionAvatar` and `CoachAvatar` sizing across cards, headers, empty states, guided injection, voice warm-up, Movement Coach screens, and the 2×2 Android Movement Coach widget (`50dp × 58dp`) for clear visual presence without crowding compact layouts.
- **HRT-Aware Movement Coach (`v2.2.34`):** Guilt-free personal trainer inside Twilight Sanctuary featuring 4 HRT-aware preset programs, Custom Routine Builder, 2-pose animated exercise diagrams, injection-site & trough-window adaptation, zero-streak-penalty _Ease Back In_ flow, and a 2×2 Android Home Screen widget.
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
- 🔔 **Precision Offline Notifications:** Native local reminders (`flutter_local_notifications`) with exact alarm receivers, _"Mark taken"_ & 15/30-minute snooze actions, optional trough bloodwork reminders, and discreet wellness masking by default.

### 🌙 Companion, Sanctuary & Personal Journey

- 💜 **Empathetic Ambient Companion & Sporty Coach Mascots:** 20-mood `CompanionAvatar` on Home (contextual greetings, imminent-dose & post-dose care, tap-to-cycle affirmations, reduced-motion support) plus 8-mood `CoachAvatar` in Movement Coach.
- 🏃 **HRT-Aware Movement Coach:** Offline-first personal trainer inside Twilight Sanctuary with 4 preset programs (_Feminizing Focus_, _Masculinizing Focus_, _Bone & Heart Care_, _Low-Energy / Trough Recovery_), Custom Routine Builder, baseline calibration, active rest/hold timers, and 2-pose animated diagrams.
- ✨ **Twilight Sanctuary Mini-Experiences:** Touch-ripple 4-4-6 breathing canvas (_Starlight Ripples_), 5-question _Safety & Dosing Sense_ practice quiz, zero-punishment daily _Moonlight Lantern_, and unlockable _Voice Pitch Studio_ (in-RAM YIN pitch + FFT spectral resonance/vocal weight analysis with zero audio saved, 4-step SOVTE warm-up, pitch pipe, and reading passages).
- 📖 **Journal, Body Progress, Moments & Milestones:** Structured symptom check-ins & mood journal, dual-unit body measurement tracking with bra-size & WHR/chest trend charts (`fl_chart`), _Lunera Moments_ visual scrapbook, and private local-only transition milestones behind biometric/PIN lock.
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
- _(Optional)_ Firebase Project configured with Authentication and Cloud Firestore for cloud sync

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
