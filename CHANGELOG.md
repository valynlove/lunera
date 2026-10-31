# Changelog 📋

All notable changes to the **Lunera** personal health & therapy tracking application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.11.3] - 2026-10-31

### Added
- **Hybrid Asteria Architecture with Zero-Setup Instant Venting (`lib/asteria.dart` & `lib/ui/asteria_chat.dart`):**
  - Integrated built-in public key support (`DEFAULT_GEMINI_API_KEY`) compiled via GitHub Actions Secret for zero-friction chat experience for general users.
  - Retained private key override in Settings for users desiring dedicated, unshared quota.
  - Implemented compassionate HTTP 429 quota exhaustion handler: Asteria displays a soothing "Asteria is resting" celestial status card rather than technical errors when public daily limits are reached.
  - Added live status dot indicators in Asteria's header bar reflecting active, offline, and resting states.

---

## [1.11.2] - 2026-10-31

### Added
- **Asteria AI Companion (`lib/asteria.dart` & `lib/ui/asteria_chat.dart`):**
  - Integrated Asteria, an empathetic, validating, non-judgmental conversational sanctuary for sharing transition dysphoria, mood fluctuations, self-doubt, and personal milestones.
  - Powered by Google Gemini 1.5 Flash Cloud API using lightweight REST requests with zero additional third-party dependencies.
  - Dedicated Home screen Floating Action Button (FAB) for instant, one-tap access to heart-to-heart venting.
  - Graceful real-time offline detection: gently locks the interface with a peaceful celestial starry illustration when internet is unavailable and unlocks automatically upon reconnecting.
  - Session Summarizer & Save to Journal: creates a warm 2-3 sentence reflection with estimated mood rating and saves directly to the user's personal Journal, while wiping the chat history clean for a fresh start.
  - Secure Bring-Your-Own-Key (BYOK) architecture: Gemini API Key stored privately in user account preferences, editable via Chat modal or Settings page.

---

## [1.11.1] - 2026-10-31

### Fixed
- **Responsive Body Silhouette Proportions on Tablets (`lib/ui/body.dart`):**
  - Resolved distorted and flattened ("gepeng") anatomical silhouette drawing when viewed in landscape mode on tablet and wide-screen devices.
  - Decoupled body shoulder width scale factor (`sw`) and center offset (`cx`) in `_BodyPainter` from unbounded viewport width, bounding it to anatomical height proportions (`h * 0.25`).
  - Centered the overview silhouette and callout badges within a responsive `diagramW` constraint (capped at 440px on tablets) while preserving 100% natural full-width rendering on mobile devices.

---

## [1.11.0] - 2026-10-31

### Added
- **Body Measurement Progression Trend Charts (`lib/ui/body.dart`):**
  - Integrated interactive FlChart progression curves in the *Size & Measures* tab (`_MeasurementTrendsCard`) for visualizing long-term physical transition metrics.
  - Multi-metric selector supporting Waist-to-Hip Ratio (WHR), Bust & Ribcage (dual curves), Waist & Hips (dual curves), Weight, and Lower Body (Thigh & Calf).
  - Live baseline vs current comparison cards showing net change ($\Delta$), touch tooltips with dates, and smooth gradient area curves.
- **Interactive Visual Injection Site Map & Tissue Rest Heatmap (`lib/ui/site_map.dart` & `lib/ui/sheets.dart`):**
  - Integrated 2D anatomical silhouette body map with dual-perspective views (Front for arms, abdomen, thighs; Back for gluteal/buttocks).
  - Intelligent tissue rest status indicators displaying days since last injection, color-coded health badges ("Resting" vs "Ready"), and celestial suggested site highlight.
  - Direct toggle integration into dose logging modal (`DoseSheet`) and standalone rotation overview in Settings (`SiteRotationSheet`).

---

## [1.10.2] - 2026-10-31

### Added
- **Multi-Standard Shoe Size Calculator & Tracking (`lib/models.dart` & `lib/ui/body.dart`):**
  - Integrated Foot Length (*Panjang Telapak Kaki*) measurement and dual-standard **Shoe Size Calculator** (`calculateShoeSize`) converting foot length into EU/ID (e.g. `39`), US Women's (e.g. `8.5`), US Men's (e.g. `7`), and UK sizing.
  - Added dedicated Shoe Size metric tile to the Estimated Clothing Fit grid in the *Size & Measures* tab.
  - Added live shoe size preview banner in the measurement entry sheet with manual shoe size override support.
  - Guaranteed 100% backward-compatibility for existing measurements stored on device and Cloud Firestore.

---

## [1.10.1] - 2026-10-31

### Added
- **Lower Body Measurements & Sizing (`lib/models.dart` & `lib/ui/body.dart`):**
  - Added support for lower body measurement tracking: Thigh (*Paha*), Calf (*Betis*), and Inseam (*Panjang Kaki*).
  - Enhanced pants sizing calculator (`bottomSize`) with automatic inseam length notation (e.g., `27–28 (S) / L30`).
  - Implemented 100% backward-compatibility ensuring existing cloud and local measurement records seamlessly load with zero errors.

### Fixed
- **Home Screen Profile Sync Discrepancy (`lib/ui/home.dart`):**
  - Synchronized home screen greeting and avatar with `displayNameProvider` and `UserAvatar`, resolving the issue where home screen displayed username handle and fallback letter instead of user's custom nickname and uploaded profile picture.
  - Hardened timestamp deserialization (`_d`) in `lib/models.dart` supporting multiple date representations (Timestamp, DateTime, String ISO, and Map).

---

## [1.10.0] - 2026-10-31

### Added
- **Body Measurements & Clothing Sizing Calculator (`lib/models.dart` & `lib/ui/body.dart`):**
  - Integrated smart body measurements tracking with dual-unit support (cm and inches) for bust, underbust, waist, hips, shoulder, weight, and height.
  - Implemented accurate **Bra & Chest Size Calculator** (`calculateBraSize`) displaying dual standard sizing (US/UK e.g., 34C and EU/ID e.g., 75C), full cup ladder (AA through G+), and snug/comfort sister size recommendations.
  - Implemented estimated clothing size calculations for Top/Shirt sizing (XS to XXL), Bottom/Pants sizing (waist inch equivalent 26–35+), and Waist-to-Hip Ratio (WHR).
  - Added interactive measurement modal bottom sheet (`MeasurementSheet`) with live interactive bra size preview and history management with deletion and edit support.
- **Native Android Bilingual Home Screen Widgets (`android_widget/` & `lib/widget_sync.dart`):**
  - Integrated native Android home screen widgets for HRT Duration (`HrtWidget.kt`), Therapy Schedule (`ScheduleWidget.kt`), and Level Curves (`LevelWidget.kt`) with full bilingual string support (`res/values/lunera_widget_strings.xml` and `res/values-in/lunera_widget_strings.xml`).
  - Added dynamic language sync via `widget_sync.dart` transmitting active language preference (`lang`) to SharedPreferences so home screen widgets dynamically match the app's selected language.
- **Biometric Security & Authentication (`lib/lock.dart` & `lib/ui/security_page.dart`):**
  - Added biometric fingerprint and face unlock via `local_auth` (`Lock.instance.bioAvailable()` and `Lock.instance.authBio()`) alongside existing cloud-synced PIN security.
  - Added configurable auto-lock delay selector (Immediately, 1 minute, 5 minutes) and `sessionUnlocked` persistence preventing unnecessary re-locks on locale rebuilds.

### Changed
- **High-Performance Global Translation Architecture (`lib/l10n.dart` & `lib/l10n_id.dart`):**
  - Re-architected localization into a centralized, reactive translation engine (`L10n` with `tr()`) featuring singular/plural interpolations (`{0?day|days}`) and reactive rebuilds via `langProvider`.
  - Expanded comprehensive English-to-Indonesian dictionary in `lib/l10n_id.dart` with over 430 curated entries covering all user flows, medical routes, notification alerts, profile settings, and dialogs.

---

## [1.9.0] - 2026-10-31

### Added
- **Web Showcase Celestial Panorama Banner (`docs/index.html` & `docs/style.css`):**
  - Integrated a panoramic banner showcase presenting the brand identity, core therapeutic pillars, and nocturnal lake landscape.
  - Locked the web landing page to the app's unified **Celestial Midnight & Pastel** signature aesthetic (`#0B0D21` canvas, `#16193E` velvet midnight cards, and pastel accent palette), removing generic light mode toggles.

### Fixed
- **Comprehensive Bilingual Localization Audit & Leak Elimination:**
  - Audited the entire Flutter codebase to eradicate all language leakages (*misslanguage*) between English (default) and Indonesian across all screens:
    - **Home Screen (`lib/ui/home.dart`)**: Localized therapy status indicators ("Overdue", "Today", "Next 7 days", "Done", "Day off", relative overdue/remaining counters, and alert cards).
    - **Calendar & Schedule (`lib/ui/calendar.dart`)**: Dynamic date header formatting respecting `AppLocale.code` and localized tab navigation.
    - **Levels & Simulation (`lib/ui/levels.dart`)**: Localized target band indicators ("In range", "Below target", "Above target"), target configuration dialogs, and timeline ranges.
    - **Physical Journal & Mood (`lib/ui/journal.dart` & `lib/ui/body.dart`)**: Fully localized filter tabs, quick mood check-in banners, body transition cards, and note prompts.
    - **Supplies & Inventory (`lib/ui/supplies.dart`)**: Localized supply cards, generic types (Syringe, Alcohol wipe, Needle, Gloves, Bandage), refill warnings, and modal sheets.
    - **History & Logging (`lib/ui/history.dart` & `lib/ui/sheets.dart`)**: Localized administration route options, time selectors, confirmation alerts, and undo actions.
    - **Data & Security (`lib/ui/data_page.dart` & `lib/ui/auth.dart`)**: Bilingual error toasts, Firebase Auth feedback messages, and import/export prompts.
- **Dynamic Date & Locale Parsing:**
  - Eliminated static `'id'` locale parameters in `DateFormat` calls across `calendar.dart`, `levels.dart`, `journal.dart`, and `history.dart` in favor of dynamic `AppLocale.code`.
- **System Notifications & Android Widget Sync:**
  - Dynamic bilingual notification scheduling and home screen widget summaries reflecting active user language preferences.

---

## [1.8.0] - 2026-10-31

### Added
- **Unified Signature "Celestial Midnight & Pastel" Theme (`lib/theme.dart`):**
  - Consolidated application visual architecture into an iconic, proprietary signature theme combining deep atmospheric midnight lake canvas (`#0B0D21`) and velvet midnight card surfaces (`#16193E`).
  - Infused tender Celestial Pastel palette accents across key user touchpoints:
    - **Moonlight Lilac (`#D8B4FE`)**: Hero countdown banners, highlighted dose cards, and active releases.
    - **Rose Quartz Mist (`#FBCFE8`)**: Emotional mood check-ins and body transformation logs.
    - **Sage Cloud Mint (`#A7F3D0`)**: Taken dose indicators, schedule compliance, and safe inventory stock.
    - **Periwinkle Twilight (`#BAE6FD`)**: Pharmacokinetic level simulation curves, lab result markers, and calendar dots.
    - **Warm Butter Glow (`#FEF08A`)**: Friendly supply reminders and gentle notifications.
- **Bespoke Phase Accents System:**
  - Redesigned Appearance settings to highlight the signature aesthetic alongside customizable celestial Phase Accents (*Celestial Lilac & Mint*, *Rose Quartz & Peony*, *Lagoon Mint & Sky*, *Solstice Sunset & Gold*).

---

## [1.7.0] - 2026-10-31

### Added
- **In-App Version Changelog Viewer (`lib/ui/app_changelog.dart`):**
  - Integrated offline changelog bottom sheet modal (`showAppChangelogSheet`) accessible directly from Settings and More dashboards.
  - Release history tracking from v1.7.0 down to v1.0.0 with categorical change tags (**Added**, **Changed**, **Fixed**), current version badges (**LATEST** / **TERBARU**), and complete bilingual (English & Indonesian) support.
- **Reactive Update Notification & State Management (`availableUpdateProvider`):**
  - Added Riverpod notifier provider (`availableUpdateProvider`) dynamically tracking GitHub release status across the application.
  - Interactive "NEW" badge indicator displayed on the "Check for Updates" tile when a newer release is published on GitHub, displaying transition versions (`v1.7.0 ➔ v1.7.1`).
  - Automated startup check with `UpdateCheckerService.checkAndNotify(ref, context: context)`.

### Changed
- **Revamped Settings Dashboard & Multilingual Localization:**
  - Modernized Settings structure with a unified **About & Support** section featuring "Check for Updates", "Version Changelog", "GitHub Repository", and "Medical Disclaimer".
  - Refactored entire Settings interface to utilize dynamic runtime translation (`context.tr`) across English and Bahasa Indonesia.

### Fixed
- **CI/CD Pipeline & Gradle Build Resilience:**
  - Added Google Cloud Maven Central mirror (`https://maven-central.storage-download.googleapis.com/maven2/`) in Android `build.gradle.kts` and `settings.gradle.kts` to eliminate HTTP 429 rate limit errors.
  - Integrated `gradle/actions/setup-gradle@v4` with build cache and a 3-attempt retry loop on release APK compilation in `.github/workflows/release.yml`.

---

## [1.6.0] - 2026-10-30

### Added
- **In-App Animated Lake Splash Screen (`SplashPage` & `AppRoot`):**
  - Atmospheric nighttime lake landscape with starry skies, mountain ranges, illuminated crescent moon, and water horizon reflections.
  - Multi-stage entrance animation: background scenery fade, tagline slide & fade (`GoogleFonts.cormorantGaramond`), subtle divider rule, and brand logo mark.
  - Smooth 500ms `AnimatedSwitcher` transition between splash screen and authentication gate once auth status is resolved (minimum 2.4s display).
  - Full localization support for both English (*"Every phase, your own."*) and Indonesian (*"Setiap fase, milikmu."*).
- **Celestial Orbit Ring Moon Icon (`_MoonPainter`):**
  - Enhanced vector moon logo with an elliptical orbital ring seamlessly rendered in front of and behind the crescent moon.
- **Lake Landscape Scenery Component (`LakeScene`):**
  - Integrated `LakeScene` with customizable moon rendering in `theme.dart`, replacing `NightScene` in `WelcomePage` for visual continuity.

---

## [1.5.0] - 2026-10-29

### Added
- **Cloud-Synchronized PIN Security Architecture:**
  - Streamlined security to focus on 6-digit PIN lock with salted SHA-256 cryptographic hashing.
  - PIN credentials automatically sync with your account via Cloud Firestore (`users/$uid/meta/security`).
  - Seamless multi-device support: logging in with the same account on a second device immediately restores the existing PIN without requiring re-setup.
  - Local security cache is securely cleared upon account sign-out.
- **English Default Localization (`lib/l10n.dart`):**
  - Set **English** as the primary default display language across the entire application.
  - Added language selector in **Settings > Appearance > Language / Bahasa** with full support for **Bahasa Indonesia**.
  - Integrated `flutter_localizations` with dynamic runtime switching across date formatters and interface elements.

---

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
