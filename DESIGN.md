# Lunera Design System

Read: Offline-first personal health and hormone therapy companion, with a calm dark-first **Eternal Dusk** interface across phones, foldables, tablets, and desktop/web windows.
Platforms: Android, iOS, Windows, macOS, Linux, Web (`Compact < 600dp`, `Medium 600–839dp`, `Expanded >= 840dp`; EN & ID locales).
Dials: variance 4 · motion 3 · density 5

## Window Size Classes (Window-First)
Adapt to the current window width rather than named device types:
- **Compact (`< 600dp`)**: Single-pane flow, floating bottom navigation bar (`Levels`, `Calendar`, `Home`, `Supplies`, `More`), bottom sheets for focused subtasks, 16–20dp horizontal margins.
- **Medium (`600–839dp`)**: Collapsed Navigation Rail (`88dp`) on the leading edge, 24dp margins, 2-column grids for peer cards, centered modal dialogs (`maxWidth: 560`).
- **Expanded (`>= 840dp`)**: Persistent Sidebar (`244dp`) with brand lockup, quick action, and keyboard shortcuts (`Alt+1..5`), 32dp margins, multi-pane split views (`AdaptiveSplitView` at `>= 880dp` content width) and 2–3 column grids, centered modal dialogs, and reading width cap (`760dp`).

## Signature Elements
- **Precision Dose Cycle Dial (`DoseCard`)**: Radial tick ring showing cycle progress or 24-hour marks with tabular countdown figures and direct one-tap dose logging.
- **Pharmacokinetic Hormone Curve (`LevelPanel`)**: Estimated serum trend paired with bloodwork points, target band, and trough reminders.
Surrounding chrome stays quiet so these two objects carry visual focus.

## Color Roles & Contrast (Celestial Reverie Dark)
- `background`: `C.voidBg` (`#0D0624`) / `C.midnight` (`#170B3D`, Midnight Purple)
- `surface`: `C.deepCard` (`#1F104F`)
- `surface-raised`: `C.nebula` (`#351078`, Royal Violet)
- `text-primary`: `C.mist` (`#FAF4FF`) — ~15.6:1 on `#1F104F`, ~16.9:1 on `#170B3D`
- `text-secondary`: `C.mist` at 82% alpha — ~10.4:1 on `#1F104F`
- `icon-default`: `C.iconDefault` (`#B8A4D6`) — ~8.1:1 on `#170B3D`, ~7.5:1 on `#1F104F`
- `accent`: `C.aurora` (`#7737D9`, Cosmic Purple — `#FFFFFF` on `#7737D9` ~6.3:1), `accent-highlight`: `C.violet` (`#C16AFF`, Lavender — ~5.4:1 on `#1F104F`)
- `border-hairline`: `C.lavender` (`#E2B8FF`) at 16–22% alpha
- `status`: success/taken `Pastel.mint` (`#7DE2C7`), warning/due `C.coral` (`#FFE2C8`, Starlight Cream), hormone series (`C.rose` `#F3A8F4` Celestial Pink E2, `C.coral` `#FFE2C8` P4, `C.violet` `#C16AFF` T) — always paired with text, icon, or shape.

## Type Roles
- **Display**: `Instrument Serif` (tight tracking `-0.01 * size`, height `1.12`) for page titles and dial hero numbers.
- **UI & Body**: `Plus Jakarta Sans` (height `1.35–1.5`) for cards, lists, labels, and reading prose.
- **Tabular Figures**: `FontFeature.tabularFigures()` via `tabular(...)` on all countdowns, doses, lab values, stock quantities, dates, and stats.

## Spacing, Radii & Elevation
- **Spacing (`S`)**: 4pt base (`4, 8, 12, 16, 20, 24, 32`).
- **Radii (`R`)**: Concentric nesting — `card: 22`, `innerChip/badge: 10–12`, `modal/dialog: 26`, `pill: 999`.
- **Elevation**: Tonal layering (`midnight` -> `deepCard` -> `nebula`) with `1px` hairline borders and restrained ambient shadows.

## Motion & Accessibility Floor
- Transitions: 180–220ms `Curves.easeOutCubic`; strictly `Duration.zero` when `MediaQuery.disableAnimationsOf(context)` is active.
- Touch targets: `>= 48x48dp` interactive hit areas with `>= 8dp` separation where adjacent.
- Reflow & Scaling: Zero horizontal overflow at `320dp` width and `1.6x` system text scaling (`Column` + `Row`/`Wrap` instead of fixed-aspect grids).
- Keyboard & Pointer: Visible focus outlines (`C.violet`), subtle hover states (`C.lavender` 6%), and `Semantics` labels/roles/states on custom controls.

## Voice & House Rules
- Voice: Calm, supportive, non-judgmental.
- House rule: Keep Eternal Dusk dark-first atmospheric wallpaper + translucent navigation chrome as Lunera's signature sanctuary mood while maintaining WCAG AA legibility across all surfaces.
