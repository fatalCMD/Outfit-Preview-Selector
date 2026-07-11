# Changelog

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
