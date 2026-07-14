const { Plugin } = require("obsidian");

const PANEL_SELECTOR = ".workspace-split.mod-horizontal.mod-left-split";
const WIDTH_VAR = "--velora-sidebar-width";
const HEIGHT_VAR = "--velora-sidebar-height";
const SECTION_LIMIT_VAR = "--velora-section-card-line-limit";
const CARD_BLOCK_CLASS = "velora-h2-card-block";
const CARD_FIRST_CLASS = "is-velora-card-first-content";
const CARD_END_CLASS = "is-velora-card-end";
const LONG_BLOCK_CLASS = "velora-h2-long-block";
const SECTION_CLASSES = [
  CARD_BLOCK_CLASS,
  CARD_FIRST_CLASS,
  CARD_END_CLASS,
  LONG_BLOCK_CLASS,
];
const SECTION_CLASS_SELECTOR = SECTION_CLASSES.map((name) => `.${name}`).join(",");

module.exports = class VeloraSidebarControls extends Plugin {
  async onload() {
    this.data = Object.assign({ width: null, height: null }, await this.loadData());
    this.handles = [];
    this.attachTimer = null;
    this.sectionCache = new Map();
    this.renderJobs = new WeakMap();
    this.lineLimitCache = null;
    this.lineLimitFrame = null;
    this.applySavedSize();

    this.registerMarkdownPostProcessor((element, context) =>
      this.decorateH2Sections(element, context)
    );

    this.app.workspace.onLayoutReady(() => {
      this.applySavedSize();
      this.attachHandles();
    });
    this.registerEvent(this.app.workspace.on("layout-change", () => this.scheduleAttach()));
    this.registerEvent(this.app.metadataCache.on("changed", (file) => {
      this.sectionCache.delete(file.path);
    }));
    this.registerEvent(this.app.vault.on("delete", (file) => {
      this.sectionCache.delete(file.path);
    }));
    this.registerEvent(this.app.vault.on("rename", (file, oldPath) => {
      this.sectionCache.delete(oldPath);
      this.sectionCache.delete(file.path);
    }));

    this.observer = new MutationObserver((mutations) => {
      if (this.sidebarChanged(mutations)) this.scheduleAttach();
    });
    this.observer.observe(document.body, { childList: true, subtree: true });
    this.register(() => this.observer.disconnect());
    this.register(() => window.clearTimeout(this.attachTimer));
    this.register(() => window.cancelAnimationFrame(this.lineLimitFrame));

    this.addCommand({
      id: "reset-floating-sidebar-size",
      name: "重置浮动侧栏尺寸",
      callback: async () => {
        this.data.width = null;
        this.data.height = null;
        document.body.style.removeProperty(WIDTH_VAR);
        document.body.style.removeProperty(HEIGHT_VAR);
        await this.saveData(this.data);
      },
    });
  }

  onunload() {
    this.removeHandles();
    this.clearAllSectionClasses(document);
    document.body.classList.remove("velora-sidebar-is-resizing");
  }

  applySavedSize() {
    if (Number.isFinite(this.data.width)) {
      document.body.style.setProperty(WIDTH_VAR, `${this.data.width}px`);
    }
    if (Number.isFinite(this.data.height)) {
      document.body.style.setProperty(HEIGHT_VAR, `${this.data.height}px`);
    }
  }

  scheduleAttach() {
    window.clearTimeout(this.attachTimer);
    this.attachTimer = window.setTimeout(() => this.attachHandles(), 80);
  }

  attachHandles() {
    if (document.body.classList.contains("is-mobile")) {
      this.removeHandles();
      return;
    }

    const panel = document.querySelector(PANEL_SELECTOR);
    if (!panel) {
      this.removeHandles();
      return;
    }
    if (this.panel === panel && this.handles.every((handle) => handle.isConnected)) return;

    this.removeHandles();
    this.panel = panel;

    for (const axis of ["width", "height", "both"]) {
      const handle = document.createElement("div");
      handle.className = `velora-sidebar-resize-handle is-${axis}`;
      handle.dataset.axis = axis;
      handle.setAttribute("role", "separator");
      handle.setAttribute("aria-label", axis === "width" ? "调整侧栏宽度" : axis === "height" ? "调整侧栏高度" : "调整侧栏宽度和高度");
      handle.addEventListener("pointerdown", (event) => this.startResize(event, axis));
      panel.appendChild(handle);
      this.handles.push(handle);
    }
  }

  removeHandles() {
    for (const handle of this.handles || []) handle.remove();
    this.handles = [];
    this.panel = null;
  }

  sidebarChanged(mutations) {
    if (document.body.classList.contains("is-mobile")) return false;
    if (this.panel && !this.panel.isConnected) return true;
    if (this.panel && this.handles.some((handle) => !handle.isConnected)) return true;
    if (this.panel) return false;

    for (const mutation of mutations) {
      for (const node of [...mutation.addedNodes, ...mutation.removedNodes]) {
        if (!(node instanceof Element)) continue;
        if (node.matches(PANEL_SELECTOR) || node.querySelector(PANEL_SELECTOR)) return true;
      }
    }
    return false;
  }

  startResize(event, axis) {
    if (event.button !== 0 || !this.panel) return;
    event.preventDefault();
    event.stopPropagation();

    const rect = this.panel.getBoundingClientRect();
    const start = {
      x: event.clientX,
      y: event.clientY,
      width: rect.width,
      height: rect.height,
    };

    document.body.classList.add("velora-sidebar-is-resizing");

    const move = (moveEvent) => {
      moveEvent.preventDefault();
      if (axis === "width" || axis === "both") {
        const width = this.clamp(start.width + moveEvent.clientX - start.x, 220, Math.min(window.innerWidth * 0.7, 720));
        this.data.width = Math.round(width);
        document.body.style.setProperty(WIDTH_VAR, `${this.data.width}px`);
      }

      if (axis === "height" || axis === "both") {
        const height = this.clamp(start.height + (moveEvent.clientY - start.y) * 2, 320, window.innerHeight * 0.96);
        this.data.height = Math.round(height);
        document.body.style.setProperty(HEIGHT_VAR, `${this.data.height}px`);
      }
    };

    const end = async () => {
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", end);
      window.removeEventListener("pointercancel", end);
      document.body.classList.remove("velora-sidebar-is-resizing");
      await this.saveData(this.data);
    };

    window.addEventListener("pointermove", move, { passive: false });
    window.addEventListener("pointerup", end, { once: true });
    window.addEventListener("pointercancel", end, { once: true });
  }

  clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
  }

  async decorateH2Sections(element, context) {
    this.clearAllSectionClasses(element);

    const info = context.getSectionInfo(element);
    const file = this.app.vault.getAbstractFileByPath(context.sourcePath);
    if (!info || !file || file.extension !== "md") return;

    const job = {};
    this.renderJobs.set(element, job);
    const structure = await this.getMarkdownStructure(file);
    if (this.renderJobs.get(element) !== job) return;

    const blocks = this.getDirectMarkdownBlocks(element);
    if (blocks.length === 0) return;

    const limit = this.getSectionLineLimit();
    const startBoundaryIndex = this.lowerBoundBoundary(structure.boundaries, info.lineStart);
    const endBoundaryIndex = this.lowerBoundBoundary(structure.boundaries, info.lineEnd + 1);
    const activeBoundary = structure.boundaries[startBoundaryIndex - 1] || null;
    let activeSection = activeBoundary?.level === 2
      ? structure.sections.get(activeBoundary.line) || null
      : null;
    const chunkBoundaries = structure.boundaries.slice(startBoundaryIndex, endBoundaryIndex);
    let boundaryIndex = 0;
    let firstContentPending = false;
    let lastCardBlock = null;

    const finishCard = () => {
      if (lastCardBlock) lastCardBlock.classList.add(CARD_END_CLASS);
      lastCardBlock = null;
      firstContentPending = false;
    };

    for (const block of blocks) {
      const headingLevel = block.classList.contains("el-h1")
        ? 1
        : block.classList.contains("el-h2")
          ? 2
          : 0;

      if (headingLevel > 0) {
        finishCard();

        let boundary = null;
        while (boundaryIndex < chunkBoundaries.length) {
          const candidate = chunkBoundaries[boundaryIndex];
          boundaryIndex += 1;
          if (candidate.level === headingLevel) {
            boundary = candidate;
            break;
          }
        }

        activeSection = headingLevel === 2 && boundary
          ? structure.sections.get(boundary.line) || null
          : null;

        if (headingLevel === 2 && this.isShortSection(activeSection, limit)) {
          block.classList.add(CARD_BLOCK_CLASS);
          firstContentPending = true;
          lastCardBlock = block;
        }
        continue;
      }

      if (!activeSection) continue;

      if (!this.isShortSection(activeSection, limit)) {
        block.classList.add(LONG_BLOCK_CLASS);
        continue;
      }

      block.classList.add(CARD_BLOCK_CLASS);
      if (firstContentPending) {
        block.classList.add(CARD_FIRST_CLASS);
        firstContentPending = false;
      }
      lastCardBlock = block;
    }

    const lastBlockInfo = lastCardBlock ? context.getSectionInfo(lastCardBlock) : null;
    const renderedEndLine = Math.max(info.lineEnd, lastBlockInfo?.lineEnd ?? -1);
    const hasFooter = element.classList.contains("mod-footer") || Boolean(element.querySelector(".mod-footer"));
    if (
      this.isShortSection(activeSection, limit) &&
      (renderedEndLine >= activeSection.endLine - 1 || hasFooter)
    ) {
      finishCard();
    }
  }

  getDirectMarkdownBlocks(element) {
    const isBlock = (candidate) =>
      candidate instanceof HTMLElement &&
      Array.from(candidate.classList).some((name) => name.startsWith("el-"));

    if (isBlock(element)) return [element];
    return Array.from(element.children).filter(isBlock);
  }

  lowerBoundBoundary(boundaries, line) {
    let low = 0;
    let high = boundaries.length;
    while (low < high) {
      const middle = (low + high) >> 1;
      if (boundaries[middle].line < line) low = middle + 1;
      else high = middle;
    }
    return low;
  }

  isShortSection(section, limit) {
    return Boolean(section && section.lineCount <= limit);
  }

  getSectionLineLimit() {
    if (this.lineLimitCache !== null) return this.lineLimitCache;

    const raw = getComputedStyle(document.body).getPropertyValue(SECTION_LIMIT_VAR);
    const value = Number.parseInt(raw, 10);
    this.lineLimitCache = Number.isFinite(value) ? this.clamp(value, 20, 1000) : 120;
    this.lineLimitFrame = window.requestAnimationFrame(() => {
      this.lineLimitCache = null;
      this.lineLimitFrame = null;
    });
    return this.lineLimitCache;
  }

  clearAllSectionClasses(root) {
    const targets = [];
    if (root instanceof HTMLElement && SECTION_CLASSES.some((name) => root.classList.contains(name))) {
      targets.push(root);
    }
    targets.push(...root.querySelectorAll(SECTION_CLASS_SELECTOR));
    for (const target of targets) target.classList.remove(...SECTION_CLASSES);
  }

  async getMarkdownStructure(file) {
    const cached = this.sectionCache.get(file.path);
    if (cached && cached.mtime === file.stat.mtime) return cached.promise;

    const entry = {
      mtime: file.stat.mtime,
      promise: this.buildMarkdownStructure(file),
    };
    this.sectionCache.set(file.path, entry);

    try {
      return await entry.promise;
    } catch (error) {
      if (this.sectionCache.get(file.path) === entry) this.sectionCache.delete(file.path);
      throw error;
    }
  }

  async buildMarkdownStructure(file) {
    const content = await this.app.vault.cachedRead(file);
    const lines = content.split(/\r\n|\n|\r/);
    const boundaries = [];
    let fence = null;
    let lastContentLine = 0;

    for (let index = 0; index < lines.length; index += 1) {
      const line = lines[index];
      if (line.trim().length > 0) lastContentLine = index;

      const fenceMatch = /^\s*(`{3,}|~{3,})/.exec(line);
      if (fenceMatch) {
        const marker = fenceMatch[1][0];
        fence = fence === marker ? null : fence || marker;
        continue;
      }
      if (fence) continue;

      const heading = /^(#{1,2})\s+/.exec(line);
      if (heading) boundaries.push({ level: heading[1].length, line: index });
    }

    const sections = new Map();
    for (let index = 0; index < boundaries.length; index += 1) {
      const heading = boundaries[index];
      if (heading.level !== 2) continue;

      const nextBoundary = boundaries[index + 1];
      const endLine = nextBoundary ? nextBoundary.line - 1 : lastContentLine;
      sections.set(heading.line, {
        endLine,
        lineCount: endLine - heading.line + 1,
      });
    }

    return { boundaries, sections };
  }
};
