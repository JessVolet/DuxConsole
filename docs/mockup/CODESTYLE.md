# DuxConsole mockup code style

Root `AGENTS.md` applies throughout. The rules here apply to the native prototype and any later web extraction. Follow [ARCHITECTURE.md](ARCHITECTURE.md) for dependency direction and [SPECS.md](SPECS.md) for behavior.

- Use English for identifiers, filenames, comments and commit subjects. Keep user-visible UI copy in locale files, including errors, labels and accessible names. Fixture titles and display names are data.
- Default to no comments. Write a brief English comment for a non-obvious invariant, platform workaround or measured visual detail whose reason is missing from the code. Put module rationale and usage in the docs. Delete commented-out code.
- Use typed QML properties and signals, strict TypeScript for web extraction, explicit public props and semantic action IDs. Keep state with one owner. Derive display state from inputs. Use typed records for adapter outcomes and serialize IDs instead of depending on collection position.
- Use PascalCase for component files, camelCase for functions and plain names that reflect the domain. Keep rendering and style together in each component. Share tokens for spacing, type, color, radius, opacity and motion before adding per-screen overrides.
- Screens compose, place, bind and register navigation. Build reusable pills, cards, surface treatments, focus borders, dialog chrome, and hint rows in primitives or widgets first. Access hardware, time, storage and browser input through host adapters. Use semantic actions from config for buttons, and resolve glyphs through `InputGlyph`.
- Keep layout responsive. Render text and icons upright on slanted surfaces. Keep focus and selection distinct. Disable motion with config or reduced-motion preference. Use native accessible buttons and modal semantics, and preserve the focus order and exact restoration rules.
- Keep changes focused on one roadmap increment. Audit the changed QML or web import paths, hardcoded copy/keys/colors/timing, cardinality, loading/empty/error states, localization, reference evidence and validation results before sign-off.
