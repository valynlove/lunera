# Changelog 📋

All notable changes to the **Lunera** personal health & therapy tracking application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
