#!/usr/bin/env bash
# ==============================================================================
# omarchy-recon Installer
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${HOME}/.local/bin/omarchy-recon"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
CONFIG_FILE="${CONFIG_DIR}/recon.conf"

echo "==> Installing omarchy-recon..."

# 1. Check dependencies
deps=(fd fzf foot bat wl-copy)
missing=()
for dep in "${deps[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    missing+=("$dep")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Warning: The following dependencies are missing: ${missing[*]}"
  echo "Please install them via pacman: sudo pacman -S ${missing[*]}"
fi

# Optional dependency check
if ! command -v pdftotext >/dev/null 2>&1; then
  echo "Note: 'pdftotext' (poppler) is optional but recommended for PDF previews."
fi

# 2. Link executable
mkdir -p "${HOME}/.local/bin"
ln -sf "${SCRIPT_DIR}/bin/omarchy-recon" "$BIN_TARGET"
chmod +x "$BIN_TARGET"
echo "  [OK] Linked ${BIN_TARGET} -> ${SCRIPT_DIR}/bin/omarchy-recon"

# 3. Create default config if not present
mkdir -p "$CONFIG_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "${SCRIPT_DIR}/config/recon.conf.example" "$CONFIG_FILE"
  echo "  [OK] Created default config at ${CONFIG_FILE}"
else
  echo "  [INFO] Existing config preserved at ${CONFIG_FILE}"
fi

# 4. Instructions for Hyprland keybinding
echo ""
echo "==> Installation complete!"
echo ""
echo "To enable the floating window rule and keybinding, add this to your ~/.config/hypr/bindings.lua:"
echo ""
echo "  o.window(\"omarchy-recon.float\", { float = true, center = true, size = { 1350, 780 } })"
echo "  o.bind(\"SUPER + M\", \"Recon File Search\", \"omarchy-recon\")"
echo ""
echo "Then reload Hyprland: hyprctl reload"
