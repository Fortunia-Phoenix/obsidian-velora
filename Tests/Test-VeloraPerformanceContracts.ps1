$ErrorActionPreference = 'Stop'

$theme = Get-Content -Raw (Join-Path $PSScriptRoot '..\theme.css')

# Obsidian discovers locally installed themes by parsing manifest.json as plain JSON.
# A UTF-8 BOM is accepted by some PowerShell readers but rejected by JSON.parse(),
# which leaves the CSS loadable by folder name while hiding the theme from Appearance.
$manifestPath = Join-Path $PSScriptRoot '..\manifest.json'
$manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)
if ($manifestBytes.Length -ge 3 -and $manifestBytes[0] -eq 0xEF -and $manifestBytes[1] -eq 0xBB -and $manifestBytes[2] -eq 0xBF) {
  throw 'manifest.json must be UTF-8 without BOM so Obsidian can enumerate the installed theme.'
}
$manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
foreach ($field in @('name', 'version', 'minAppVersion', 'author')) {
  if ([string]::IsNullOrWhiteSpace([string]$manifest.$field)) {
    throw "manifest.json is missing required theme field: $field"
  }
}

function Assert-Contains([string] $Needle, [string] $Message) {
  if (-not $theme.Contains($Needle)) { throw $Message }
}

# Obsidian uses the lowercase `todo` callout type; only conventional uppercase
# placeholders are forbidden in the theme source.
if ($theme -cmatch '\b(?:TODO|TBD)\b') {
  throw 'Placeholder found in theme CSS.'
}

# Style Settings public contract: IDs and numeric values are parsed as one block so
# a default or range cannot be accidentally borrowed from a neighbouring setting.
foreach ($contract in @(
  @{ Id = 'velora-sidebar-liquid-glass'; Type = 'class-toggle' },
  @{ Id = 'velora-sidebar-liquid-intensity'; Type = 'variable-number-slider'; Default = '0.16'; Min = '0.08'; Max = '0.6'; Step = '0.01' },
  @{ Id = 'velora-sidebar-liquid-duration'; Type = 'variable-number-slider'; Default = '18'; Min = '10'; Max = '40'; Step = '1' },
  @{ Id = 'velora-sidebar-blur'; Type = 'variable-number-slider'; Default = '22'; Min = '0'; Max = '40'; Step = '1' },
  @{ Id = 'velora-reduce-motion'; Type = 'class-toggle' }
)) {
  $block = [regex]::Match($theme, "(?ms)^\s*-\s*\r?\n\s*id:\s*$($contract.Id)\s*$.*?(?=^\s*-\s*\r?\n\s*id:|^\*/)")
  if (-not $block.Success) { throw "Missing Style Settings block: $($contract.Id)" }
  foreach ($field in @('Type', 'Default', 'Min', 'Max', 'Step')) {
    if ($contract.ContainsKey($field)) {
      $expected = $contract[$field]
      if ($block.Value -notmatch "(?m)^\s*$($field.ToLowerInvariant()):\s*$([regex]::Escape($expected))\s*$") {
        throw "Style Settings contract drifted for $($contract.Id): $($field.ToLowerInvariant()) must be $expected."
      }
    }
  }
}

# The optimized implementation must share the decorative paint definition and only
# use the glass filter where the running Obsidian/Electron engine supports it.
Assert-Contains '--velora-sidebar-liquid-decoration:' 'Liquid-glass decoration was not factored into a shared custom property.'
Assert-Contains '@supports (backdrop-filter: blur(1px))' 'Missing backdrop-filter capability guard for Obsidian/Electron fallback.'
Assert-Contains 'background: var(--velora-sidebar-liquid-decoration)' 'Liquid-glass surfaces are not consuming the shared decoration.'

$liquidLeaf = 'body\.velora-sidebar-liquid-glass \.mod-sidedock \.workspace-leaf-content'
$themeOutsideBackdropSupport = [regex]::Replace(
  $theme,
  "(?ms)@supports \(backdrop-filter: blur\(1px\)\)\s*\{\s*$liquidLeaf\s*\{.*?\n\s*\}\s*\}",
  ''
)
$unconditionalLiquidLeaf = [regex]::Match($themeOutsideBackdropSupport, "(?ms)$liquidLeaf\s*\{[^}]*backdrop-filter:\s*[^;]+;")
if ($unconditionalLiquidLeaf.Success) {
  throw 'Liquid sidebar backdrop filtering must be declared only inside its @supports block.'
}
$supportsLiquidLeaf = [regex]::Match($theme, "(?ms)@supports \(backdrop-filter: blur\(1px\)\)\s*\{.*?$liquidLeaf\s*\{[^}]*backdrop-filter:\s*blur\(var\(--velora-sidebar-blur\)\) saturate\(1\.18\) contrast\(1\.02\);")
if (-not $supportsLiquidLeaf.Success) {
  throw 'Supported Obsidian/Electron engines must retain the liquid sidebar backdrop filter.'
}

$opaqueLiquidFallback = [regex]::Match($theme, "(?ms)$liquidLeaf\s*\{[^}]*background:\s*var\(--velora-sidebar-liquid-decoration\);")
if (-not $opaqueLiquidFallback.Success) {
  throw 'Liquid sidebar fallback must retain the opaque token-driven decorative surface.'
}

$sharedLeaf = '\.mod-sidedock \.workspace-leaf-content'
$sharedLeafBases = [regex]::Matches($theme, "(?ms)^$sharedLeaf\s*\{.*?^\}")
$sharedLeafBase = $sharedLeafBases | Where-Object { $_.Value -match 'background:\s*var\(--velora-panel-strong\);' } | Select-Object -First 1
if ($null -eq $sharedLeafBase) { throw 'Shared sidebar leaf opaque fallback rule is missing.' }
if ($sharedLeafBase.Value -match 'backdrop-filter:\s*[^;]+;') {
  throw 'Shared sidebar leaf backdrop filtering must be declared only inside a backdrop-filter @supports block.'
}
$sharedLeafSupported = [regex]::Match($theme, "(?ms)@supports \(backdrop-filter: blur\(1px\)\)\s*\{.*?$sharedLeaf\s*\{[^}]*background:\s*rgba\(var\(--velora-surface-rgb\), 0\.48\);[^}]*backdrop-filter:\s*blur\(18px\) saturate\(1\.2\);")
if (-not $sharedLeafSupported.Success) {
  throw 'Supported Obsidian/Electron engines must retain the translucent shared sidebar leaf surface and filter.'
}

# Settings controls share a single flex row with native icons and dropdowns. Their
# hover styling may change paint, but must not translate the button out of alignment.
$settingButtonHover = [regex]::Match($theme, '(?ms)\.setting-item-control\s*>\s*button:not\(\.clickable-icon\):hover\s*\{(?<body>.*?)\}')
if (-not $settingButtonHover.Success) {
  throw 'Missing dedicated stationary hover rule for Settings buttons.'
}
if ($settingButtonHover.Groups['body'].Value -notmatch 'transform:\s*none\s*;') {
  throw 'Settings buttons must remain stationary on hover.'
}
# Obsidian mobile already exposes the left drawer in its top navigation. On iPad,
# the view-header copy must be hidden without removing the desktop control.
$ipadToggleRule = "  body.is-mobile .sidebar-toggle-button.mod-left {`n    display: none;`n  }"
if (-not $theme.Contains($ipadToggleRule)) {
  throw 'The duplicate left-sidebar toggle must be hidden in the iPad/mobile tablet layout.'
}
if ($theme -match '(?m)^body\.is-mobile \.sidebar-toggle-button\.mod-left\s*\{') {
  throw 'The duplicate-toggle fix must remain inside the tablet media query, not apply globally to every mobile layout.'
}

# Preserve the Nexus-first H2 contract; the pure-CSS fallback must never take over
# when the section engine has marked the document active.
Assert-Contains 'body:not(.velora-section-engine-active) .markdown-preview-view' 'H2 fallback no longer defers to the Nexus section engine.'
Assert-Contains '.velora-h2-card-block' 'Nexus H2 card classes are no longer protected.'

$h2FallbackStart = 'body:not\(\.velora-section-engine-active\) \.markdown-preview-view \.markdown-preview-section > div\.el-h2:not\(\.velora-h2-card-block\):not\(\.velora-h2-long-block\):is\('
if ($theme -notmatch $h2FallbackStart) { throw 'H2 fallback lost its Nexus guard or protected-class exclusions.' }
$h2Fallback = [regex]::Match($theme, "(?ms)$h2FallbackStart.*?\) > h2\s*\{")
if (-not $h2Fallback.Success) { throw 'H2 fallback heading rule is missing or no longer scoped to the Markdown preview section.' }
if ([regex]::Matches($h2Fallback.Value, ':has\(').Count -ne 5) {
  throw 'H2 fallback must retain exactly five bounded lookahead branches.'
}
foreach ($count in 1..5) {
  $branch = ':has(' + (('+ div:not(.el-h1):not(.el-h2):not(.mod-footer) ' * $count) + '+ div:is(.el-h1, .el-h2, .mod-footer))')
  if (-not $h2Fallback.Value.Contains($branch)) { throw "H2 fallback is missing its $count-block bounded lookahead branch." }
}

# One compact reduced-motion selector is retained for the liquid-glass animation.
$reducedBlocks = [regex]::Matches($theme, 'body\.velora-reduce-motion\.velora-sidebar-liquid-glass').Count
if ($reducedBlocks -ne 1) { throw "Expected one liquid-glass reduced-motion selector, found $reducedBlocks." }

# Left and right floating sidebars must remain independently configurable while
# sharing the established sizing, surface, liquid-glass, and retract contracts.
foreach ($contract in @(
  @{ Id = 'velora-floating-sidebar'; Type = 'class-toggle' },
  @{ Id = 'velora-floating-right-sidebar'; Type = 'class-toggle' },
  @{ Id = 'velora-sidebar-left-margin'; Type = 'variable-number-slider'; Default = '14'; Min = '0'; Max = '48'; Step = '1' },
  @{ Id = 'velora-sidebar-right-margin'; Type = 'variable-number-slider'; Default = '14'; Min = '0'; Max = '48'; Step = '1' }
)) {
  $block = [regex]::Match($theme, "(?ms)^\s*-\s*\r?\n\s*id:\s*$($contract.Id)\s*$.*?(?=^\s*-\s*\r?\n\s*id:|^\*/)")
  if (-not $block.Success) { throw "Missing floating-sidebar Style Settings block: $($contract.Id)" }
  foreach ($field in @('Type', 'Default', 'Min', 'Max', 'Step')) {
    if ($contract.ContainsKey($field)) {
      $expected = $contract[$field]
      if ($block.Value -notmatch "(?m)^\s*$($field.ToLowerInvariant()):\s*$([regex]::Escape($expected))\s*$") {
        throw "Floating-sidebar Style Settings contract drifted for $($contract.Id): $($field.ToLowerInvariant()) must be $expected."
      }
    }
  }
}

Assert-Contains 'body:not(.is-mobile).velora-floating-right-sidebar .sidebar-toggle-button.mod-right' 'The right floating sidebar must hide its native desktop toggle just like the left side.'
Assert-Contains 'body:not(.is-mobile).velora-floating-right-sidebar .workspace-split.mod-horizontal.mod-right-split' 'Missing desktop right floating-sidebar layout selector.'
Assert-Contains 'transform: translateX(100%) !important;' 'The right floating sidebar must retract beyond the right viewport edge.'
Assert-Contains 'right: 0 !important;' "The right floating sidebar must anchor to the viewport's right edge."
Assert-Contains 'left: auto !important;' 'The right floating sidebar must clear the left anchor inherited from the mirrored implementation.'
Assert-Contains 'transform: translateX(calc(var(--velora-sidebar-right-margin) * -1)) !important;' 'The right floating sidebar must expand to its configured right inset.'
Assert-Contains 'left: calc(var(--velora-sidebar-handle-width) * -1);' 'The right floating sidebar must expose a mirrored left-side hover handle.'
Assert-Contains 'body:not(.is-mobile).velora-floating-right-sidebar.velora-sidebar-liquid-glass .workspace-split.mod-horizontal.mod-right-split' 'The right floating sidebar must inherit the left sidebar liquid-glass treatment.'
Assert-Contains 'body.velora-floating-right-sidebar.velora-sidebar-liquid-glass .workspace-split.mod-horizontal.mod-right-split' 'System reduced motion must stop the right floating-sidebar animation.'

# The fixed-height floating right sidebar starts below the Windows titlebar controls,
# so its tab row must reclaim that otherwise-unused safe area and keep every sidebar
# tab visible at the default 300px width without making the native strip scroll.
Assert-Contains '.is-hidden-frameless:not(.is-fullscreen) .workspace-tabs.mod-top-right-space .workspace-tab-header-container' 'The native top-right window-controls safe area must remain protected outside the floating sidebar.'
$floatingRightHeader = [regex]::Match($theme, '(?ms)body:not\(\.is-mobile\)\.velora-floating-right-sidebar \.workspace-split\.mod-horizontal\.mod-right-split \.workspace-tabs\.mod-top-right-space \.workspace-tab-header-container\s*\{[^}]*padding-right:\s*12px;')
if (-not $floatingRightHeader.Success) {
  throw 'The floating right sidebar must reclaim the inapplicable top-right frame safe area.'
}
$floatingRightTab = [regex]::Match($theme, '(?ms)body:not\(\.is-mobile\)\.velora-floating-right-sidebar \.workspace-split\.mod-horizontal\.mod-right-split \.workspace-tab-header\s*\{(?=[^}]*flex:\s*0 0 28px;)(?=[^}]*width:\s*28px;)(?=[^}]*min-width:\s*28px;)(?=[^}]*height:\s*28px;)[^}]*\}')
if (-not $floatingRightTab.Success) {
  throw 'The floating right sidebar tabs must use compact fixed icon hitboxes at the default width.'
}
$floatingRightTabInner = [regex]::Match($theme, '(?ms)body:not\(\.is-mobile\)\.velora-floating-right-sidebar \.workspace-split\.mod-horizontal\.mod-right-split \.workspace-tab-header-inner\s*\{(?=[^}]*width:\s*28px;)(?=[^}]*height:\s*28px;)(?=[^}]*padding:\s*5px;)[^}]*\}')
if (-not $floatingRightTabInner.Success) {
  throw 'The floating right sidebar tab contents must stay centered inside the compact hitboxes.'
}
Write-Host 'Velora performance contracts passed.'
