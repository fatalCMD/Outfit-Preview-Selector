# Changelog

## 1.2.0 - 2026-07-11

### Added

- Added persistent List and Card views with ten presets per page and automatic restoration of the last selected layout.
- Added semantic outfit icons with Auto Detect, Armor, Heavy, Light, Arcane, and Clothing choices saved per preset.
- Added full two-dimensional controller navigation in Card View and a physical `Y` / Triangle shortcut for opening the selected preset editor.
- Added saved MCM controls for the preview camera's horizontal position and height.
- Added reversible suppression of other registered Skyrim and mod UI movies while OPS is open.
- Added configurable player-targeted depth of field to keep the preview character sharp while softening the world behind them.
- Added an animated right-side badge displaying the selected outfit's name, slot number, and category icon.
- Added a centered, letter-spaced **GEAR PRESETS** title and gold-sweep opening animation.

### Changed

- Reworked pagination into a compact counter with adjacent previous and next controls.
- Replaced controller pointers with animated double-gold focus frames for cards, list rows, Edit, Close, view switching, and pagination controls.
- Made List View focus column-specific: the Apply column highlights the full row, while the Edit column highlights only its button.
- Removed the Card View Edit button; controller users open Edit with `Y` / Triangle, while mouse users can switch to List View.
- Locks all preset switching while an outfit change is already in progress.
- Positions the selected-outfit badge approximately 20% above the bottom edge.

### Fixed

- Removed the fallback cursor that could jitter after keyboard-only menu opens; SkyUI again owns the only visible pointer.
- Prevented saved List/Card preferences from flashing the wrong layout during the next menu load.

## 1.1.0 - 2026-07-11

### Added

- Expanded storage from 10 to 50 persistent, renameable outfit slots.
- Added five pages of ten outfits with mouse, keyboard, and controller navigation.
- Added a rotating gold equipping indicator to the active outfit row.
- Added inventory preflight before outfit changes. Missing pieces now leave the current attire untouched and appear in a themed **Ensemble Incomplete** notice.
- Added a thin double-gold frame with ornamental corner marks to the list and detail panels.

### Changed

- Rebuilt the menu on a 1280x720 stage for consistent widescreen sizing and mouse reach.
- Extended the footer and moved the Close control lower for clearer separation from pagination.
- Preserved animated preview physics on the supported Faster HDT-SMP 2.5 build through FSMP's normal frame and synchronization pipeline.
- Temporarily suspends preview physics while armor systems detach and rebuild during an outfit change, then resumes automatically.
- Defers and coalesces mouse actions so SkyUI and native input cannot process the same page or outfit click twice.

### Fixed

- Removed the duplicate custom mouse pointer so only the SkyUI cursor is displayed.
- Fixed oversized menus and unreachable footer controls on systems that scaled the previous 800x600 movie differently.
- Corrected the previous and next arrow directions.
- Fixed crashes caused by replacing menu rows from inside their active mouse callbacks.
- Fixed crashes caused by outfit changes rebuilding HDT-enabled armor while preview physics was still using those systems.
- Reworked the guarded FSMP hook with a full 64-bit jump and instruction-safe gateway, avoiding ASLR displacement failures.

## 1.0.0

- Initial public release.
- Added ten persistent, renameable outfit slots and exact worn-outfit highlighting.
- Added the paused third-person preview with mouse and gamepad rotation.
- Added optional preview animation and guarded Faster HDT-SMP 2.5 physics support.
- Added MCM configuration, SmoothCam coordination, and cached outfit data.
