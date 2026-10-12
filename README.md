# Omarchy Recon (Native QML File & Directory Finder Overlay)

> **Ultra-fast, native frosted-glass file finder, previewer, and launcher overlay for Omarchy.** Built with Quickshell QML, Hyprland Wayland layer-shell, and instant live preview.

---

## ✨ Features That Outperform Competitors

| Feature | Omafinder | shafayet.finder | **Omarchy Recon** |
| :--- | :---: | :---: | :---: |
| **Native Omarchy Frosted UI** | ✅ (BorderSurface) | ✅ (BorderSurface) | ✅ **Full acrylic styling & tokens** |
| **Interactive Text Preview** | ❌ (No preview) | ⚠️ (Static Text, unselectable) | ✅ **Mouse Select & Copy (`TextEdit`)** |
| **Live Document / Code Preview**| ❌ | ✅ | ✅ **Instant `head` & `pdftotext`** |
| **Full Image Previews** | ❌ | ⚠️ | ✅ **Aspect-fit async Image preview** |
| **Exclusion Filtering** | ⚠️ | ⚠️ | ✅ **Custom excludes + hidden dotfiles** |
| **Category Filter Chips** | ❌ | ✅ | ✅ **Tab / Click: All, Dirs, Docs, Code...** |
| **Ergonomic Keyboard Shortcuts** | ✅ | ⚠️ | ✅ **Open, Copy Path, Reveal, Trash** |

---

## ⚡ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`↵ Enter`** | Open selected file or folder in default desktop app (`xdg-open`) |
| **`⇧ Shift + Enter`** | Copy file path to Wayland clipboard (`wl-copy`) and close |
| **`⎇ Alt + Enter`** | Reveal item in desktop file manager |
| **`Tab` / `⇧ Shift + Tab`** | Cycle category filter tabs (`All` → `Folders` → `Docs` → `Code` → `PDF` → `Office` → `Images`) |
| **`Ctrl + D` / `Delete`** | Safely move file to trash (`gio trash`) |
| **`Ctrl + C`** | Copy file path to clipboard |
| **`Esc`** | Clear search query (if text exists) or close overlay immediately |
| **Mouse Drag & Click** | **Select and copy text directly inside the preview pane!** |

---

## 📦 Installation & Setup

### 1. Enable the Plugin in Omarchy
```bash
# Link the repo into Omarchy plugins directory
ln -sfn /home/hp/Work/omarchy-recon ~/.config/omarchy/plugins/recon.finder

# Rescan and enable plugin
omarchy-shell shell rescanPlugins
omarchy plugin enable recon.finder
omarchy restart shell
```

### 2. Configure Keybinding in Hyprland
In `~/.config/hypr/bindings.lua`:
```lua
-- Super+M: Fast File Search (Omarchy Recon)
o.bind("SUPER + M", "File Search (Recon)", "omarchy-shell shell toggle recon.finder")
```

Then reload Hyprland:
```bash
hyprctl reload
```

Press **`SUPER + M`** to summon Recon instantly!
