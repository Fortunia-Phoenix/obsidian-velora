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

manifest.json must be saved as UTF-8 without BOM. A BOM can let the CSS keep loading from an existing cssTheme folder selection while preventing Obsidian from listing the theme under installed themes.

## Style Settings

Velora is designed to work with the Style Settings community plugin. Install Style Settings if you want to control theme options from Obsidian settings.

The floating sidebar options are handled by theme CSS variables, including:

- independently enable or disable the left and right floating sidebars
- hide or show the left ribbon
- sidebar width
- sidebar height
- independent left and right inset margins when expanded
- auto retract delay
- sidebar opacity, blur, radius, and liquid glass effect

No companion plugin is required for these settings. Sidebar size is adjusted from Style Settings instead of direct drag handles. The right floating sidebar mirrors the left sidebar behavior, including auto-retract, hover handle, shared dimensions, surface styling, and optional liquid-glass effects. Its vertically inset header reclaims the unused Windows frame-control reserve and uses compact icon hitboxes so the current sidebar tabs, new-tab button, and tab-list button fit at the default 300px width.

## Notes

This repository is intended for personal GitHub management. It does not include the full Obsidian vault, workspace files, cache files, private notes, internal maintenance contracts, local verification scripts, or JavaScript plugin code.

On iPad and other coarse-pointer tablets using Obsidian mobile navigation, Velora keeps the native top-navbar drawer control and hides the duplicate left-sidebar control inside the note header.
