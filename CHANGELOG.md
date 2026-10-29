# Changelog 📋

All notable changes to the **Lunera** personal health & therapy tracking application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-10-29

### Added
- **Native Android Home Screen Widgets (`home_widget`):**
  - Integrated 3 native Android AppWidgets accessible directly from the home screen:
    - **Lama Terapi (HRT Counter):** Displays continuous transition duration (years, months, days) and total taken dose tally.
    - **Jadwal Dosis (Schedule):** Real-time list of the next 3 upcoming or overdue doses with scheduled timestamps, dose units, and recommended injection rotation sites.
    - **Level Hormon (Level Chart):** Crisp pharmacokinetic level simulation curve rendered off-screen with custom painters, displaying current estimated levels and lab result markers.
  - Automated background synchronizer (`lib/widget_sync.dart`) updating home screen widgets whenever doses are logged, therapies modified, or lab results added.
  - Added privacy switch in **Pengaturan > Widget Layar Utama > Sembunyikan detail di widget** to mask medical data when the phone is viewed by others.
  - Integrated clean cache clearing upon user sign-out (`WidgetSync.clear()`).

---

## [1.3.0] - 2026-10-29

### Added
- **Dedicated Profile Management & Avatar Customization (`lib/profile.dart` & `lib/ui/profile_page.dart`):**
  - Integrated customizable **Nickname** and **Profile Photo** avatar matching the *Wall o' Pay* experience.
  - Interactive camera button overlay allowing photo selection from gallery (`image_picker`) with desktop file dialog fallback (`file_selector`).
  - Automatic on-device caching via `shared_preferences` and real-time cloud synchronization to Firestore (`users/$uid/meta/profile`).
  - Background cloud restoration so user profile and avatar automatically sync when logging in across multiple devices.
- **Enhanced Home & More Navigation:**
  - Dynamic personalized greeting in `lib/ui/home.dart` prioritizing Nickname over username/email.
  - Replaced static avatar placeholder with interactive `UserAvatar` widget in both Home header and More dashboard.
  - Added dedicated Profile Card and menu action in `lib/ui/more.dart` for 1-tap navigation to profile customization.
- **Biometric Security Grace Period:**
  - Preserved strict 3-second grace window when opening system file/photo pickers to avoid unintentional lock triggers.

---

## [1.2.0] - 2026-10-29

### Added
- **Refreshed High-Precision Moon Orbital Emblem:**
  - Regenerated all Android launcher mipmaps (`mdpi` through `xxxhdpi`), Web progressive web app icons & favicon, and Docs showcase brand assets from 1024x1024 high-resolution artwork.
- **Interactive Body Changes Visualizer (`lib/ui/body.dart`):**
  - Anatomical body silhouette with interactive callouts for hair, breast development, skin, and body shape.
  - Category-based observation timelines tracking physical changes and transition progress over time.
- **Insights & Cycle Correlation Engine (`lib/ui/insights.dart`):**
  - 30-day dose adherence metrics measuring taken, skipped, and overdue medication slots.
  - Emotional distribution analysis across 5 mood states (*Senang, Tenang, Biasa, Murung, Cemas*).
  - Algorithmic hormone cycle correlation (`moodByCycleDay`) highlighting emotional trends relative to dosage intervals.
- **Comprehensive Mood Integration:**
  - Added `MoodQuickCard` on the Home screen for quick 1-tap daily mood check-ins.
  - Placed interactive mood spots and tooltips directly on pharmacokinetic level charts in `lib/ui/levels.dart`.
  - Integrated 3rd tab (`Jurnal`) in the Calendar view (`lib/ui/calendar.dart`) with filterable category chips (*Semua, Suasana, Tubuh, Catatan*).
- **Model & Architecture Enhancements:**
  - Upgraded `JournalEntry` schema with structured per-area observations (`bodyAreas`), mood ratings, and numeric scoring (`moodScore`).
  - Seamlessly harmonized new features with biometrics, exit warning confirmations (`PopScope`), and in-app update checker.

---

## [1.1.0] - 2026-10-29

### Added
- **Comprehensive UI & Navigation Overhaul:**
  - Modernized visual experience with NightScene dynamic backdrops, orbital crescent moon emblem (`MoonLogo`), and curated Manrope & Jost typography.
  - Reorganized into a streamlined 5-tab navigation shell: Beranda (Home), Kalender (Calendar), Level (Insights/Labs), Stok (Supplies), and Lainnya (More).
- **Dedicated PIN & Biometric Security Engine (`lib/lock.dart` & `lock_screen.dart`):**
  - Salted SHA-256 6-digit PIN hashing stored safely on-device with `crypto`.
  - Biometric authentication (Fingerprint and Face ID) with configurable auto-lock timeouts (Immediate, 1 min, 5 min) and 30-second cooldown on failed attempts.
  - Full-screen PIN flow for secure PIN setup, verification, and change in dedicated Security dashboard (`security_page.dart`).
- **Interactive Weekly Calendar & Agenda (`calendar.dart`):**
  - Week strip date selector with schedule indicators, dynamic agenda list, and 1-tap view switcher between upcoming doses and full intake history.
- **Automated Stock & Expiration Reminders:**
  - Automatic daily 09:00 notifications for depleted supplies and medications.
  - Advance expiration alerts at 14 days, 3 days, and day-of expiry.
- **Username Registration & Cloud Rules:**
  - Seamless account sign-up and sign-in using customized `@username` handles or email addresses.
  - Preserved in-app update checking and exit warning confirmation across all tabs.

---

## [1.0.1] - 2026-10-28

### Added
- **Exit Warning & Confirmation Dialog (`PopScope`):**
  - Integrated graceful back navigation and exit confirmation dialog matching *Wall o' Pay*.
  - When pressing back on secondary tabs (Timeline, Insights, Journal), automatically navigates back to the Home tab first.
  - When pressing back on the Home tab, displays a themed Lunera exit dialog with Cancel and Exit actions, preventing accidental app closure.

---

## [1.0.0] - 2026-10-28

### Added
- **Rebranding to Lunera:**
  - Modernized brand identity with *"Every Phase, Your Own."* motto and orbital crescent moon emblem.
  - Curated Midnight UI palette with Midnight (`#0F122B`), Indigo (`#3B3F7A`), and Lavender (`#A997FF`).
- **Biometric Security & Privacy (`local_auth`):**
  - Integrated Fingerprint and Face ID authentication gate (`pin_lock_gate.dart`) protecting all private health records.
  - Implemented 3-second grace period protection for seamless camera/file-picker transitions.
- **Pharmacokinetic Level Simulations (`fl_chart`):**
  - Interactive multi-compartment pharmacokinetic curves for Estradiol and Testosterone esters.
  - Configurable target hormone ranges with visual target zone overlays and lab result calibration.
- **Dose Schedule & Dual View Timeline:**
  - Interactive calendar picker, rolling interval schedule calculations, and historical dose logs.
  - Real-time HRT duration counter tracking years, months, and days since therapy start.
- **Mood & Body Observation Journal:**
  - Daily emotional status logging, physical observation notes, and category filters.
- **Supply & Inventory Management:**
  - Track medication vials, syringes, alcohol wipes, and needles with automatic stock deduction upon dose intake.
  - Low stock reminders and expiration warning alerts.
- **Local & Cloud Data Safety:**
  - Completely offline JSON backup export and import with validation.
  - Cloud backup synchronization via Firebase Cloud Firestore.
- **Cross-Platform Support:**
  - Optimized for Android mobile devices, Windows desktop, and clean Flutter Web runtime.
- **In-App Update Checker (`UpdateCheckerService`):**
  - Integrated automatic release polling via GitHub Releases public API.
  - Displays a dedicated update dialog showing new version numbers, release notes, and a direct 1-tap "Update Now" button.
  - Added on-demand "Check for Updates" option in Settings dashboard.
  - Added background check 3 seconds after application launch.
- **Dedicated Web Showcase Library:**
  - Standalone web landing page in `docs/` with dynamic release detection and responsive layouts.

### Fixed
- **Persistent Release Key Signing for Seamless Updates:**
  - Configured repository-level release signing credentials (`key.properties` and `release-keystore.jks`) for GitHub Actions CI and local builds.
  - Ensures every GitHub Actions build is signed with the identical cryptographic signature, eliminating Android's `INSTALL_FAILED_UPDATE_INCOMPATIBLE` ("App not installed as package conflicts with an existing package") error when updating in-place.
- **Scheduled Dose Notifications:**
  - Registered `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` in Android manifest to prevent scheduled alarms from being dropped by the OS.
  - Added `USE_EXACT_ALARM` permission and explicit high-importance `doses` notification channel with sound & vibration.
  - Resilient timezone offset fallback ensuring notifications fire at exact local device clock times.
  - Automatic notification permission prompt upon entering app dashboard.
- **Profile Photo Cropping:**
  - Resolved avatar photo aspect distortion in crop dialog using `paintImage` with `BoxFit.cover`.
  - Added in-memory RAM image cache (`_avatarCache`) for butter-smooth profile rendering.
- **Injection Site Localization:**
  - On-the-fly translation converting legacy Indonesian site names to standardized English (`Left thigh`, `Right thigh`, etc.).
