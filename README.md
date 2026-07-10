# Outfit Preview Selector

Outfit Preview Selector (OPS) is a Skyrim Special Edition outfit manager built around a paused third-person character preview. It provides ten named outfit slots, applies outfits without closing the selector, and highlights an outfit only while the player is wearing exactly its saved armor set.

Current public version: **1.0.0**

The current source targets Skyrim Special Edition 1.5.97 with SKSE64 2.0.20. Anniversary Edition and Skyrim VR are not currently supported.

## Features

- Ten persistent, renameable outfit slots.
- Outfit switching without closing the selector.
- Exact worn-outfit highlighting.
- Paused third-person preview with mouse and gamepad rotation.
- Optional player animation during the paused preview.
- Guarded Faster HDT-SMP 2.5 preview-physics support.
- MCM configuration for controls and behavior.
- Event-driven equipment checks with no continuous Papyrus polling.

## Requirements

- Skyrim Special Edition 1.5.97
- [SKSE64 2.0.20](https://skse.silverlock.org/)
- [Address Library for SKSE Plugins (1.5.x)](https://www.nexusmods.com/skyrimspecialedition/mods/32444)
- [SkyUI 5.2 or newer](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
- Microsoft Visual C++ Redistributable 2015–2022 x64

Optional integrations include [Faster HDT-SMP](https://www.nexusmods.com/skyrimspecialedition/mods/57339) and [SmoothCam](https://www.nexusmods.com/skyrimspecialedition/mods/41252).

## Source layout

- `native/` — SKSE/CommonLibSSE-NG camera, input, animation, and Scaleform bridge.
- `interface/` — ActionScript 2 source for the custom selector menu.
- `papyrus/` — Papyrus source for outfit storage, MCM, and menu coordination.

Compiled binaries, the plugin file, and third-party interface assets are intentionally not included in this source repository.

## Native build

The native plugin uses CMake and vcpkg. From the `native` directory, configure and build the Skyrim preset:

```powershell
cmake --preset skyrim
cmake --build build/skyrim --config Release
```

The exact preset names and dependency configuration are defined in `native/CMakePresets.json` and `native/vcpkg.json`.

## Compatibility notes

- Skyrim SE 1.5.97 with SKSE64 2.0.20 is the tested target.
- Skyrim AE 1.6.x has not been release-tested.
- Skyrim VR is unsupported.
- Paused-preview SMP physics is limited to the validated Faster HDT-SMP 2.5 layout. Other versions use the animation-only fallback.
- SmoothCam integration is optional.

## Credits

Bethesda Game Studios; the SKSE team; meh321; the SkyUI team; the CommonLibSSE-NG contributors; DaymareOn and the Faster HDT-SMP contributors; and the SmoothCam contributors.
