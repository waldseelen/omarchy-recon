# omarchy-recon 🔭

A blazing-fast floating file & directory explorer, live previewer, and launcher plugin designed for [Omarchy](https://github.com/omarchy) and Hyprland.

Powered by `foot`, `fzf`, `fd`, `bat`, `eza`, and `chafa`.

---

## ✨ Features

- ⚡ **Instant Search**: Sub-millisecond indexing of tens of thousands of files and directories via `fd` and POSIX `stat`.
- 📐 **Aligned 4-Column Layout**: Clear tabular display showing `[TYPE]`, `[FILE]`, `[FOLDER]`, and `[SIZE]`.
- 📊 **Dynamic Stats Bar**: Real-time breakdown of item types (`DIR`, `PDF`, `MD`, `CODE`, `OFFICE`, `OTHER`) and total count.
- 🎯 **Instant Category Filters**:
  - `ALT+A` (All items)
  - `ALT+F` (Directories only)
  - `ALT+D` (Documents & Markdown)
  - `ALT+C` (Source Code)
  - `ALT+P` (PDFs only)
  - `ALT+O` (Office files)
- 🗂️ **Multi-Format Live Previews**:
  - **Directories**: Formatted colored directory trees via `eza` / `tree`.
  - **Code & Markdown**: Syntax-highlighted text via `bat`.
  - **PDFs**: Text extraction via `pdftotext`.
  - **Images**: High-resolution terminal graphics via `chafa` (with metadata fallback).
- ⌨️ **Rich Keyboard Actions**:
  - `ENTER`: Open file or folder in default desktop application.
  - `CTRL+T`: Open terminal directly inside selected item's directory (`xdg-terminal-exec`).
  - `CTRL+O`: Reveal folder in desktop file manager (`xdg-open`).
  - `CTRL+E`: Edit file in terminal editor (`$EDITOR` / `nvim`).
  - `CTRL+DEL`: Safely move item to desktop trash (`gio trash`).
  - `CTRL+Y`: Copy absolute file path to clipboard (`wl-copy`).
  - `ALT+Y`: Copy complete file text contents to clipboard (`wl-copy`).
- 📋 **Seamless Auto-Copy**: Selecting text with the mouse inside the preview pane automatically copies it to the Wayland clipboard (`wl-copy`).
- 🛡️ **Clean Text Selection**: Dedicated bottom preview layout prevents terminal wrap-around from polluting preview text selections with file list columns.
- 🔄 **Dynamic Layout Switching**: Toggle instantly between **Bottom**, **Right** (side-by-side), and **Hidden** preview modes via `CTRL+/`.
- 🪟 **True Toggle Window**: Pressing the keybinding toggles the window open and closed instantly. Single `ESC` closes without delay.
- 🚫 **Smart Filtering**: Skips hidden directories (`.*`) by default, with custom exclusion lists.
- 🤖 **AI Agent Ready**: Includes [`AGENT.md`](AGENT.md) for quick customization by any AI coding assistant.

---

## 📦 Requirements

- **Wayland Compositor**: Hyprland (native Omarchy setup)
- **Terminal**: `foot`
- **Fuzzy Finder**: `fzf`
- **Search Tool**: `fd`
- **Previewer**: `bat`, `eza`
- **Clipboard & Actions**: `wl-clipboard` (`wl-copy`), `glib2` (`gio`), `xdg-terminal-exec`
- *(Optional)*: `poppler` (`pdftotext`) for PDF text extraction, `chafa` for terminal image rendering

Install all dependencies on Arch / Omarchy:
```bash
sudo pacman -S --needed foot fzf fd bat eza wl-clipboard poppler chafa
```

---

## 🚀 Installation

Clone and install:
```bash
git clone https://github.com/your-username/omarchy-recon.git ~/Work/omarchy-recon
cd ~/Work/omarchy-recon
./install.sh
```

### Hyprland Keybinding
Add the window rule and binding to your `~/.config/hypr/bindings.lua`:

```lua
-- Recon Floating Window Rules
o.window("omarchy-recon.float", { float = true })
o.window("omarchy-recon.float", { center = true })
o.window("omarchy-recon.float", { size = { 1350, 780 } })

-- Keybinding: SUPER + M to open Recon:
o.bind("SUPER + M", "Recon File Search", "omarchy-recon /run/media/hp/SSS")
```

Reload Hyprland:
```bash
hyprctl reload
```

---

## ⌨️ Keybindings Reference

| Shortcut | Action |
| :--- | :--- |
| **`ENTER`** | Open file or folder in default application (`xdg-open`) |
| **`CTRL + T`** | Open terminal in selected item's directory (`xdg-terminal-exec`) |
| **`CTRL + O`** | Reveal selected item in desktop file manager (`xdg-open $(dirname ...)`) |
| **`CTRL + E`** | Edit file in terminal editor (`$EDITOR` / `nvim`) |
| **`CTRL + Y`** | Copy full file path to clipboard and exit |
| **`ALT + Y`** | Copy full file text content to clipboard and exit |
| **`CTRL + DEL`** | Move item to desktop trash (`gio trash`) |
| **`CTRL + /`** | Rotate preview layout (`Bottom` ➔ `Right` ➔ `Hidden`) |
| **`ALT + A`** | Filter: All items (clear filter) |
| **`ALT + F`** | Filter: Folders only (`[DIR]`) |
| **`ALT + D`** | Filter: Documents & Markdown (`[MD]`) |
| **`ALT + C`** | Filter: Source code (`[CODE]`) |
| **`ALT + P`** | Filter: PDF documents (`[PDF]`) |
| **`ALT + O`** | Filter: Office documents (`[OFFICE]`) |
| **`PAGE UP / DOWN`** | Scroll preview pane up or down |
| **`ESC`** | Close Recon immediately |
| **`MOUSE SELECT`** | Highlight preview text to automatically copy to clipboard |

---

## ⚙️ Configuration

A configuration file is located at `~/.config/omarchy/recon.conf`:

```bash
# Target directory to search (overridden by CLI argument $1)
TARGET_DIR="${HOME}"

# Space-separated list of folder names to exclude
EXCLUDE_DIRS="DOTFILES BRAIN KUBUNTU WIN MEDIA .Trash-1000 .trash .git node_modules __pycache__ .venv"

# Whether to include hidden files (true / false)
INCLUDE_HIDDEN="false"

# Whether to include directories (true / false)
INCLUDE_DIRS="true"

# Initial preview window layout ("down:50%:wrap" or "right:50%:wrap")
PREVIEW_LAYOUT="down:50%:wrap"
```

---

## 🤖 For AI Coding Agents

Want to customize Recon using your AI coding assistant? See [`AGENT.md`](AGENT.md) for architectural maps, variable dictionaries, and prompt recipes for agents.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
