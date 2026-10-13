# Recon v2.0 Power Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Recon v2.0 Power Suite: In-File Ripgrep search, Power Actions contextual menu (`Alt+A`), Frecency ranking, In-place file operations (`F2`, `Ctrl+N`), and fuzzy scoring.

**Architecture:** Modulate new features into focused QML components and JavaScript modules: `script/Fuzzy.js` (fuzzy scorer), `script/Frecency.js` (recency/frequency ranker), `PowerActionsMenu.qml` (contextual action runner), `RenameModal.qml` (inline rename), and `NewFileModal.qml` (inline creation). Integrate into `Recon.qml` with asynchronous execution.

**Tech Stack:** Quickshell QML (Qt 6), Hyprland (Wayland layer-shell), Ripgrep (`rg`), Wayland tools (`wl-copy`, `xdg-open`).

**Spec:** `docs/superpowers/specs/2026-10-13-recon-v2-power-suite-design.md`

## Global Constraints
- Target platform: Linux (Hyprland / Wayland, Quickshell runtime).
- 100% English UI text (zero Turkish or non-ASCII characters).
- 100% keyboard accessibility for every new feature.
- Zero UI overflow; anchor-based layouts honoring `contentInset` margins.
- Asynchronous process dispatch (no blocking the QML UI thread).

## Review Focus
- Extremely large query strings or regex special characters in Ripgrep mode (escape or handle safely).
- Missing binaries (`rg`, `kitty`, `code`) handled gracefully with user feedback or fallbacks.
- Invalid filesystem characters in Rename/NewFile modals prevented with input validation.
- Race conditions when rapid-typing in Ripgrep mode cancelled by debounced process termination.
- Empty search state cleanly rendering without index out-of-bounds errors.

---

### Task 1: Typo-Tolerant Fuzzy Scorer (`script/Fuzzy.js`)

**Files:**
- Create: `script/Fuzzy.js`
- Test: `tests/test_fuzzy.js` (CLI node or qmljs test)

- [ ] **Step 1: Write failing test for fuzzy matching**
  Create test verifying exact matches, word-boundary matches, camelCase initials, and substring matches with ranked scores.
- [ ] **Step 2: Implement `Fuzzy.score(pattern, text)` in `script/Fuzzy.js`**
  Implement fzf-like scoring calculating bonus for boundary, camelCase, consecutive characters, and penalty for gaps.
- [ ] **Step 3: Run test and verify scoring accuracy**
  Run test script to verify `scrshot` scores high against `screenshot.png` and low against unrelated strings.
- [ ] **Step 4: Integrate `Fuzzy.js` into `Recon.qml` display model filtering**
  Update `Recon.qml` search filter logic to sort display items by fuzzy match score.
- [ ] **Step 5: Commit Task 1**
  `git add script/Fuzzy.js tests/test_fuzzy.js Recon.qml && git commit -m "feat(search): add typo-tolerant fuzzy matching engine"`

---

### Task 2: Frecency Cache & Smart Ranking (`script/Frecency.js`)

**Files:**
- Create: `script/Frecency.js`
- Modify: `Recon.qml`
- Config: `~/.config/omarchy/recon_frecency.json`

- [ ] **Step 1: Implement Frecency tracker in `script/Frecency.js`**
  Functions: `recordAccess(path, frecencyData)`, `getScore(path, frecencyData)`, `prune(frecencyData)`.
- [ ] **Step 2: Add `FileView` for `recon_frecency.json` in `Recon.qml`**
  Persist access timestamps and count atomically on file open / action execution.
- [ ] **Step 3: Combine frecency score with fuzzy score in results ranking**
  When queries are empty or equally scored, rank by frecency score.
- [ ] **Step 4: Verify frecency update and ordering**
  Open test file, re-open Recon, verify file ranks top.
- [ ] **Step 5: Commit Task 2**
  `git add script/Frecency.js Recon.qml && git commit -m "feat(frecency): add frecency tracking and smart result ranking"`

---

### Task 3: In-File Content Search Mode (Ripgrep Engine)

**Files:**
- Modify: `Recon.qml`
- Modify: `ReconHeader.qml`
- Modify: `ResultRow.qml`

- [ ] **Step 1: Add Content Search mode state in `Recon.qml`**
  Detect `?` query prefix or `Ctrl+F` toggle to activate `isContentSearch` state.
- [ ] **Step 2: Update `ReconHeader.qml` to display Content Search indicator**
  Display `[In-File Search]` badge when mode is active.
- [ ] **Step 3: Wire asynchronous `rg` Process execution**
  Execute `rg -n --max-count=1 --smart-case "$QUERY" "$TARGET_DIR"` asynchronously via `StdioCollector`.
- [ ] **Step 4: Update `ResultRow.qml` and `PreviewPane.qml` for matching lines**
  Display matching line number and excerpt snippet in results and preview.
- [ ] **Step 5: Verify in-file search with test queries**
  Search known text inside notes or source files; verify exact line matches.
- [ ] **Step 6: Commit Task 3**
  `git add Recon.qml ReconHeader.qml ResultRow.qml PreviewPane.qml && git commit -m "feat(search): add ripgrep in-file content search mode"`

---

### Task 4: Power Actions Contextual Popover (`PowerActionsMenu.qml`)

**Files:**
- Create: `PowerActionsMenu.qml`
- Modify: `Recon.qml`

- [ ] **Step 1: Create `PowerActionsMenu.qml`**
  Anchor-based modal with actions list: `Open Default`, `Open in Terminal`, `Open with Code`, `Copy Relative Path`, `Git Diff`, `Extract Archive`.
- [ ] **Step 2: Add keyboard navigation to `PowerActionsMenu.qml`**
  `↑` / `↓` navigation, `Enter` to execute, `Esc` to close and return focus to results list.
- [ ] **Step 3: Implement execution handlers in `Recon.qml`**
  Wire shell commands (`kitty --directory`, `code`, `tar -xf / unzip`, `wl-copy`).
- [ ] **Step 4: Bind `Alt+A` and footer badge in `Recon.qml`**
  Pressing `Alt+A` on selected item opens `PowerActionsMenu`.
- [ ] **Step 5: Verify all action triggers**
  Test opening terminal and editor from selected item.
- [ ] **Step 6: Commit Task 4**
  `git add PowerActionsMenu.qml Recon.qml && git commit -m "feat(actions): add power actions contextual popover menu"`

---

### Task 5: In-Place File Operations (`F2` Rename & `Ctrl+N` New File)

**Files:**
- Create: `InlineActionModal.qml`
- Modify: `Recon.qml`

- [ ] **Step 1: Build `InlineActionModal.qml`**
  Modal with title, description, input field, and `Cancel` / `Confirm` actions.
- [ ] **Step 2: Wire `F2` Rename flow in `Recon.qml`**
  Pre-fill existing name; on `Confirm`, run `mv "$OLD" "$NEW"`, update models and select new item.
- [ ] **Step 3: Wire `Ctrl+N` New File/Note flow in `Recon.qml`**
  Prompt for new file name; on `Confirm`, run `touch "$NEW"` and open in editor.
- [ ] **Step 4: Add input validation for illegal path characters**
  Disallow empty names or directory traversal attacks.
- [ ] **Step 5: Verify rename and file creation on disk**
  Test renaming a test file and creating a new file; verify disk updates.
- [ ] **Step 6: Commit Task 5**
  `git add InlineActionModal.qml Recon.qml && git commit -m "feat(fs): add in-place rename and new file creation modals"`

---

### Task 6: Final Integration, Zero-Overflow Verification & Documentation

**Files:**
- Modify: `README.md`
- Test: Full end-to-end verification under Omarchy shell

- [ ] **Step 1: Verify all 5 features under running Quickshell**
  Restart omarchy-shell; test Ripgrep mode, Power Actions, Rename, New File, Frecency.
- [ ] **Step 2: Verify zero layout clipping and 100% English text**
  Confirm no text overflows on any display resolution.
- [ ] **Step 3: Update `README.md` with new features and shortcuts**
  Document `?` query mode, `Alt+A`, `F2`, `Ctrl+N` in keyboard table and feature highlights.
- [ ] **Step 4: Commit and push Task 6**
  `git add README.md && git commit -m "docs: document Recon v2.0 Power Suite features and shortcuts" && git push origin master`
