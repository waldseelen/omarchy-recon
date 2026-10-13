#!/usr/bin/env bash
# ==============================================================================
# omarchy-recon Safe Uninstaller
# ==============================================================================
set -euo pipefail

BIN_TARGET="${HOME}/.local/bin/omarchy-recon"
PLUGIN_TARGET="${HOME}/.config/omarchy/plugins/waldseelen.recon"
OLD_PLUGIN_TARGET="${HOME}/.config/omarchy/plugins/recon.finder"

echo "==> Uninstalling omarchy-recon (waldseelen.recon)..."

# 1. Disable plugin in Omarchy
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable waldseelen.recon 2>/dev/null || true
  omarchy plugin disable recon.finder 2>/dev/null || true
  echo "  [OK] Disabled plugin in Omarchy shell"
fi

# 2. Remove plugin links / directories
if [[ -L "${PLUGIN_TARGET}" || -d "${PLUGIN_TARGET}" ]]; then
  rm -rf "${PLUGIN_TARGET}"
  echo "  [OK] Removed plugin directory: ${PLUGIN_TARGET}"
fi

if [[ -L "${OLD_PLUGIN_TARGET}" || -d "${OLD_PLUGIN_TARGET}" ]]; then
  rm -rf "${OLD_PLUGIN_TARGET}"
  echo "  [OK] Removed legacy plugin link: ${OLD_PLUGIN_TARGET}"
fi

# 3. Rescan plugins
if command -v omarchy-shell >/dev/null 2>&1; then
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  echo "  [OK] Rescanned Omarchy shell plugins"
fi

# 4. Remove CLI helper
if [[ -e "${BIN_TARGET}" ]]; then
  rm -f "${BIN_TARGET}"
  echo "  [OK] Removed CLI helper: ${BIN_TARGET}"
fi

echo ""
echo "==> Removal complete!"
echo "Remember to remove the SUPER + M keybind from ~/.config/hypr/bindings.lua if no longer needed."
