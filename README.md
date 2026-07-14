# Velora

Velora is a custom Obsidian theme with an optional companion plugin for sidebar controls.

## Repository Layout

```text
manifest.json
theme.css
plugin/
  velora-sidebar-controls/
    main.js
    styles.css
    manifest.json
```

## Install Theme Only

Download this repository as a ZIP, extract it, and put the extracted folder into:

```text
.obsidian/themes/
```

The final theme structure should be:

```text
.obsidian/themes/Velora/
  manifest.json
  theme.css
```

Then open Obsidian and select `Velora` in Settings -> Appearance -> Themes.

## Install Theme + Sidebar Controls

Obsidian themes cannot load JavaScript from the theme folder. The sidebar controls are a companion plugin and must be installed in the plugins folder.

Use the complete install package from Releases when available:

```text
Velora-complete-vault-install-1.3.3.zip
```

Extract it into your vault root so the structure becomes:

```text
.obsidian/themes/Velora/
  manifest.json
  theme.css
.obsidian/plugins/velora-sidebar-controls/
  main.js
  manifest.json
  styles.css
```

Then enable both:

- Settings -> Appearance -> Themes -> Velora
- Settings -> Community plugins -> Velora Sidebar Controls

## Manual Plugin Install

If you installed the theme only, copy this folder:

```text
plugin/velora-sidebar-controls/
```

into:

```text
.obsidian/plugins/velora-sidebar-controls/
```

Then enable `Velora Sidebar Controls` in Settings -> Community plugins.

## Recommended Plugin

Velora supports settings through the Style Settings plugin. Install Style Settings from Obsidian community plugins if you want to adjust theme options from the settings UI.

## Notes

This repository is intended for personal GitHub management. It does not include the full Obsidian vault, workspace files, cache files, or private notes.
