# Velora

Velora is a custom Obsidian theme with a soft glass interface, floating sidebar styling, Style Settings controls, and responsive desktop/tablet/mobile layout tuning.

## Install

Download this repository as a ZIP, extract it, and put the extracted folder into:

```text
.obsidian/themes/
```

The final structure should be:

```text
.obsidian/themes/Velora/
  manifest.json
  theme.css
```

If the extracted folder is named `obsidian-velora-main`, rename it to `Velora` for clarity.

Then open Obsidian and select `Velora` in Settings -> Appearance -> Themes.

## Style Settings

Velora is designed to work with the Style Settings community plugin. Install Style Settings if you want to control theme options from Obsidian settings.

The floating sidebar options are handled by theme CSS variables, including:

- enable or disable the left floating sidebar
- hide or show the left ribbon
- sidebar width
- sidebar height
- left margin when expanded
- auto retract delay
- sidebar opacity, blur, radius, and liquid glass effect

No companion plugin is required for these settings. Sidebar size is adjusted from Style Settings instead of direct drag handles.

## Notes

This repository is intended for personal GitHub management. It does not include the full Obsidian vault, workspace files, cache files, private notes, or JavaScript plugin code.
