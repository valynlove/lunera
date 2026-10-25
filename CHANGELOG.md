# Changelog

All notable changes to the **Lunera** project will be documented in this file.

## [1.0.0] - 2026-10-21

### 🌙 Rebranding & Design System
- **Rebranded to Lunera**: Introduced tagline *"Every Phase, Your Own."*
- **Midnight Color Palette**: Aesthetic dark theme featuring Midnight (`#0F122B`), Indigo (`#3B3F7A`), Lavender (`#A997FF`), Moonlight (`#E6E2FF`), and Ivory (`#F7F6FB`).
- **Dynamic Accent Chooser**: Theme customization supporting Lunera, Moonlight, Ocean, and Rose Quartz accents.
- **Custom Lunera Emblem**: Custom-painted logo featuring orbital ring, crescent moon, and glowing star.

### 🔒 Biometric Security & Privacy
- **Fingerprint & Face ID Lock**: Integrated `local_auth` biometric security gate on app resume and startup.
- **Persistent Biometric State**: State preserved across app reboots via `SharedPreferences`.
- **Grace Period Protection**: 3-second grace period during app lifecycle transitions to prevent lock screen triggers when picking photos from external pickers.

### 📊 Pharmacokinetic Level Simulations & Insights
- **Interactive Level Curves**: Real-time simulation curves for Estradiol and Testosterone levels based on pharmacokinetic models.
- **Target Range Overlay**: Customizable green target bands set in collaboration with medical guidance.
- **Lab Result Calibration**: Dynamic calibration matching level estimates to actual blood lab test results.
- **Body Development Map**: Physical transition map highlighting skin, breast, body curve, and mood milestones.

### 📅 Calendar & Timeline
- **Interactive Date Picker**: Top bar calendar button allowing instant navigation to any year or month.
- **Dual View Modes**:
  - `Schedule View`: Detailed dose slots and observations for the selected date.
  - `Full History`: Complete chronological log of all recorded doses with date, time, site, and dosage.
- **HRT Duration Counter**: Real-time tracker calculating years, months, and days on therapy alongside total logged doses.

### 📖 Journal & Observations
- **Mood Emoji Selector**: 5 state selectors (Calm, Happy, Neutral, Energetic, Tired).
- **Category Filter Chips**: Filter entries by All, Mood, Body Changes, and Notes.
- **CRUD Journal Entries**: Create, edit, and delete personal reflections and physical observations.

### 📦 Supply & Tool Management
- **Stock Tracking**: Monitor medication vials, pills, patches, and tools (syringes, alcohol wipes, needles, gloves).
- **Expiration & Low Stock Alerts**: Smart color indicators for stock running low (≤ 2 doses) or expired items.
- **Automatic Stock Deduction**: Logging a dose automatically deducts medication and supplies from inventory.

### 🖼️ Profile & Avatar System
- **Avatar Cache Engine**: Zero-lag in-memory RAM image cache (`_avatarCache`) preventing decoding stutter when rendering compact base64 photos.
- **Photo Fitting Dialog**: Aspect ratio crop tool with `BoxFit.cover` preventing photo distortion.
- **Live Circular Preview**: Live avatar preview during profile editing.

### ☁️ Data Backup & Export
- **Offline JSON Export/Import**: Export and import complete account data (therapies, logs, labs, supplies, targets, prefs, journals) to/from single JSON files.
- **Firebase Cloud Backup**: Online cloud backup restoration.
