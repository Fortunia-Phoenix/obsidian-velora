# Changelog

## Unreleased

- 修复：右侧浮动侧边栏不再继承仅适用于窗口顶栏的 `126px` 窗口控制区占位，并将侧栏标签收敛为 `28px` 图标命中区；默认 `300px` 宽度现在可同时显示当前六个侧栏标签、原生“加号”和标签列表按钮，常规顶栏安全距离保持不变。
- 验证状态：合同测试与实际 Obsidian 1.13.7 DOM 布局检查均已通过；用户已于 2026-09-21 完成最终视觉确认。
- 新增：增加独立的右侧浮动侧边栏 Style Settings 开关和展开后右侧距离设置；右侧栏镜像复用左侧栏的自动缩回、悬浮把手、尺寸、外观、液态玻璃和减少动态效果行为。
- 行为变化：左右浮动侧栏可独立启用；原有左侧开关 ID、默认关闭状态和现有配置保持不变。
- 验证状态：合同测试覆盖右侧开关、位置变量、镜像锚点、收回方向、把手、液态玻璃和减少动态效果；实际 Obsidian 双侧交互与视觉 QA 待运行时验证。

- 修复：在 iPad/粗指针平板的 Obsidian 移动布局中隐藏视图标题栏内重复的左侧栏按钮，保留顶部移动导航栏的原生左侧抽屉入口。
- 修复：移除 manifest.json 的 UTF-8 BOM，使 Obsidian 外观设置能够正常枚举已安装的 Velora，同时保留按文件夹名加载主题的现有行为。
- 修复：设置页按钮悬停只更新阴影，不再向上位移，避免与同一行的原生图标、下拉框出现位置跳动。
- 验证状态：扩展 PowerShell 合同测试，覆盖主题清单无 BOM、必需字段和设置按钮悬停位置；实际 Obsidian 1.13.7 重载后的主题列表与视觉状态仍待桌面 QA。
- 性能优化：合并液态玻璃侧栏的重复动画停用选择器，并复用浅色流光装饰层，减少重复 CSS 声明与样式维护成本。
- 兼容性变化：为侧边栏玻璃滤镜增加 `@supports (backdrop-filter: blur(1px))` 守卫；支持该能力的 Obsidian/Electron 保持原有半透明与模糊，不支持时回退到可读的面板表面。
- 验证状态：新增 `Tests/Test-VeloraPerformanceContracts.ps1`，锁定 Style Settings 数值、Nexus 优先的 H2 五分支回退、桌面侧栏和减少动态效果合同；尚待实际 Obsidian 桌面视觉 QA。
- Added a complete Chinese feature and caveat reference for theme behavior, all Style Settings options, responsive rules, compatibility boundaries, and optional Velora Nexus integration.
- Established the feature reference as the required synchronization and acceptance baseline for every future Velora change.
- Protected every documented `VEL-*` feature contract from unconfirmed behavioral changes and added mandatory regression verification for affected features.

## 1.3.3

- Converted Velora to a directly installable theme repository.
- Sidebar sizing is controlled through Style Settings variables instead of a companion plugin.
- Removed the companion plugin from the release structure.
- Added a CSS fallback so compact H2 sections can frame their following content in pure theme installs.
