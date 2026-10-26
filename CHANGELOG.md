# Changelog

All notable changes to the **Lunera** project will be documented in this file.

## [1.0.0] - 2026-10-21

### Added
- **Rebranding to Lunera**: Introduced slogan *"Every Phase, Your Own."* with custom-painted orbital crescent moon emblem.
- **Biometric Security & Privacy**: Integrated Fingerprint & Face ID lock (`local_auth`) with persistent `SharedPreferences` gate and 3-second grace period protection.
- **Pharmacokinetic Level Simulations**: Real-time interactive simulation curves for Estradiol and Testosterone with customizable target zones and lab result calibration.
- **Calendar & Timeline Dual View**: Schedule View and Full History Timeline View with interactive Date Picker.
- **HRT Duration Counter**: Real-time tracker calculating years, months, and days on therapy alongside total logged doses.
- **Mood & Body Journal**: Emotional state selectors (Calm, Happy, Neutral, Energetic, Tired), category filter chips, and CRUD operations.
- **Supply & Tool Management**: Medication vials, pills, patches, and equipment tracking (syringes, wipes, needles, gloves) with low stock and expiration alerts.
- **Avatar Performance Engine**: Zero-lag in-memory RAM image cache (`_avatarCache`), `BoxFit.cover` cropping dialog, and live circular avatar preview.
- **Data Backup & Export**: Offline JSON export/import and Firebase cloud backup.
- **Windows & Android Platform Support**: Deployment support for Android (APK) and Windows desktop platforms.

### Fixed
- **Photo Squishing Bug**: Solved photo distortion in profile avatar crop dialog using `paintImage` with `BoxFit.cover`.
- **Gallery Lock Screen Trigger**: Implemented 3-second grace period to prevent biometric lock screen from triggering when selecting photos from external pickers.
- **Historical Site Translation**: Live on-the-fly translation (`translatePlace`) converting legacy Indonesian injection site names (`Paha kiri`, `Paha kanan`, etc.) to English (`Left thigh`, `Right thigh`, etc.).

### Changed
- **Default Application Language**: Standardized 100% of user interface strings, schedule text, chart legends, and notifications to English (EN).
- **Midnight Theme System**: Refined Midnight palette featuring Midnight (`#0F122B`), Indigo (`#3B3F7A`), Lavender (`#A997FF`), and customizable accent choices (`Lunera`, `Moonlight`, `Ocean`, `Rose Quartz`).
