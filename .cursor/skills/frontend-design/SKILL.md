---
name: frontend-design
description: Create distinctive, production-grade Flutter UI with high design quality. Use this skill when the user asks to build widgets, screens, or cross-platform apps. Generates creative, polished Dart/Flutter code that avoids generic AI aesthetics.
---

This skill guides creation of distinctive, production-grade Flutter interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides UI requirements: a component, screen, application, or interface to build. They may include context about purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a **bold** aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. Use these for inspiration but design one that is true to a single, coherent aesthetic.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this **unforgettable**? What is the one thing someone will remember?

**Critical**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work—the key is intentionality, not intensity.

Then implement working Flutter/Dart code (widgets, theme, animations, etc.) that is:

- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Flutter UI Aesthetics Guidelines

Focus on:

- **Typography**: Choose fonts that are distinctive and readable (e.g. Google Fonts). Avoid relying only on system defaults or plain Roboto; pair a characterful display font with a clear body font. Use `TextTheme` and `ThemeData.textTheme` for consistency and clear hierarchy.
- **Color & Theme**: Commit to a cohesive palette. Use `ThemeData`, `ColorScheme`, and color constants for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion & Feedback**: Use `AnimationController`, implicit/explicit animations, `Hero`, `AnimatedSwitcher`, etc. for transitions and micro-interactions. Prioritize high-impact moments: one well-orchestrated entrance with staggered reveals creates more delight than scattered motion. Combine gestures, hover (e.g. on web), and focus states for small surprises.
- **Spatial Composition**: Unexpected layouts. Asymmetry, overlap, diagonal flow, grid-breaking elements. Generous negative space OR controlled density. Implement with `Row`, `Column`, `Stack`, `CustomScrollView`, `CustomPainter`, and the like.
- **Backgrounds & Visual Depth**: Create atmosphere and depth rather than defaulting to solid colors. Use `Decoration`, gradients, shapes, shadows, and transparency. Add contextual effects—gradient meshes, geometric patterns, layered transparencies, strong shadows, decorative borders—that match the overall aesthetic.

NEVER use generic AI aesthetics: overused fonts (default Roboto/system-only with no hierarchy), clichéd color schemes (especially purple gradients on white), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, and different aesthetics. NEVER converge on common choices (e.g. Space Grotesk) across generations.

**Important**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing and typography. Elegance comes from executing the vision well.

Remember: extraordinary creative work is possible. Don’t hold back—show what can be created when committing fully to a distinctive Flutter UI.
