#!/usr/bin/env bash
# ==============================================================================
# omarchy-recon Installer (Native Quickshell QML Overlay)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_TARGET="${HOME}/.local/bin/omarchy-recon"
PLUGIN_TARGET="${HOME}/.config/omarchy/plugins/recon.finder"

echo "==> Installing omarchy-recon..."

# 1. Check dependencies
deps=(fd wl-copy gio xdg-open)
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

if ! command -v pdftotext >/dev/null 2>&1; then
  echo "Note: 'pdftotext' (poppler) is recommended for live PDF previews."
fi

# 2. Register native Omarchy plugin
mkdir -p "${HOME}/.config/omarchy/plugins"
ln -sfn "${SCRIPT_DIR}" "${PLUGIN_TARGET}"
echo "  [OK] Linked plugin: ${PLUGIN_TARGET} -> ${SCRIPT_DIR}"

if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable recon.finder 2>/dev/null || true
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  echo "  [OK] Enabled plugin 'recon.finder' in Omarchy"
fi

# 3. Link executable CLI helper
mkdir -p "${HOME}/.local/bin"
ln -sf "${SCRIPT_DIR}/bin/omarchy-recon" "$BIN_TARGET"
chmod +x "$BIN_TARGET"
echo "  [OK] Linked CLI: ${BIN_TARGET}"

echo ""
echo "==> Installation complete!"
echo ""
echo "Add this to your ~/.config/hypr/bindings.lua:"
echo "  o.bind(\"SUPER + M\", \"File Search (Recon)\", \"omarchy-shell shell toggle recon.finder\")"
echo ""
echo "Then reload Hyprland: hyprctl reload"
