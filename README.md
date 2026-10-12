# omarchy-recon 🔭

A blazing-fast floating file explorer, live previewer, and launcher plugin designed for [Omarchy](https://github.com/omarchy) and Hyprland.

Powered by `foot`, `fzf`, `fd`, and `bat`.

---

## ✨ Features

- ⚡ **Instant Search**: Sub-millisecond indexing of tens of thousands of files via `fd` and POSIX `stat`.
- 📐 **Aligned 4-Column Layout**: Clear display showing `[TYPE]`, `[FILE]`, `[FOLDER]`, and `[SIZE]`.
- 📊 **Dynamic Stats Bar**: Real-time breakdown of file types (`PDF`, `MD`, `CODE`, `JSON`, `OFFICE`, `OTHER`) and total count.
- 📋 **Seamless Auto-Copy**: Selecting text with the mouse inside the preview pane automatically copies it to the Wayland clipboard (`wl-copy`).
- 🛡️ **Clean Text Selection**: Dedicated bottom preview layout prevents terminal wrap-around from polluting preview text selections with file list columns.
- 🔄 **Dynamic Layout Switching**: Toggle instantly between **Bottom**, **Right** (side-by-side), and **Hidden** preview modes via `CTRL+/`.
- 📑 **Rich Document Previews**: Syntax highlighting for code/markdown via `bat`, plain text fallback, and instant text extraction for PDF documents via `pdftotext`.
- 🪟 **True Toggle Window**: Pressing the keybinding toggles the window open and closed instantly. Single `ESC` closes without delay.
- 🚫 **Smart Filtering**: Skips hidden directories (`.*`) by default, with custom exclusion lists.
- 🤖 **AI Agent Ready**: Includes [`AGENT.md`](AGENT.md) for quick customization by any AI coding assistant (Antigravity, Cursor, Claude Code, Copilot).

---

## 📦 Requirements

- **Wayland Compositor**: Hyprland (native Omarchy setup)
- **Terminal**: `foot`
- **Fuzzy Finder**: `fzf`
- **Search Tool**: `fd`
- **Previewer**: `bat`
- **Clipboard**: `wl-clipboard` (`wl-copy`)
- *(Optional)*: `poppler` (`pdftotext`) for PDF text previewing

Install all dependencies on Arch / Omarchy:
```bash
sudo pacman -S foot fzf fd bat wl-clipboard poppler
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

-- Keybinding: SUPER + M to open Recon (with optional path):
o.bind("SUPER + M", "Recon File Search", "omarchy-recon /run/media/hp/SSS")
```

Reload Hyprland:
```bash
hyprctl reload
```

---

## ⌨️ Keybindings

| Shortcut | Action |
| :--- | :--- |
| **`ENTER`** | Open selected file in default desktop application (`xdg-open`) |
| **`CTRL + Y`** | Copy full file path to clipboard and exit |
| **`ALT + Y`** | Copy complete file text content to clipboard and exit |
| **`CTRL + /`** | Rotate preview layout (`Bottom` ➔ `Right` ➔ `Hidden`) |
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

# Initial preview window layout ("down:50%:wrap" or "right:50%:wrap")
PREVIEW_LAYOUT="down:50%:wrap"
```

---

## 🤖 For AI Coding Agents

Want to customize Recon using your AI coding assistant? See [`AGENT.md`](AGENT.md) for architectural maps, variable dictionaries, and prompt recipes for agents.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
