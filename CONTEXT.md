# nitmgpt UI

Android notification watcher client. UI follows a glass-minimal chrome strategy: liquid glass only on the Bottom Bar and secondary-page Back button; everything else opaque.

## Language

**Bottom Bar**:
The pill-shaped tab bar at the root of the app (Home / Settings). One of two surfaces that keep liquid glass (the other is the Back button on secondary pages).
_Avoid_: Tab bar, navbar, footer bar

**Chrome**:
Fixed navigation UI that frames content — top bars, bottom bar, and modal shells. Not scrollable list content.
_Avoid_: Shell, header area

**Content**:
Scrollable or grouped main body of a screen (lists, forms, tiles). Always opaque — including buttons, switches, and chips inside content.
_Avoid_: Body, main area

**Liquid glass**:
Real-time refractive shader surfaces from `liquid_glass_widgets`. Distinct from the static gradient wallpaper behind the app.
_Avoid_: Glass effect, blur, frosted

**Wallpaper**:
The static mint gradient background (`kAppGlassBackground`) behind all screens. Not liquid glass. Retained for Bottom Bar refraction and brand identity.
_Avoid_: Background, glass background

**Secondary page**:
A full-screen page pushed on top of the tab shell (e.g. Local models, Add Rules). Uses wallpaper Stack + transparent Scaffold + standard opaque AppBar — same layout pattern throughout.
_Avoid_: Sub-page, detail page, pushed route

**Back button**:
The navigation control that pops a secondary page. Uses liquid glass (`GlassIconButton`) — the only liquid-glass control besides the Bottom Bar.
_Avoid_: Back arrow, leading button, close button

**Modal**:
Temporary overlay UI — alert dialogs, confirm dialogs, and bottom sheets. Always opaque.
_Avoid_: Dialog, popup, sheet

**Adaptive glass quality**:
Device performance probing and quality caching (`GlassAdaptiveScopeConfig`, `GlassQualityCache`) retained at app root. Wraps the entire app via `LiquidGlassWidgets.wrap` — not scoped locally to individual glass widgets.
_Avoid_: Quality warmup, glass cache
