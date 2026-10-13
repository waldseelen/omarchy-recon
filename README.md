# Omarchy Recon

> **Native QML File & Directory Finder Overlay for Omarchy / Hyprland (Wayland)**  
> High-performance desktop search, live document/code previewer, in-file ripgrep search, and desktop command center engineered natively with Quickshell QML and Wayland Layer-Shell protocols.

---

## 1. System Overview & Architecture

**Omarchy Recon** is built specifically for Arch Linux and Omarchy Wayland environments. It integrates directly into the `omarchy-shell` runtime as a first-class plugin, eliminating the overhead and latency of external Electron, GTK, or heavyweight search daemons.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Hyprland Compositor                             │
│       (Wayland Layer-Shell Overlay: Exclusive Keyboard Focus)          │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                      ┌────────────▼─────────────┐
                      │    Omarchy Recon (QML)   │
                      │   BorderSurface Glass    │
                      └───────┬──────────────┬───┘
                              │              │
       ┌──────────────────────▼───┐      ┌───▼──────────────────────┐
       │   Asynchronous Search    │      │   Live Preview Pipeline  │
       │  • Substring & Fuzzy     │      │  • Native TextEdit Copy  │
       │  • In-File Ripgrep (?Q)  │      │  • pdftotext Extraction  │
       │  • Frecency Ranking      │      │  • Async Image Loading   │
       └──────────────────────────┘      └──────────────────────────┘
                              │              │
       ┌──────────────────────▼──────────────▼───┐
       │     Atomic State Persistence (JSON)     │
       │         ~/.config/omarchy/recon.json    │
       │     ~/.config/omarchy/recon_frecency.json
       └─────────────────────────────────────────┘
```

- **Runtime**: Quickshell (Qt 6 / QML declarative engine).
- **Surface Protocol**: `WlrLayershell` overlay layer with `WlrKeyboardFocus.Exclusive` and dynamic animated scrim.
- **IPC Architecture**: Controlled via Unix socket IPC (`omarchy-shell shell toggle recon.finder`) and CLI wrapper `omarchy-recon`.
- **Styling**: 100% native Omarchy theme integration using `qs.Commons` and `qs.Ui` design tokens (`Color.menu`, `BorderSurface`, `Style.space`, `Style.cornerRadius`).

---

## 2. Core Capabilities

### 🔍 Target Search & Typo-Tolerant Fuzzy Engine
- **Target Drive Focus**: Configured to search any directory, with native quick toggles for `/run/media/hp/SSS` and `~` (Home).
- **fzf-Like Fuzzy Scorer (`script/Fuzzy.js`)**: Evaluates camelCase boundaries, word separators (`_`, `-`, `/`, `.`), and consecutive character match sequences so abbreviation queries (e.g. `scshot` -> `screenshot.png`) hit immediately.
- **Smart Frecency Ordering (`script/Frecency.js`)**: Automatically boosts frequently opened and recently modified files to the top of search results.
- **Asynchronous Execution**: Background execution prevents UI thread blockages during large drive traversals.
- **Live Search Debounce**: Typing queries updates results dynamically without spawning redundant process cascades.

### 📄 In-File Content Search Mode (Ripgrep)
- **Instant Full-Text Search**: Prefix any search query with `?` (e.g. `?import QtQuick` or `?def calculate`) or press `Ctrl + F` to switch to Ripgrep in-file mode.
- **Line & Snippet Reporting**: Results display the exact matching line number and preview excerpt directly in the list (`Core.js :42 — const foo = bar`).
- **Deep Preview Integration**: Selecting an in-file match loads the document directly with matching content.

### ⚡ Power Actions Context Menu (`Alt + A`)
- Pressing `Alt + A` on any search result opens a sleek, keyboard-driven action popover:
  1. **Open Default**: Launch in system default app (`xdg-open`).
  2. **Open in Terminal**: Open containing folder in terminal (`foot` / `xdg-terminal-exec`).
  3. **Open in Editor**: Open file in code editor (`code` / `nvim`).
  4. **Copy Relative Path**: Copy path relative to search root (clean for code reviews and markdown links).
  5. **Copy File Content**: Dump entire file text directly into Wayland clipboard (`wl-copy`).
  6. **Move to Trash**: Safe trash disposal via `gio trash`.

### ✏️ In-Place File Operations (`F2` Rename & `Ctrl + N` New File)
- **Inline Rename (`F2`)**: Press `F2` on any selected item to open an anchor-based rename modal with current basename pre-filled and extension preserved.
- **Inline New File (`Ctrl + N`)**: Press `Ctrl + N` to create a new file or note directly inside the target search folder and immediately open it in your editor.

### 📄 Interactive Live Preview Pipeline
- **Selectable & Copyable Text Preview**: Embedded `TextEdit` inside a smooth `Flickable` viewport allows mouse text selection and clipboard copying.
- **One-Click Content Copy**: Header `Copy All` button instantly transfers full preview contents to the Wayland clipboard via `wl-copy`.
- **Multi-Format Extraction**:
  - **Source Code & Text**: Instantaneous head extraction for code, markdown, configuration, and plain text.
  - **PDF Documents**: Direct page text extraction using `pdftotext`.
  - **Images**: High-resolution, smooth aspect-fit image rendering for `.png`, `.jpg`, `.jpeg`, `.webp`, `.svg`.
  - **Directories**: Formatted directory hierarchy preview via `ls -1 -p`.

### 🗂️ Hierarchical Categorization & Dynamic Sub-Filters
Filter large file sets across two synchronized layers:
1. **Primary Categories**:
   - `All` — Unified results across all indexed files and directories.
   - `Folders` — Directory-only navigation.
   - `Docs` — Documentation and markdown files.
   - `Code` — Source code scripts and project assets.
   - `Office` — Spreadsheets, presentations, and word documents.
   - `Images` — Vector and raster visual assets.
2. **Dynamic Sub-Filter Chips**:
   Selecting a category dynamically reveals its specific file extension chips with zero UI overflow:
   - **Docs**: `All Docs`, `Markdown (.md)`, `PDF (.pdf)`, `Text (.txt)`, `Org (.org)`
   - **Code**: `All Code`, `.py`, `.js`, `.ts`, `.sh`, `.json`, `.html`, `.css`, `.lua`, `.c / .cpp`, `.rs`
   - **Office**: `All Office`, `Word (.docx)`, `Excel (.xlsx)`, `PPT (.pptx)`, `CSV (.csv)`
   - **Images**: `All Images`, `PNG (.png)`, `JPG (.jpg)`, `WebP (.webp)`, `SVG (.svg)`

### ⚙️ Persistent Settings & Exclusion Manager
A native modal dialog allows live customization of indexing boundaries:
- **Search Target Directory**: Editable text input with instant shortcut buttons for SSS drive and User Home.
- **Excluded Directories**: Visual interactive chip tags (`📁 DOTFILES`, `📁 BRAIN`, `📁 node_modules`, `📁 .git`, etc.).
- **Excluded File Extensions**: Filter out build artifacts or temporary files (`.tmp`, `.bak`, `.log`, `.iso`, etc.).
- **Hidden Dot-Folder Toggle**: One-switch exclusion for all hidden directories (`.*`).
- **Atomic Persistence**: Configurations are automatically stored in `~/.config/omarchy/recon.json`.

---

## 3. Comprehensive Keyboard Reference

Omarchy Recon is designed for 100% keyboard-only workflows. Every internal function is mapped to intuitive keybindings:

### Main Finder Overlay
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| **`SUPER + M`** | **Summon / Dismiss** | Hyprland global shortcut to toggle the finder overlay. |
| **`↵ Enter`** | **Open** | Launch selected file or folder in default application (`xdg-open`). |
| **`⎇ Alt + A`** | **Power Actions** | Open contextual action menu on selected item. |
| **`F2`** | **Rename Item** | Rename selected file/folder in-place. |
| **`Ctrl + N`** | **New File / Note** | Create a new file directly inside the target directory. |
| **`Ctrl + F` / `?`** | **In-File Mode** | Toggle Ripgrep in-file content search mode. |
| **`⇧ Shift + Enter`** | **Copy Path** | Copy absolute path to Wayland clipboard (`wl-copy`) and close. |
| **`⎇ Alt + Enter`** | **Reveal Folder** | Open enclosing folder in the default desktop file manager. |
| **`Ctrl + C`** | **Copy Path** | Copy selected item's absolute path to clipboard. |
| **`Delete` / `Ctrl + D`** | **Move to Trash** | Safely send selected file/directory to system trash (`gio trash`). |
| **`↑` / `Ctrl + K`** | **Move Up** | Select previous result item. |
| **`↓` / `Ctrl + J`** | **Move Down** | Select next result item. |
| **`PageUp` / `PageDown`** | **Page Scroll** | Jump 8 items up or down. |
| **`Home` / `End`** | **Jump Bounds** | Select first or last item in the result list. |
| **`Tab`** | **Next Category** | Cycle category filter forward (`All` → `Folders` → `Docs` → ...). |
| **`⇧ Shift + Tab`** | **Prev Category** | Cycle category filter backward. |
| **`Alt + 1` .. `Alt + 6`** | **Direct Tab Jump** | Direct jump to category index (1: All, 2: Folders, 3: Docs, etc.). |
| **`Ctrl + →` / `Ctrl + Tab`** | **Next Sub-Filter** | Cycle through active category sub-filter chips (e.g. `.md` → `.pdf`). |
| **`Ctrl + ←` / `Ctrl + ⇧Tab`** | **Prev Sub-Filter** | Cycle sub-filter chips backward. |
| **`F10` / `Ctrl + S` / `^,`** | **Open Settings** | Toggle the settings and exclusions dialog. |
| **`Esc`** | **Clear / Close** | Clears search query if non-empty; dismisses overlay if search is clear. |

### Settings & Exclusions Modal
| Keybinding | Action | Description |
| :--- | :--- | :--- |
| **`Tab` / `⇧ Shift + Tab`** | **Field Navigation** | Cycles focus through Target Dir → Folder Excludes → Hidden Toggle → Ext Excludes → Buttons. |
| **`↵ Enter` (in Add Folder)** | **Add Folder Chip** | Adds folder to exclusion list and clears input for rapid entry. |
| **`⌫ Backspace` (empty input)**| **Remove Last Chip** | Deletes the most recent exclusion chip. |
| **`↵ Enter` (in Add Ext)** | **Add Ext Chip** | Adds file extension to exclusion list and clears input. |
| **`Space` / `↵ Enter` (Checkbox)**| **Toggle Hidden** | Toggles exclusion of all hidden dot-directories (`.*`). |
| **`Ctrl + ↵` / `Ctrl + S`** | **Save & Apply** | Commits changes to disk, reapplies filters, and refreshes search. |
| **`Ctrl + R`** | **Reset Defaults** | Restores factory default paths and exclusions. |
| **`Esc` / `F10`** | **Cancel / Close** | Closes the modal without applying unsaved modifications. |

---

## 4. Architectural Comparison

| Dimension | Omafinder | shafayet.finder | WindowPeek | **Omarchy Recon** |
| :--- | :---: | :---: | :---: | :---: |
| **Rendering Framework** | Quickshell QML | Quickshell QML | Quickshell QML | **Quickshell QML** |
| **Native BorderSurface Glass** | Basic | Partial | Basic | **Full Acrylic / Tokens** |
| **Interactive Text Preview** | None | Read-only static text | None | **Selectable & Copyable `TextEdit`** |
| **In-File Content Search** | None | None | None | **Ripgrep (`?query` / `Ctrl+F`)** |
| **Contextual Power Actions** | None | None | None | **`Alt+A` (Terminal, Editor, Diff)** |
| **In-Place File Operations** | None | None | None | **`F2` Rename & `Ctrl+N` New File** |
| **Frecency & Fuzzy Scoring** | Alphabetical | Basic substring | Window order | **fzf Scoring + Frecency Ranking** |
| **Multi-Format Extraction** | None | Text only | None | **Code, Plaintext, PDF, Images, Dirs** |
| **Sub-Filter Refinements** | None | Fixed tabs | None | **Dynamic 2-Tier Extension Chips** |
| **Exclusions Management** | Hardcoded | Hardcoded | None | **Live GUI & Persistent JSON Engine** |
| **100% Keyboard Operability** | Search only | Partial | Window switch | **Full Finder & Modal Keyboard Control** |
| **Layout Stability** | Fixed sizing | Overflow issues | Fixed sizing | **Anchor-based Elastic Zero-Overflow** |

---

## 5. Configuration Schema

Settings are saved automatically to `~/.config/omarchy/recon.json`:

```json
{
  "targetDir": "/run/media/hp/SSS",
  "excludeDirs": [
    "DOTFILES",
    "BRAIN",
    "KUBUNTU",
    "WIN",
    "MEDIA",
    ".Trash-1000",
    "node_modules",
    ".git"
  ],
  "excludeExts": [
    "tmp",
    "bak",
    "log",
    "iso",
    "bin"
  ],
  "excludeHidden": true
}
```

Frecency history is maintained in `~/.config/omarchy/recon_frecency.json`.

---

## 6. Installation & Integration

### Symlink Plugin
```bash
ln -sfn /home/hp/Work/omarchy-recon ~/.config/omarchy/plugins/recon.finder
```

### Enable in Omarchy Shell
```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable recon.finder
omarchy restart shell
```

### Hyprland Keybinding
Add the shortcut in `~/.config/hypr/bindings.lua`:
```lua
o.bind("SUPER + M", "File Search (Recon)", "omarchy-shell shell toggle recon.finder")
```

Reload Hyprland bindings:
```bash
hyprctl reload
```

Summon Recon anytime using **`SUPER + M`**.
