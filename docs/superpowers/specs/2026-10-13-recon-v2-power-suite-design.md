# Recon v2.0 Power Suite Design Specification

> **Date**: 2026-10-13  
> **Status**: Approved  
> **Project**: `omarchy-recon` (Native Omarchy / Hyprland QML Overlay)  

---

## 1. Intent & The "Why"

Omarchy Recon is currently a fast, native frosted-glass file name finder and previewer. However, power users in an Arch Linux + Hyprland workflow frequently need to:
1. Search **inside** files (code declarations, markdown notes, documentation contents) without opening a heavy terminal session or separate ripgrep command.
2. Trigger contextual operations on found files (Open in Terminal, Open in VS Code, Git Diff, Extract) directly from keyboard shortcuts.
3. Rapidly manage files in-place (rename with `F2`, create new notes/scripts with `Ctrl+N`) without opening a graphical file manager or changing terminal directories.
4. Tolerate typos and abbreviation queries (`scshot` -> `screenshot.png`).
5. Surface the files they actually work on recently and frequently instead of plain alphabetical listings.

**Recon v2.0 Power Suite** elevates Recon from a simple file finder to a keyboard-driven desktop command center.

---

## 2. Goals, Non-Goals & Anti-Goals

### Goals
- **Full-Text In-File Search**: Seamlessly switch between filename search and in-file content search using a `?` query prefix (e.g., `?handleClick`) or `Ctrl+F` toggle.
- **Power Actions Menu**: Floating keyboard-driven popover (`Alt+A` / `Tab` when on result) offering contextual actions (`Open in Terminal`, `Open with Code`, `Copy Relative Path`, `Extract Archive`, `Git Diff`).
- **Frecency & Dynamic Sorting**: Track execution counts and modification times (`mtime`) in a lightweight local JSON cache (`~/.config/omarchy/recon_frecency.json`) to float active project files to the top.
- **In-Place File Operations**: Quick modal dialogs for inline file rename (`F2`) and new file creation (`Ctrl+N`) inside the active target directory.
- **Typo-Tolerant Fuzzy Engine**: Native fast fzf-like scoring algorithm evaluating word boundaries, CamelCase initials, and substring sequences.

### Non-Goals
- Full background filesystem daemon/indexer running 24/7 (we rely on direct fast `ripgrep` and `fd`).
- Full GUI file manager replacement (no tree-view drag-and-drop or dual-pane directory explorer).
- Arbitrary bash script execution engine (actions are well-defined, safe presets configurable via settings).

### Anti-Goals
- **No UI Stalls**: Content search must never freeze Quickshell's Wayland event loop. Searches must run via debounced asynchronous `Process` child workers.
- **No Drive-by Refactoring**: Preserve existing QML design tokens (`Color.menu`, `BorderSurface`, `Style.space`) and zero-overflow layout guarantees.

---

## 3. Architecture & Technical Details

### Module 1: Ripgrep In-File Content Search
- **Trigger**: Query starts with `?` (e.g. `?import QtQuick`) or user toggles `Ctrl+F`.
- **Command Dispatch**:
  ```bash
  rg --color=never --no-heading --line-number --max-count=1 --smart-case [EXCLUDES] "$QUERY" "$TARGET_DIR" | head -n 80
  ```
- **Parsing**: Parses `filePath:lineNum:lineContent`.
- **UI Presentation**:
  - Result row shows file name with line number badge (e.g. `Core.js:42`).
  - Preview pane automatically highlights and scrolls to the matching line.

### Module 2: Power Actions Popover (`Alt+A` / `Tab`)
- **Trigger**: Pressing `Alt+A` on any selected search result.
- **Actions Matrix**:
  1. `Open Default` (`xdg-open "$FILE"`)
  2. `Open in Terminal` (Spawns user terminal at containing folder, e.g. `kitty --directory "$DIR"`)
  3. `Open in Editor` (`code "$FILE"` or configured editor)
  4. `Copy Relative Path` (Relative to target directory, copied to `wl-copy`)
  5. `Git Diff` (If inside git repo, runs `git diff "$FILE"` in preview)
  6. `Extract Archive` (For `.zip`, `.tar.gz`, `.tar.xz`, `.7z`)
- **Keyboard Navigation**: Up/Down arrows to select, `Enter` to run, `Esc` to dismiss back to results.

### Module 3: Frecency Scoring
- **Storage**: `~/.config/omarchy/recon_frecency.json` (Atomic via `FileView`).
- **Scoring Formula**:
  $$\text{Score} = \text{FuzzyScore} + (\text{AccessCount} \times 10) + \text{RecencyBonus}$$
  where `RecencyBonus` decreases exponentially based on hours since last opened.
- Persists user preferences and dynamically orders search results on identical or empty queries.

### Module 4: In-Place File Operations
- **Rename (`F2`)**:
  - Modal prompt over selected item with current name pre-filled and selected (excluding extension).
  - Pressing `Enter` executes `mv "$OLD" "$NEW"`, updates model, and selects renamed item.
- **New File / Note (`Ctrl+N`)**:
  - Modal prompt: "Create file in [Target Directory]".
  - Enter creates file with `touch "$NEW"` (creating parent directories if specified) and immediately opens in editor.

### Module 5: Typo-Tolerant Fuzzy Matcher (`Fuzzy.js`)
- Embedded JavaScript fuzzy matcher implemented in `script/Fuzzy.js`.
- Evaluates:
  - Exact prefix bonus: +50
  - Word boundary bonus (after `/`, `_`, `-`, `.`): +30
  - CamelCase boundary bonus: +25
  - Consecutive character match bonus: +15
  - Penalty for skipped characters.

---

## 4. Keyboard Shortcuts Specification

| Context | Key | Action |
| :--- | :--- | :--- |
| **Finder** | `?` (prefix) or `Ctrl + F` | Toggle In-File Content Search (Ripgrep mode) |
| **Finder** | `Alt + A` | Open Power Actions menu on selected item |
| **Finder** | `F2` | Rename selected file/folder in-place |
| **Finder** | `Ctrl + N` | Create new file/note in current directory |
| **Power Actions** | `↑` / `↓` + `↵ Enter` | Navigate and execute action |
| **Power Actions** | `Esc` | Return to search results |
| **Inline Modals** | `↵ Enter` / `Esc` | Confirm / Cancel rename or file creation |

---

## 5. Verification Plan
1. **Ripgrep Verification**: Search known string across files in a test directory; verify result paths and line previews.
2. **Action Runner Verification**: Test `Open in Terminal` (Kitty) and `Open in Editor` (Code) on selected file.
3. **Frecency Verification**: Open file, restart Recon, verify file ranks higher on blank query.
4. **Rename/New File Verification**: Rename dummy file via `F2`, create new file via `Ctrl+N`, confirm filesystem changes on disk.
5. **Zero Overflow Verification**: Test all new modals against window boundaries to ensure strict adherence to anchor insets.
