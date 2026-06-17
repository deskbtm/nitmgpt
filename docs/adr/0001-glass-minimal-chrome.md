# Glass-minimal chrome

nitmgpt previously applied liquid glass (`liquid_glass_widgets`) broadly — AppBars, tab bars, dialogs, list controls, and the root scaffold. That increased GPU compositing cost and fought the library's own guidance: scrollable content should be opaque; glass belongs on navigation chrome.

We decided to keep liquid glass on **two surfaces only**: the root **Bottom Bar** (Home / Settings tabs) and the **Back button** on secondary pages. Everything else becomes opaque Material/Cupertino UI. The static mint **Wallpaper** stays — it is not liquid glass and gives the Bottom Bar something to refract against.

**Adaptive glass quality is retained.** `LiquidGlassWidgets.wrap`, `GlassAdaptiveScopeConfig`, and `GlassQualityCache` continue to wrap the entire app (not scoped locally to the two glass widgets). Bottom Bar visual parameters (`GlassQuality.premium`, pill sizing, iOS 26-style settings) are unchanged.

## Considered Options

- **Glass everywhere (status quo)** — Rejected: unnecessary shader work on lists, dialogs, and toolbars; inconsistent with opaque content already used on Settings and Local models.
- **Bottom Bar only, opaque back button** — Rejected: user wanted glass on secondary-page back navigation for visual continuity with the pill bar.
- **Remove adaptive quality cache** — Rejected: keep startup probing and cached quality for the remaining glass surfaces; full-app wrap is simpler than local scoping.
- **Replace wallpaper with flat color** — Rejected: wallpaper is cheap to draw and supports Bottom Bar aesthetics.

## Consequences

- `GlassScaffold`, `GlassAppBar`, `GlassToolbarLayer`, `GlassTabShell`, and content glass controls (`GlassButton`, `GlassSwitch`, `GlassChip`) should be removed or replaced outside the two allowed surfaces.
- Modals (`GlassDialog`, `GlassSheet`) become standard opaque dialogs and bottom sheets.
- Secondary pages (Add Rules, Local models, etc.) share one layout pattern: wallpaper Stack + transparent Scaffold + fixed glass back button (44×44pt), with large title scrolled inside the body.
- Domain terms for this UI model live in `CONTEXT.md` at the repo root.
