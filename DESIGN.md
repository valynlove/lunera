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

## Color Roles & Contrast (Eternal Dusk Dark)
- `background`: `C.voidBg` (`#090817`) / `C.midnight` (`#11102B`)
- `surface`: `C.deepCard` (`#171436`)
- `surface-raised`: `C.nebula` (`#292052`)
- `text-primary`: `C.mist` (`#ECE8FF`) — ~14.6:1 on `#171436`
- `text-secondary`: `C.mist` at 82% alpha — ~9.6:1 on `#171436`
- `icon-default`: `C.iconDefault` (`#A29BBE`) — ~6.8:1 on `#11102B`
- `accent`: `C.aurora` (`#8065E8`), `accent-highlight`: `C.violet` (`#A58BFF`)
- `border-hairline`: `C.lavender` (`#C7B8FF`) at 16–22% alpha
- `status`: success/taken `Pastel.mint` (`#7DE2C7`), warning/due `C.coral` (`#F2A17C`), hormone series (`C.rose` E2, `C.coral` P4, `C.violet` T) — always paired with text, icon, or shape.

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
