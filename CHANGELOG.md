# Changelog 📋

All notable changes to the **Lunera** personal health & therapy tracking application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-11-10

### Added
- **Major Milestone: Arcane Astral Redesign & System Overhaul:**
  - **Arcane Astral Design System (`lib/theme.dart`, `docs/style.css`):** Complete visual renaissance introducing a celestial midnight universe fused with Trans Pride palette tokens: Atmospheric Deep Indigo (`#17264D`), Midnight Slate (`#26334F`), Ice Blue (`#DDF6FF`), Lavender (`#B9A9E8`), Champagne Gold (`#E8D3A5`), Sky Cyan (`#5BC8E8` for Testosterone), Blush Pink (`#F1A4B8` for Estradiol), glowing astral halos, Cinzel decorative brand wordmark, Cormorant Garamond display headings, and Plus Jakarta Sans body typography.
  - **Dreamy Celestial Splash & Launch Experience (`lib/ui/splash.dart`, `lib/main.dart`, `android/app/src/main/res/`):** Full-screen starry night backdrop (`arcane_astral_bg.jpg`), glowing celestial crescent moon emblem with orbital rings, LUNERA wordmark, starlight diamond divider, and inspiring tagline `"YOUR JOURNEY, YOUR PACE."` with a smooth 1.5-second entrance cross-fade, paired with a solid `#171A35` cold-launch theme.
  - **Authentic Celestial Iconography Suite (`assets/icons/celestial/`, `assets/icons/`, `lib/ui/shell.dart`, `docs/images/icons/`):** 42 authentic celestial sprite icons sliced to 160×160 square transparent canvases with symmetrical padding, powering the bottom navigation dock, feature highlights, and lore storytelling.
  - **Ornate Celestial Profile Avatar Frame (`assets/images/avatar_frame_celestial.png`, `lib/profile.dart`):** Circular avatar framing with golden crescent moon crest, astral filigree, hanging stars, amethyst lotus accents, and centered auto-scaling overlays across Home, More, and Profile headers.
  - **Decoy Calculator Lock & Wall o' Pay Keypad (`lib/ui/lock_screen.dart`, `lib/lock.dart`):** Covert functional calculator camouflage concealing the PIN lock screen, paired with Wall o' Pay-inspired 72×72 circular keypad buttons, gold starlight borders (`#E8D3A5`), 14px glowing starlight indicators with 180ms easeOutCubic transitions, and discreet masked push notifications.
  - **Combination Medication Support (`lib/models.dart`, `lib/ui/sheets.dart`, `lib/sim.dart`, `lib/ui/history.dart`):** Per-dose `secondaryDose` overrides in `DoseLog`, dual dosage inputs in `DoseSheet`, inline "+ Add combination medication" configuration, and dual-curve pharmacokinetic simulation for combination therapies.
  - **Guided Calm Injection Assistant (`lib/ui/guided_injection.dart`, `lib/ui/sheets.dart`):** Step-by-step injection ceremony with breathing circles, countdown timers, angle guides, and responsive scrollable layouts.
  - **Restock Pickup Assistant (`lib/ui/supplies.dart`):** Smart logistics assistant generating Hold-at-Location courier templates and discreet pharmacy pickup notes.
  - **Immersive "About Lunera" Sheet (`lib/ui/about_sheet.dart`):** Full-fledged modal sheet presenting Lunera's guiding philosophy, circled cosmic MoonLogo, 4 Lore Pillars (Moon Phase Rhythms, Celestial Sanctuary, Guiding Star, Arcane Astral Canvas), core architectural principles, and open-source changelog access.

### Changed
- **Comprehensive UI/UX Streamlining Across All Application Hubs:**
  - **Home Dashboard (`lib/ui/home.dart`):** Compact hero layout with precision radial cycle dial, overdue alert banners, quick mood logging, and direct calendar bridge links.
  - **Hormone Levels & PK Simulations (`lib/ui/levels.dart`):** Streamlined minimal feed cards with sparklines and target status badges, moving deep analytical charts and period filters to the full `HormonePage`.
  - **Dose Logging & Injection Site Selection (`lib/ui/sheets.dart`):** Replaced bulky interactive body maps in `DoseSheet` ("Catat Suntikan" & "Ubah Catatan") with lightweight, responsive site chips (`Wrap` of `FilterChip`), reserving the full 2D interactive anatomical silhouette map for `SiteRotationSheet`.
  - **Settings & More Hub (`lib/ui/settings_page.dart`, `lib/ui/more.dart`):** Removed redundant appearance cards, priority-ordered settings sections, streamlined hormone units into compact choice chips, elevated contrast on all subtitles (`Pastel.mist`), and tactile haptic feedback across all controls.
  - **Calendar & Timeline (`lib/ui/calendar.dart`, `lib/ui/history.dart`):** Arcane Astral weekly day selector card with instant "Today" shortcut, daily completion chips, serene rest-day empty states, and high-contrast log histories.
- **Revamped Landing Page & Web Showcase (`docs/`):**
  - Modernized showcase with dual-layer smartphone hardware chassis architecture (Phone A: Home Screen, Phone B: Levels Screen) with Wall o' Pay-style metallic titanium rims, OLED display bezels, diagonal sheen reflection, and canonical in-app demo data.
  - Full-width solid acrylic midnight surface with deep backdrop blur and 2.5px radiant celestial gold horizon separators for both header and footer.
  - Direct APK download integration pointing to official GitHub Releases.

### Fixed
- **Biometric & PIN Lock Lifecycle Stabilization (`lib/lock.dart`, `lib/ui/lock_screen.dart`):** Eliminated OS prompt collisions during screen-off (`stickyAuth: false`), added auto-lock suppression (`suppressLockDuring`) with a 3-second grace window during photo picking and file backup/restore, and sub-second debounce protection.
- **Seamless Page Route Transitions (`lib/theme.dart`):** Configured transparent transition scrims and backgrounds, preventing the background wallpaper from flashing opaque purple during route navigation.
- **Layout Overflow Resilience (`lib/ui/site_map.dart`, `lib/ui/guided_injection.dart`, `lib/ui/levels.dart`):** Wrapped titles, technique chips, site rotation chips, and health status indicators in `Wrap`, `Expanded`, and ellipsis to eliminate RenderFlex overflow on narrow devices and localized text.

## [1.11.50] - 2026-11-09

### Added
- **Ornate Celestial Profile Avatar Frame (`assets/images/avatar_frame_celestial.png`, `lib/profile.dart`):**
  - Integrated an enchanting fantasy circular avatar frame featuring a golden crescent moon crest, starry astral filigree, delicate hanging stars, amethyst lotus flowers, and a radiant star gem brooch.
  - Enhanced `UserAvatar` with automatic frame overlay scaling (`size * 1.35`) and centered alignment, framing both custom profile photos and fallback initial avatars seamlessly across Home, More, and Profile pages.
  - Harmonized ambient glow in More page hero profile card by removing harsh static borders and allowing the celestial frame to shine naturally with warm honey gold and amethyst halos.

## [1.11.49] - 2026-11-09

### Changed
- **Enhanced More and Settings UI (`lib/ui/more.dart`, `lib/ui/settings_page.dart`):**
  - **Expansive Feature Hub Header**: Updated `More` title to full `display(40)` Cormorant Garamond typography.
  - **Elevated Typography Contrast**: Replaced low-opacity muted subtitle text throughout all settings and hub tiles with high-contrast `Pastel.mist` (85% opacity) and crisp white titles for effortless legibility on dark velvet surfaces.
  - **Tactile Haptic Feedback**: Embedded subtle haptic pulses across all interactive controls: navigation tiles, tab selectors, reminder switches, unit choice chips, site rotation buttons, and cloud backup actions.

## [1.11.48] - 2026-11-09

### Changed
- **Streamlined Calendar & History UI (`lib/ui/calendar.dart`, `lib/ui/history.dart`):**
  - **Weekly Navigator Card**: Anchored the week selector and month navigation bar inside a dedicated Arcane Astral card (`cardBox`) with glowing day indicators, subtle today borders, and an instant "Today" shortcut button to jump back when browsing past or future dates.
  - **Selected Day Status Header**: Added clear daily completion badges (`Completed` in mint, `{0} pending` in amber) beside the localized date header.
  - **Serene Empty State**: Replaced bare empty text with a peaceful Arcane Astral night-sky card (`iconBadge(Icons.nightlight_round, Pastel.lilac)`) indicating rest days with comforting guidance.
  - **History & Log Tile Refinements**: Elevated typography contrast on dosage log cards (`Colors.white` title, `Pastel.mist` subtitle), styled empty history with an icon badge, and added tactile haptic feedback (`HapticFeedback.selectionClick`, `lightImpact`, `mediumImpact`) across tab changes, date taps, week navigation, and log actions.
- **Indonesian Localization (`lib/l10n_id.dart`):**
  - Added translations for `Today, {0}`, `Previous week`, `Next week`, `Completed`, `{0} pending`, `No doses scheduled`, `Enjoy your rest day or log a dose manually if needed.`, `No history entries yet`, and `Doses you log will show up here with full administration history.`.

## [1.11.47] - 2026-11-09

### Changed
- **Decluttered & Streamlined Levels Screen UI (`lib/ui/levels.dart`):**
  - Expansive header layout: separated `Levels` title onto its own line with Cormorant Garamond typography and placed `Add Lab Result` (with glowing `C.peony`) and `Insights` into a balanced dual action bar.
  - Eliminated duplicate hormone cards: prevented hormones with active PK simulations from redundantly rendering standalone lab summary cards beneath their simulation panels, reserving `Blood Tests & Lab Markers` exclusively for non-simulated blood markers.
  - Simplified compact `LevelPanel`: streamlined the primary chart cards by tucking calibration options, retrospective date paginators, and deep clinical disclaimers into the dedicated full-page `HormonePage`, keeping the main dashboard clean and focused.
  - Added target range indicator badges (`In range`, `Below target`, `Above target`) and latest lab result quick info directly inside the simulation panel header.
  - Elevated card styling and contrast across lab result histories and added tactile haptic feedback (`HapticFeedback.selectionClick`, `lightImpact`, `mediumImpact`) across chart controls, time range pill tabs, date pickers, and lab sheets.
- **Indonesian Localization (`lib/l10n_id.dart`):**
  - Added translations for `Add Lab Result`, `Blood Tests & Lab Markers`, `No level data yet`, `Lab Results History`, `View lab history & calibrate`, `Latest lab: {0} {1} ({2})`, `estimated`, and `target`.

## [1.11.46] - 2026-11-09

### Changed
- **Streamlined Home Dashboard (`lib/ui/home.dart`):**
  - Eliminated visual clutter and redundant slot repetition: removed duplicate today's slot tiles beneath active dose dials and decommissioned bottom 7-day schedule list in favor of an elegant, focused bridge link to the dedicated Calendar tab.
  - Replaced expansive missed dose tiles with a sleek, high-priority `_OverdueAlertBanner` paired with a focused `_showOverdueSheet` for catching up on or skipping missed doses in one place.
  - Compacted supply alert notifications into an informative, single-line alert banner with direct access to the Supplies tab.
- **Enhanced Contrast & Visual Accessibility (`lib/ui/home.dart`, `lib/ui/journal.dart`, `lib/ui/calendar.dart`):**
  - Elevated secondary text and icon opacities across dark velvet cards using `Pastel.mist` and `Pastel.cream` with high contrast ratios for effortless legibility.
- **Tactile Haptic Feedback & Micro-Interactions:**
  - Added subtle haptic pulses across dose logging (`HapticFeedback.lightImpact`), dial interactions, quick mood logging, skip confirmations, and bottom navigation tab transitions (`HapticFeedback.selectionClick`).
- **Hero Avatar Transition:**
  - Connected the Home screen avatar to the Profile page using a smooth Hero animation transition.

## [1.11.45] - 2026-11-09

### Changed
- **Supplies Screen Header & Dual Action Bar Relocation (`lib/ui/supplies.dart`):**
  - Restructured the header of `SuppliesPage` by moving the action buttons out of the title row, giving the `Supplies` title expansive breathing room with its classic Cormorant Garamond typography.
  - Positioned the primary `Add Supply` button (`FilledButton.icon` in glowing amethyst `C.peony`) and secondary `Pickup Assistant` button (`OutlinedButton.icon` with delicate `#D6B277` starlight border and frosted indigo backing) into a balanced, dual-button action row immediately below the header.
  - Updated Indonesian localization with dedicated keys for `Add Supply` (`Tambah Stok`).

## [1.11.44] - 2026-11-09

### Changed
- **Web Landing Page Architecture & In-App UI Revamp (`docs/index.html`, `docs/style.css`, `docs/script.js`):**
  - **Removed Brand Identity Section:** Decommissioned the dedicated `#brand` section and its navigation anchor, streamlining the landing page experience towards core clinical features, interactive showcases, and downloads.
  - **Revamped Hero Mockup to Match In-App Home Screen (`lib/ui/home.dart` & `lib/ui/shell.dart`):**
    - Redesigned the hero mobile mockup from the ground up to faithfully reflect Lunera's actual UI components.
    - Added the personalized greeting header ("Good evening, Lunera"), daily wellness motto ("Take a moment for yourself today."), real-time dynamic date, quick action add button (`+`), and glowing circular `UserAvatar`.
    - Transformed the medication card into Lunera's authentic `DoseCard` structure: dual-column layout with a 100x100 precision dial on the left (completed days in mint, active cycle in lavender, idle days pudar, center countdown), alongside therapy dosage badge (`7.5 mg`), recurrence tag (`Every 7 days`), and dynamic site rotation hint (`next: Right thigh`).
    - Added full-fidelity action buttons: primary "Log injection" stadium button paired with the "Guided Calm Injection" companion button.
    - Updated the floating Arcane Astral dock to match the exact in-app tab order: *Levels*, *Calendar*, raised glowing *Home* center star, *Supplies*, and *More*.
  - **Dynamic Time-of-Day Greeting (`docs/script.js`):** Mockup greeting automatically adapts between "Good morning,", "Good afternoon,", and "Good evening," according to the visitor's local system time.

### Added
- **Featured Injection Site Map & Guided Calm Injections on Web Showcase (`docs/index.html`, `docs/style.css`):**
  - Added dedicated clinical feature cards for **Interactive Injection Site Map & Tissue Rest** and **Guided Calm Injections** in the core Features Grid.
  - Added a new interactive **Site Rotation & Tissue Rest** preview card in the Showcase section displaying site recovery metrics and optimal injection rotation recommendations.

## [1.11.43] - 2026-11-09

### Added
- **"About Lunera" Immersive Arcane Astral Modal Sheet (`lib/ui/about_sheet.dart`, `lib/ui/settings_page.dart`, `lib/ui/more.dart`):**
  - Re-architected "About Lunera" from a basic 3-line alert dialog into a rich, full-fledged draggable modal bottom sheet inspired by Wall o' Pay.
  - **Brand Header Card:** Displays the illuminated celestial crescent moon emblem (`MoonLogo(size: 76)`), Cinzel wordmark, version tag (`v1.11.43 • Release`), and italicized brand tagline.
  - **Mission / Lore Quote Card:** Features a highlighted blockquote with starlight gold quotes celebrating mindful hormone tracking and body harmony.
  - **4 Celestial Lore Pillars:** Detailed cards explaining the philosophy behind Lunera's identity—*The Moon Phase Rhythms*, *The Celestial Sanctuary*, *The Guiding Star*, and *The Arcane Astral Canvas*.
  - **Core Principles:** Clearly breaks down Offline-First Architecture, Biometric & Privacy Guard, Clinical Pharmacokinetics, and Smart Site Rotation.
  - **Medical Disclaimer & Project Metadata:** Outlines responsible clinical guidance and provides clickable links to the open-source repository and direct access to the Version Changelog sheet.
  - Integrated into both `SettingsPage` (under About & Support) and `MorePage` (under System).

## [1.11.42] - 2026-11-09

### Fixed
- **Bilingual Leak Prevention & Full Localization Audit (`lib/l10n_id.dart`, `lib/ui/`):**
  - Resolved English string leaks in Indonesian language mode by adding 40 missing translations across Settings, Profile, Body Measurements, and Home (e.g. `'Preferences'`, `'Reminders & Privacy'`, `'Sample Data'`, `'Home Screen Widgets'`, `'Active'`, `'Sign out'`, `'Height (cm)'`, `'Notes (optional)'`, and disclaimer texts).
  - Fixed malformed plural key `'{0?d} ago'` in Home dial card (`lib/ui/home.dart`) by updating it to `'{0?day|days} ago'` with full singular/plural support in both English and Indonesian.
  - Fixed double-escaped newlines in `lib/l10n_id.dart` that prevented data merge and courier pickup tip strings from matching their lookup keys.
  - Wrapped previously hardcoded labels in `tr()`: Data header and panel tags (`lib/ui/data_page.dart`), profile error toast and nickname hint (`lib/ui/profile_page.dart`), and signup text field labels (`lib/ui/auth.dart`).
  - Restored `Every Phase, Your Own.` brand tagline on `SplashPage` (`lib/ui/splash.dart`) to ensure visual and test suite consistency.

## [1.11.41] - 2026-11-09

### Changed
- Removed the forced 2.4-second splash screen delay on app launch. The splash screen now only appears while Firebase Auth is loading, then immediately transitions to the main content.
- Simplified `SplashPage` from 262 lines (dual animation controllers, sequenced intro, pulse glow, starlight loading bar) to a ~75-line static `StatelessWidget` with logo halo and brand name — appropriate for its now sub-second display time.
- Extracted `_NavBar` widget from `Shell` for clearer separation of navigation bar rendering.
- Extracted `_ExitDialog` widget from `Shell` for cleaner exit confirmation dialog ownership.

## [1.11.40] - 2026-11-09

### Changed
- **Revamped Arcane Astral Splash & Loading Screen (`lib/ui/splash.dart`, `lib/main.dart`):**
  - Replaced the legacy vector lake/mountain splash screen with an enchanting celestial nocturnal loading sequence featuring the Arcane Astral cosmic backdrop (`arcane_astral_bg.jpg`) and atmospheric scrims.
  - Added an illuminated circular orbital aura with dual-radial gradients (amethyst and celestial honey gold) and subtle breathing pulse animation.
  - Featured the Cinzel brand wordmark (`appName`), gold starlight ornament (`✦`), and Cormorant Garamond tagline (`tr('Every Phase, Your Own.')`).
  - Implemented an animated starlight shimmer loading bar with glowing pill gradient for seamless loading feedback.
  - Updated `AuthGate` in `lib/main.dart` so intermediate loading states render the celestial `SplashPage` rather than a blank scaffold with a raw spinner.
- **Updated In-App Celestial Crescent Moon Emblem (`assets/images/lunera_celestial_logo.png`, `lib/theme.dart`):**
  - Integrated the new high-resolution celestial crescent moon emblem with starry interior, golden crescent contour, and orbital rings for all in-app logo usages (`MoonLogo`, `WelcomePage`, `SignInPage`, `LockScreen`, and settings dialogs).
  - Preserved the existing Android home screen launcher icons (`ic_launcher.png`) untouched per user instructions.

## [1.11.39] - 2026-11-08

### Changed
- **Web Landing Page & Showcase Arcane Astral Overhaul (`docs/index.html`, `docs/style.css`, `docs/script.js`):**
  - Revamped the public landing page and GitHub Pages showcase to fully match Lunera's Arcane Astral design system.
  - Replaced legacy flat crescent SVG with the celestial planetary moon emblem (`docs/images/logo.png`, `docs/images/icon.png`) with luminous halo filter.
  - Integrated the 3-tier typography system: **Cinzel** for the brand wordmark, **Cormorant Garamond** for hero titles, display headers, greetings, and cycle numbers, and **Manrope** for clinical body, cards, and specifications.
  - Styled cards with nocturnal glassmorphism, thin celestial gold borders (`#D6B277`), and atmospheric background scrims over `arcane_astral_bg.jpg`.
  - Added an interactive mobile-style mockup featuring the signature floating navigation dock with 5 custom celestial icons (`nav_calendar.png`, `nav_levels.png`, `nav_home.png`, `nav_supplies.png`, `nav_more.png`) and the enlarged frameless central Beranda star.
  - Updated the brand visual identity and color palette specimen to showcase Celestial Gold, Nocturnal Midnight, Surface Indigo, Pastel Lavender, and Mint.

## [1.11.38] - 2026-11-08

### Changed
- **Revamped Celestial Exit & Application Update Cards (`lib/ui/shell.dart`, `lib/update_checker.dart`):**
  - Revamped the exit confirmation modal dialog (`_showExitDialog` in `lib/ui/shell.dart`) into an Arcane Astral celestial card featuring velvet midnight surface (`C.deepCard`), delicate starlight gold borders (`#D6B277`), a glowing halo power emblem with dual-radial gradients, soft reassuring copy, and refined frosted/glowing action buttons.
  - Upgraded the application update dialog (`showUpdateDialog` in `lib/update_checker.dart`) into an Arcane Astral release announcement card featuring glowing starburst badge, version transition chip (`vCurrent ➔ vLatest`), velvet scrollable release notes container with custom scrollbar, and glowing `Update Now` download action button.

## [1.11.37] - 2026-11-08

### Changed
- **Revamped Celestial PIN Security & Lock Screen (`LockScreen`, `PinPad`, `_PinFlow` in `lib/ui/lock_screen.dart`):**
  - Replaced legacy `NightScene` in PIN unlock and PIN setup screens with the celestial Arcane Astral backdrop (`AuthScene`) featuring atmospheric starlight scrims.
  - Upgraded `PinPad` with glowing animated celestial orb indicators (scaling up to 16px with lilac blur glow when entered).
  - Redesigned circular keypad keys with delicate frosted-glass borders, tactile haptic response, starlight highlight splashes, and international letter markings (ABC, DEF, etc.).
  - Added soft glowing halo container around the brand moon emblem and streamlined error message badges with warning icons.

## [1.11.36] - 2026-11-08

### Changed
- **Arcane Astral Celestial Authentication Background (`AuthScene` in `lib/ui/auth.dart`):**
  - Replaced legacy `LakeScene` and `NightScene` in authentication views (`WelcomePage`, `SignInPage`, and `SignUpPage`) with the high-resolution Arcane Astral celestial artwork (`assets/images/arcane_astral_bg.jpg`).
  - Implemented `AuthScene` with deep atmospheric gradient scrims and contrast compensation, ensuring optimal typography readability, form accessibility, and seamless visual consistency with Lunera's nocturnal sanctuary design language.

## [1.11.35] - 2026-11-08

### Changed
- **Arcane Astral Typography Hierarchy (`lib/theme.dart`, `lib/ui/splash.dart`):**
  - Integrated **Cinzel** for the Lunera brand logo, wordmarks, and splash screen brand identity.
  - Applied **Cormorant Garamond** across decorative headings, hero numbers, and page titles (`display()`).
  - Switched the entire Android UI body, input fields, labels, and chips to **Manrope** (`manropeTextTheme`) for clinical clarity.
- **New Celestial Crescent Moon App Icon & Splash Screen Artwork (`android/app/src/main/res/`, `assets/images/`, `lib/theme.dart`, `web/`, `docs/`):**
  - Updated all Android launcher mipmap icons (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi) to the new high-resolution celestial crescent moon emblem with orbital rings.
  - Updated web icons, favicons, and documentation brand images.
  - Upgraded in-app `MoonLogo` to render the celestial emblem across Splash, Lock Screen, Welcome, and About dialogues with graceful vector fallback.

## [1.11.34] - 2026-11-08

### Changed
- **Subtle Celestial Gold Card Borders & Slimmer Navbar Dock (`lib/theme.dart`, `lib/ui/shell.dart`, `lib/ui/more.dart`):**
  - Updated card border styling (`cardBox`, `AppCard`, and hero profile card) with a refined, delicate gold starlight tint (`#D6B277`).
  - Slimmed down the floating navbar capsule: reduced outer vertical padding, reduced inner padding, set a sleeker 26px corner radius, and proportioned icons for a more compact and elegant profile.

## [1.11.33] - 2026-11-08

### Changed
- **Frameless Full Celestial Home Navbar Icon (`lib/ui/shell.dart`):**
  - Removed artificial container border, background, and double-ring frame from the center Beranda (Home) button.
  - Rendered the celestial 8-point astrological star artwork full-size at 56x56 with active scaling and ethereal gold/peony halo drop-shadows.

## [1.11.32] - 2026-11-08

### Changed
- **Custom Celestial Navbar Icons & Prominent Center Home Button (`lib/ui/shell.dart`, `assets/icons/`, `pubspec.yaml`):**
  - Integrated high-resolution sliced celestial icon assets across all navigation tabs (Line Chart for Levels, Celestial Calendar for Calendar, Medication Pill for Supplies, and Profile Silhouette for More).
  - Redesigned and enlarged the center Beranda (Home) button into a 58px floating circular orb (elevated by 12px) with gold & amethyst halo glows, inspired by the center-docked action button from Pay o' Wall.
  - Added graceful asset fallback handling for headless test runners and widget test suites.

## [1.11.31] - 2026-11-08

### Added
- **Arcane Astral Wallpaper Backdrop (`assets/images/`, `lib/theme.dart`, `pubspec.yaml`):**
  - Integrated full-bleed Arcane Astral celestial artwork featuring an astrological clockwork dome, crescent moon, and temple sanctuary.
  - Layered with an atmospheric dark scrim gradient (0.58 to 0.85 opacity) ensuring cards, dials, and text retain optimal contrast and eye comfort.
  - Registered asset bundle directory in `pubspec.yaml` with graceful fallback handling for headless test environments.

## [1.11.30] - 2026-11-08

### Changed
- **Unified All-Dropdown Therapy Form Experience (`lib/ui/sheets.dart`):**
  - Fully transformed therapy category, administration route, injection method, patch unit type, combination categories, and repeat schedule into cohesive, styled `DropdownButtonFormField` controls.
  - Eliminated visual clutter and vertical scroll sprawl across the modal sheet, replacing multi-line wrapping choice chips with tidy, single-row inputs.
  - Converted custom pharmacokinetic simulation profile selectors into styled dropdowns when custom formulas are used.
  - Added Indonesian localization keys for therapy categories, injection methods, and repeat schedule definitions.

## [1.11.29] - 2026-11-08

### Changed
- **Streamlined Therapy Sheet with Active Compound Dropdown (`lib/ui/sheets.dart`):**
  - Replaced sprawling multi-row choice chips for active compounds with a clean, single-line `DropdownButtonFormField`.
  - Retained fast one-tap category chips at the top while dynamically updating the active compound dropdown options.
  - Automatically hid redundant pharmacokinetic (`pk`) simulation profile chips when a standard preset compound is selected, dramatically reducing vertical form clutter.
  - Applied the same streamlined single-line dropdown to secondary active compounds in combination medications.

## [1.11.28] - 2026-11-08

### Added
- **Standardized Active Compound Presets (`lib/models.dart`):**
  - Introduced `CompoundPreset` catalog (`compoundPresets`, `compoundsFor()`, `compoundOf()`) providing predefined active chemical compounds and esters across Estradiol, Testosterone, Progesterone, and Anti-androgens / Blockers.
  - Added Anti-androgen / Blocker category (`blocker`) to therapy molecule classification and presets.
  - Extended `Therapy` model with optional `compound` and `secondaryCompound` attributes, fully serialized across JSON and Firestore backups.
- **Active Compound Picker & Brand Name Separation (`lib/ui/sheets.dart`):**
  - Added interactive active compound chips in `TherapySheet` displayed directly under category selection.
  - Selecting an active compound automatically configures standard administration routes, default simulation profile (`pk`), and initial product name.
  - Added secondary active compound chip selection for combination treatments (e.g., Cyclofem containing Estradiol cypionate and Medroxyprogesterone acetate).
  - Clarified separation between user-customized Product/Brand names (e.g. Progynova, Androcur, Utrogestan) and active pharmaceutical ingredients.
- **Bilingual Terminology & Localization (`lib/l10n_id.dart`):**
  - Added comprehensive Indonesian translations for all active chemical compounds, anti-androgen options, and form labels.
- **Unit Testing Suite (`test/models_test.dart`):**
  - Added comprehensive unit tests covering active compound catalog retrieval across all categories and serialization fidelity in `Therapy`.

## [1.11.27] - 2026-11-08

### Changed
- **Home Header Refinements (`lib/ui/home.dart`):**
  - Removed the decorative heart symbol `(♡)` from the greeting banner to keep the user nickname clean.
  - Scaled user display name font size to 22pt with single-line truncation and added 12px right padding to prevent overlapping with header action buttons on compact screens.

## [1.11.26] - 2026-11-08

### Changed
- **Arcane Astral Profile Hero Card on More Page (`lib/ui/more.dart`):**
  - Redesigned the profile header into a centered cosmic hero card featuring a glowing celestial halo avatar, bold typography, identity subtitle, and top-right quick Settings gear action.
- **Direct Profile Navigation from Home Avatar (`lib/ui/home.dart`):**
  - Tapping the user avatar in the Home page header now navigates directly to `ProfilePage` for instant identity management.
- **Reordered Navigation Bar & Star Icon Assignment (`lib/ui/shell.dart`, `lib/repo.dart`):**
  - Swapped positions of Home and Levels in the floating navigation dock.
  - Beranda (Home) is now the prominent center button adorned with the 8-point astrological star (`CompassStarPainter`).
  - Levels is now positioned as tab 0 featuring clinical insights iconography (`Icons.insights_rounded`).
  - Updated default active shell tab to Home (index 2) and adjusted intra-app navigation links accordingly.

## [1.11.25] - 2026-11-08

### Changed
- **Compact Dose Cards & Prioritized Home Feed (`lib/ui/home.dart`):**
  - Re-engineered `DoseCard` into a compact, horizontal 100px dial card, reducing vertical height by over 50% while preserving cycle countdown, site recommendations, and direct logging actions.
  - Upgraded `DialPainter` and `HourDialPainter` with responsive tick scaling to render crisply at compact dimensions.
  - Restructured Home dashboard cards by clinical urgency and daily action priority:
    1. Supply and Expiry Alerts (`AlertsCard`)
    2. Missed / Overdue Doses (`section(tr('Missed'))`)
    3. Active Therapy Action Cards (`DoseCard`)
    4. Today's Scheduled Slots (`section(tr('Today'))`)
    5. Clinical Pharmacokinetics Trends (`WeekCard`)
    6. Daily Emotional Check-in (`MoodQuickCard`)
    7. Upcoming 7-Day Lookahead (`section(tr('Next 7 days'))`)

## [1.11.24] - 2026-11-08

### Changed
- **Unified Signature Aesthetic & Phase Accent Deprecation (`lib/ui/settings_page.dart`, `lib/theme.dart`):**
  - Consolidated app styling into the single bespoke **Arcane Astral** aesthetic, removing the redundant Phase Accent picker chips from Settings.
  - Redesigned the Appearance card in Settings with an elegant preview showcase highlighting the 5 core swatches of the Arcane Astral palette.
  - Locked `applyAccent` to permanently enforce the signature Mystical Amethyst and Celestial Honey Gold theme systemwide while preserving database backward compatibility.

## [1.11.23] - 2026-11-08

### Changed
- **Arcane Astral Floating Navigation & Compass Starburst (`lib/ui/shell.dart`, `lib/theme.dart`, `lib/ui/home.dart`):**
  - Transformed bottom navigation into a floating frosted glass pill dock with 32px rounded curvature, deep velvet starlight shadows, and starlight purple contour borders.
  - Introduced custom `CompassStarPainter` rendering an 8-point astrological celestial compass star for the center Levels tab with active starlight halo and cream highlights.
  - Polished Home screen hero greeting with delicate phase heart (`♡`), starlight subtitle (*"Take a moment for yourself today."*), and improved typography hierarchy.

## [1.11.22] - 2026-11-08

### Changed
- **Arcane Astral Hormone Trend & Clinical Visualizations (`lib/theme.dart`, `lib/ui/home.dart`, `lib/ui/levels.dart`, `lib/ui/journal.dart`):**
  - Introduced `hormoneColor(hormoneId)` theme token mapping Estradiol (E2) to Mystical Amethyst (`#9E7CC6`), Progesterone (P4) to Celestial Honey Gold (`#F1BA79`), and Testosterone to Periwinkle Astral Sky (`#B5DCFD`).
  - Upgraded Home `WeekCard` to **Hormone Trend** with multi-hormone concurrent curve rendering, color-coded legend, starlight now-line, and one-tap quick jump to the Levels tab.
  - Modernized hormone sparklines and PK simulation curves with smooth curved interpolation and gradient shading.
  - Harmonized clinical target ranges and adherence indicators to Sage Astral Mint (`Pastel.mint`, `#8EE3C3`) for *"Within range"* and logged doses.
  - Updated journal `moodColor` to align with Arcane Astral warm amber highlights for joyful moods.

## [1.11.21] - 2026-11-08

### Changed
- **Arcane Astral Design System & Color Palette (`lib/theme.dart`):**
  - Transformed Lunera's primary color system to the bespoke **Arcane Astral** palette (*Fantasy • Classic • Sophisticated*).
  - Upgraded atmospheric canvas to Deep Astral Midnight (`#120E2E` – `#19143F`) and surfaces to Velvet Arcane Glass (`#201A4B`) with luminous starlight contours (`#45397A`).
  - Introduced **Mystical Amethyst** (`#9E7CC6`) as the signature primary accent alongside **Celestial Honey Gold** (`#F1BA79`) and **Moonlight Cream** (`#FCE3BD`).
  - Refined `Pastel` and `C` design tokens with full compliance for `C.surface`, `C.midnight`, `C.lavender`, `C.indigo`, and `C.moonlight`.
  - Enhanced `MoonLogo` with warm moonlight cream lunar body and arcane lilac orbit ring.

## [1.11.20] - 2026-11-08

### Added
- **Wall o' Pay-Inspired Care & Feature Hub (`MorePage`):**
  - Redesigned the 5th tab (`MorePage`) into a clean, purpose-driven Feature Hub organizing Lunera's health and therapy capabilities into distinct, thematic card sections with colored icon badges (`iconBadge`).
  - Added **Health & Journey** section grouping *Insights & Patterns*, *Body & Changes (Journal Physical Milestones)*, and *Site Rotation & Health (Anatomical Map & Tissue Resting Tracker)*.
  - Added **Care & Assistant Tools** section featuring *Guided Calm Injection* (interactive step-by-step calming injection procedure with breathing exercise and 30-second drying timer) and *Discreet Pickup Assistant* (Hold-at-Location courier address generator for privacy).
  - Added **System** section providing a single, clear entry point into the comprehensive *Settings* control center.
- **Unified Design System Components (`lib/theme.dart`):**
  - Introduced `AppCard`, `SectionHeader`, and `iconBadge` reusable components in `lib/theme.dart` matching Lunera's nocturnal velvet surface (`C.deepCard`), moonlight borders, and pastel accent highlights (`Pastel.lilac`, `Pastel.rose`, `Pastel.mint`, `Pastel.sky`, `Pastel.butter`).

### Changed
- **Comprehensive Settings & Control Center (`SettingsPage`):**
  - Re-architected `SettingsPage` to adopt Wall o' Pay's all-in-one settings structure, consolidating preferences and system controls without redundant sub-screens.
  - Integrated live **Security & Privacy Lock** card showing real-time App PIN & Biometric status, timeout duration, and decoy calculator indicator.
  - Integrated **Cloud Sync & Storage** section displaying live Firebase Cloud Firestore status, auto-sync indicator, and one-tap cloud backup creation.
  - Integrated **Manual Backup & Export** section with direct JSON backup file export & import (merge/replace options) and links to snapshot history.
  - Consolidated Preferences (Language), Appearance (Phase accents), Reminders & Notification Privacy (lockscreen masking), Therapy & Clinical units, and About & Support (version check with NEW badge, changelog, GitHub repo, medical disclaimer).

## [1.11.19] - 2026-11-08

### Fixed
- **Injection Site Map Layout & Modal Sheet Stability:**
  - Fixed an unconstrained horizontal layout assertion failure (`RenderFlex children have non-zero flex but incoming width constraints are unbounded`) inside `InjectionSiteMap` when embedding `PillTabs` within a parent `Row`.
  - Wrapped `PillTabs` in `Expanded` and set `MainAxisSize.min` on the rotation health summary pill to prevent layout crashes that caused UI thread freezes (Android ANR / "Lunera Dev isn't responding") and dark opacity overlay hangs when opening the "Log injection" sheet.
  - Replaced unsafe `AsyncValue.value` reads with `valueOrNull` in `DoseSheet` and `SiteRotationSheet` to safeguard against unhandled Riverpod stream error states.
  - Wrapped `SiteRotationSheet` in a `SingleChildScrollView` to prevent viewport bottom overflows on compact displays.
  - Added comprehensive automated widget tests covering `InjectionSiteMap`, `DoseSheet` site rotation interactions, `SiteRotationSheet`, and `CalmInjectionSheet`.

## [1.11.18] - 2026-11-08

### Added
- **Dedicated Debug & Release Build Variants (Side-by-Side Installation):**
  - Configured `applicationIdSuffix = ".debug"` and `versionNameSuffix = "-debug"` in `android/app/build.gradle.kts`, enabling side-by-side installation of the debug build (`com.example.ritme.debug`) alongside the production release (`com.example.ritme`).
  - Added multi-client Firebase configuration in `android/app/google-services.json` supporting both release and debug package identifiers.
  - Implemented distinct Android app launcher labels via resource overlays: "Lunera Dev" for debug builds and "Lunera" for production releases.
- **In-App Developer Indicators & Flexible Privacy Shield:**
  - Added a subtle `DEV` pill badge in `HomePage` during debug mode (`kDebugMode`).
  - Updated `SettingsPage` to distinguish debug builds from production releases.
  - Added automatic Privacy Shield (`FLAG_SECURE`) bypass in `Lock.setSecureScreen` during debug mode, allowing developers to capture screenshots and record tests unimpeded.

## [1.11.17] - 2026-11-08

### Added
- **Android Privacy Shield (`FLAG_SECURE`):**
  - Added native Android window protection in `MainActivity.kt` via MethodChannel (`setSecureScreen`), preventing sensitive medical data leakage in Recent Apps / App Switcher previews and blocking screenshots.
  - Added `privacyShield` state to `AppLockState` and persistence in `lib/lock.dart`, automatically applying `FLAG_SECURE` upon application startup.
  - Added a dedicated "Privacy Shield" toggle in `SecurityPage` (`lib/ui/security_page.dart`) with Indonesian translation support.

### Changed
- **Device Security Parity & Cleanup:**
  - Synchronized secure screen lifecycle so disabling app security automatically releases `FLAG_SECURE`.

## [1.11.16] - 2026-11-08

### Added
- **Debounced Background Auto-Sync Queue (`lib/repo.dart`):**
  - Implemented centralized background auto-sync scheduling with a 1,500ms debounce interval (`scheduleDebounceSync`), coalescing rapid successive writes into a smooth background sync cycle.
  - Added reactive `SyncState` and `syncStateProvider` to track synchronization status (`idle`, `syncing`, `synced`, `error`), pending mutation counts, and last synced timestamp.
- **Auto-Sync Status Indicator in Data Management (`lib/ui/data_page.dart`):**
  - Integrated real-time background sync status pill and timestamp in `DataPage` with full Indonesian localization.

### Changed
- **Non-Blocking Safe Writes (`lib/repo.dart`):**
  - Wrapped all repository write mutations (`addTherapy`, `logDose`, `adjustSupply`, `addJournal`, `addMeasurement`, etc.) in `_safeWrite`, enforcing a 4-second bounded timeout so offline usage commits instantly to Firestore's local cache without freezing the UI thread.

## [1.11.15] - 2026-11-08

### Added
- **Interactive Profile Photo Cropper (`lib/ui/profile_page.dart`):**
  - Added pure Flutter circular avatar cropper (`ProfilePhotoCropPage`) featuring pan gestures, pinch-to-zoom (0.8x to 4.0x), 90-degree clockwise rotation, and rule-of-thirds grid guides without external heavy native image cropping libraries.
  - Implemented `_WhatsAppCropOverlayPainter` with circular mask, guideline grid, and corner focus brackets.
- **Full-Screen Photo Viewer & Action Sheet (`lib/ui/profile_page.dart`):**
  - Added `ProfilePhotoViewPage` for full-screen photo viewing with zoom, pan, and smooth `Hero(tag: 'profile_photo_hero')` transition from the profile avatar.
  - Added modern modal bottom sheet with quick actions for Camera, Gallery, View Photo, and Remove Photo.
- **Indonesian Localization Support (`lib/l10n_id.dart`):**
  - Added comprehensive Indonesian translations for profile photo cropping, viewing, camera/gallery selection, and confirmation dialogues.

### Changed
- **Pre-Decoded Avatar MemoryImage Caching (`lib/profile.dart`):**
  - Cached pre-decoded `MemoryImage` directly within `ProfileState` (`effectiveImage`) to eliminate redundant base64 decoding on repeated widget builds and list scrolling.
- **Enhanced UserAvatar (`lib/profile.dart`):**
  - Added `heroTag` support to `UserAvatar` and integrated light haptic feedback on avatar interactions.
- **Tactile Keypad Haptics (`lib/ui/lock_screen.dart`):**
  - Integrated `HapticFeedback.lightImpact()` across the Moon PIN pad and stealth Decoy Calculator buttons for responsive tactile feedback on every digit tap.

## [1.11.14] - 2026-11-08

### Added
- **Multi-Hormone Pharmacokinetic Simulations (`lib/sim.dart`):**
  - Expanded pharmacokinetic simulation models to support **Testosterone** (`t_enanthate`, `t_cypionate`, `t_propionate`, `t_undecanoate`, `t_gel`) in `ng/dL` and **Progesterone/Progestins** (`p4_oral`, `p4_rectal`, `mpa_susp`) in `ng/mL`, making hormone level curves universal across transfeminine, transmasculine, and TRT regimens.
  - Added helper `pkProfilesFor(hormoneId, route)` to filter simulation profiles dynamically according to selected hormone and administration route.
- **Combination Medication Support (`lib/models.dart`, `lib/ui/sheets.dart`, `lib/sim.dart`):**
  - Added support for dual-component combination medications (such as Cyclofem / Novafem with 5 mg Estradiol Cypionate + 25 mg Medroxyprogesterone Acetate) with `secondaryHormoneId`, `secondaryDose`, `secondaryDoseUnit`, and `secondaryPk`.
  - Updated `intakesFor()` to automatically distribute a single logged dose across both target hormone curves simultaneously with zero double-counting in inventory or reminders.
  - Added "Combination medication" toggle and secondary active ingredient configuration in `TherapySheet`.
- **Adaptive Level Displays (`lib/ui/levels.dart`, `lib/ui/home.dart`, `lib/widget_sync.dart`):**
  - Updated `WeekCard` on Home screen and `LevelPanel` to adaptively display the primary active hormone (Estradiol, Testosterone, or Progesterone) and properly format decimal values for progestins in `ng/mL`.
  - Updated `widget_sync.dart` to recognize secondary combination hormone curves in Android home screen widgets.

## [1.11.13] - 2026-11-05

### Changed
- **Modular Test Suite Architecture (`test/`):**
  - Partitioned monolithic `widget_test.dart` into domain-specific, maintainable test files: `test/models_test.dart`, `test/sim_test.dart`, `test/schedule_test.dart`, `test/security_test.dart`, `test/notifications_test.dart`, and `test/repo_test.dart`.
- **Update Checker Dialog Localization (`lib/update_checker.dart`, `lib/l10n_id.dart`):**
  - Wrapped app update prompts, status messages, and action buttons in `tr()` with complete Indonesian translations.
- **Project Structure & Module Cleanup (`lunera.iml`, `.idea/modules.xml`):**
  - Renamed legacy IDE module descriptor `ritme.iml` to `lunera.iml` and updated project configuration while strictly preserving native Android package identity and backup schema compatibility.

### Removed
- **Redundant Root Android Widget Scaffolding (`android_widget/`):**
  - Removed duplicate `android_widget/` folder from project root as all native Kotlin widget implementations, layouts, and resource snippet files are permanently wired inside `android/app/src/main/`.

## [1.11.12] - 2026-11-05

### Fixed
- **Discreet Notifications for Low Supply & Expiry (`lib/notifications.dart`, `lib/l10n_id.dart`):**
  - Extended lockscreen notification privacy masking (`discreetNotify`: *Wellness & Routine* and *Minimal*) to low-supply and medication expiry reminders so sensitive item names and medication labels never leak on the lockscreen.
- **Persistent PIN & Decoy Calculator Brute-Force Protection (`lib/lock.dart`, `lib/ui/lock_screen.dart`):**
  - Added persistent 5-attempt lockout tracking in `SharedPreferences` across the Moon PIN screen, stealth Decoy Calculator, and PIN verification sheet so app restarts cannot bypass cooldowns.
  - Hardened Decoy Calculator `=` PIN verification to check single 6-digit candidates silently without breaking calculator stealth or counting normal math operations as failed guesses.

### Changed
- **Pure Celestial Dark Theme (`lib/main.dart`):**
  - Streamlined theme architecture to Lunera's signature single dark sanctuary theme (Midnight & Pastel) with dynamic phase accents, eliminating redundant theme mode switching.
- **Robust Backup Schema Validation (`lib/repo.dart`):**
  - Enhanced JSON backup validation with per-row schema and date integrity checks across all data collections, while supporting both Lunera and legacy 'ritme' file formats.
- **PBKDF2-HMAC-SHA256 PIN Key Derivation (`lib/lock.dart`):**
  - Upgraded PIN hashing from single-round SHA-256 to 60,000-iteration PBKDF2-HMAC-SHA256 with constant-time verification and seamless automatic migration for existing legacy PIN hashes.
- **Release Signing Security & CI Quality Gate (`android/app/build.gradle.kts`, `.github/workflows/release.yml`, `.gitignore`):**
  - Removed tracked Android release keystore and credential files from Git version control while preserving local signing support.
  - Updated GitHub Actions release workflow to enforce `flutter analyze` and `flutter test` before building and to load release signing credentials securely from GitHub Repository Secrets with automatic post-build cleanup.

### Removed
- **Legacy Asteria AI Leftovers (`lib/models.dart`, `lib/repo.dart`, `lib/l10n_id.dart`, `.github/workflows/release.yml`):**
  - Removed unused `DEFAULT_GEMINI_API_KEY` build flag, `Prefs.geminiApiKey` / `Prefs.asteriaMode` persistence (while preserving legacy backup import compatibility), and 74 unused translation strings.

---

## [1.11.11] - 2026-11-01

### Added
- **Guided Calm Injection (`lib/ui/guided_injection.dart`, `lib/ui/home.dart`, `lib/ui/sheets.dart`):**
  - Interactive 4-step guided injection modal specifically designed to ease injection anxiety, needle fatigue, and rushed administration.
  - Step 1: Mindful grounding with an animated pulsing breathing orb, site rotation indicator, and calming prompts.
  - Step 2: 30-second alcohol evaporation countdown timer with haptic cues to prevent stinging and skin irritation.
  - Step 3: Technique guide comparing Intramuscular (90°, muscle relaxation tips) and Subcutaneous (45°–90°, skin fold pinching tips).
  - Step 4: Heartwarming affirmation, dose recap, and seamless 1-tap logging with automatic supply deduction.
- **Discreet Shipping & Pickup Assistant (`lib/ui/pickup_assistant_sheet.dart`, `lib/ui/supplies.dart`):**
  - "Hold at Location / Ambil Sendiri di Agen Ekspedisi" template generator supporting J&T Express, JNE Express, SiCepat, Pos Indonesia, and generic couriers.
  - Generates standardized shipping notes instructing logistics couriers to keep sensitive parcels at the drop point rather than delivering to family households.
  - Integrated 1-tap clipboard copying with haptic feedback, real-time monospace preview, and practical safe pickup tips.
  - Added a restock alert banner in the Supplies tab highlighting low items and providing instant access to the Pickup Assistant.

---

## [1.11.10] - 2026-11-01

### Added
- **Decoy Calculator Lock (`lib/lock.dart`, `lib/ui/lock_screen.dart`, `lib/ui/security_page.dart`):**
  - Integrated stealth calculator lock screen disguise that acts as a real, functional dark-themed calculator performing genuine mathematical operations.
  - Owners securely unlock the application by entering their 6-digit PIN followed by `=` (or biometric authentication when enabled).
  - Added dedicated toggle in Security Settings allowing users to choose between the celestial Moon PIN pad and the stealth Decoy Calculator.
- **Discreet Notifications / Lockscreen Masking (`lib/models.dart`, `lib/notifications.dart`, `lib/ui/settings_page.dart`):**
  - Added notification text masking to prevent sensitive medication names and dosages from appearing on device lockscreens in public or family environments.
  - Introduced customizable privacy modes: *Standard*, *Wellness & Routine* (*"Routine Reminder ✦ Time for your daily hydration and wellness routine"*), and *Minimal* (*"Lunera ✦ Gentle reminder."*).
  - Integrated live test notification preview directly from the Dose Reminders settings card.

---

## [1.11.9] - 2026-10-31

### Removed
- **Asteria AI Chatbot (`lib/asteria.dart` & `lib/ui/asteria_chat.dart`):**
  - Removed Asteria AI chatbot companion and associated UI entry points (Floating Action Button in Home, Asteria navigation tile in More screen, and Asteria Connection card in Settings).
  - Streamlined application codebase and APK bundle size, optimizing resource efficiency and reaffirming Lunera's pure, lightweight offline-first health and therapy tracking philosophy.

---

## [1.11.8] - 2026-10-31

### Fixed
- **Ultra-Low Latency Asteria Conversational Replies (`lib/asteria.dart`):**
  - Integrated model-aware thinking configuration: applied `thinkingLevel: 'low'` for Gemini 3.8 and `thinkingBudget: 0` for Gemini 2.5 Flash, preventing 15–30 second internal reasoning pauses and delivering instant companion replies.
  - Added robust candidate part extraction filtering out internal reasoning thoughts (`part.thought == true`), ensuring Asteria surfaces only compassionate and soothing dialogue.
  - Eliminated pre-flight model discovery latency by directly attempting generation with active candidates first, saving up to 10 seconds of round-trip downloads on mobile connections.
- **Connection Hang Prevention & Timeout Safeguards (`lib/asteria.dart` & `lib/ui/asteria_chat.dart`):**
  - Implemented strict per-phase HTTP timeouts (10s connect, 18s stream body read) preventing unbounded socket hangs on cellular networks.
  - Added a 22-second UI safeguard in `AsteriaChatPage` with graceful fallback handling and friendly localized timeout messages, guaranteeing Asteria never remains indefinitely stuck on "Asteria is reflecting...".

---

## [1.11.7] - 2026-10-31

### Fixed
- **Gemini 3.8 Flash & Gemini 3.6 Flash Flagship Prioritization (`lib/asteria.dart`):**
  - Updated candidate endpoints to prioritize active Gemini 3.x Flash models (`gemini-3.8-flash` and `gemini-3.6-flash`), removing obsolete fallback dependencies.
  - Implemented universal fallback: if model discovery finds any active model supporting `generateContent`, Asteria dynamically binds to it regardless of model identifier changes.

### Added
- **In-Dialog Live Connection Testing (`lib/ui/asteria_chat.dart` & `lib/l10n_id.dart`):**
  - Introduced a **[Tes Koneksi / Test Connection]** button directly inside the Asteria Connection Modal.
  - Users can now verify their Gemini API Key with one tap, receiving instant live feedback confirming active model availability or detailed server diagnostics.

---

## [1.11.6] - 2026-10-31

### Fixed
- **Official GA v1 Endpoint Routing with Multi-Tier Fallback (`lib/asteria.dart`):**
  - Resolved `Unknown Gemini API error` by routing `gemini-1.5-flash` to its official GA endpoint (`https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent`).
  - Added dual-version `AsteriaEndpoint` architecture supporting both GA (`v1`) and preview (`v1beta`) endpoints with automatic failover across multiple model tiers (`gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash`, `gemini-2.5-flash`).
  - Preserved comprehensive error messaging from Google's response payloads so diagnostic information is transparently displayed if API key permissions or project quotas are rejected.

---

## [1.11.5] - 2026-10-31

### Fixed
- **Dynamic Gemini Flash Model Discovery & Resilient Fallback (`lib/asteria.dart`):**
  - Resolved `models/gemini-1.5-flash is not found for API version v1beta` (404) by upgrading to Google's active Flash family (`gemini-2.5-flash` and `gemini-2.0-flash`).
  - Added programmatic runtime model discovery via `https://generativelanguage.googleapis.com/v1beta/models` to automatically bind to whichever Flash model is enabled for the provided API key.
  - Implemented multi-model fallback queue in `_postGenerateContent`: if any candidate returns 404, Asteria immediately shifts to the next active model in the queue without interrupting the conversation or throwing exceptions to the user.

---

## [1.11.4] - 2026-10-31

### Added
- **Celestial Mode Switcher for Asteria AI (`lib/models.dart`, `lib/asteria.dart`, `lib/ui/asteria_chat.dart`):**
  - Introduced seamless mode selection between **Shared Star** (*Bintang Bersama* - free community connection provided out-of-the-box) and **Personal Star** (*Bintang Pribadi* - dedicated connection powered by user's own Google Gemini API key).
  - Designed elegant and intuitive `showAsteriaConnectionDialog` accessible directly from both the Asteria chat screen and the application Settings page.
  - Added bidirectional quota fallback: if either Shared Star or Personal Star reaches its daily resting limit (HTTP 429), users are gently prompted with a one-tap option to switch to the alternative mode immediately without disruption.

### Changed
- **Softened and Welcoming Celestial Terminology (`lib/l10n_id.dart` & `lib/ui/settings_page.dart`):**
  - Completely replaced cold technical developer jargon ("Public Key", "Private Key", "BYOK") with warm, poetic, and friendly celestial language tailored for all users.
  - Full bilingual localization (English and Indonesian) across all modal dialogs, status badges, and resting notification banners.

---

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
