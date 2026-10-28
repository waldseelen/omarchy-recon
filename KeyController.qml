import QtQuick
import qs.Commons
import "script/Core.js" as Core
import "script/Safe.js" as Safe

Item {
  id: keyCtrl

  property var root: null
  property var actionCtrl: null
  property var searchCtrl: null
  property var displayModel: null

  function getMarkedCount() {
    if (!root || !root.markedPaths) return 0
    var c = 0
    for (var k in root.markedPaths) {
      if (root.markedPaths[k]) c++
    }
    return c
  }

  function handleKey(event) {
    if (!root) return
    if (root.helpOpen || root.settingsOpen || root.actionsOpen || root.inlineModalOpen) return

    // Quick Help (F1 or Ctrl+/)
    if (event.key === Qt.Key_F1 || ((event.key === Qt.Key_Slash) && (event.modifiers & Qt.ControlModifier))) {
      root.openHelp()
      event.accepted = true
      return
    }

    // Settings (F10 or Ctrl+, or Ctrl+S)
    if (event.key === Qt.Key_F10 ||
        ((event.key === Qt.Key_Comma) && (event.modifiers & Qt.ControlModifier)) ||
        ((event.key === Qt.Key_S) && (event.modifiers & Qt.ControlModifier))) {
      root.settingsOpen = true
      event.accepted = true
      return
    }

    // Toggle Preview Layout (Alt + P)
    if ((event.key === Qt.Key_P) && (event.modifiers & Qt.AltModifier)) {
      root.previewLayout = root.previewLayout === "side" ? "bottom" : "side"
      root.saveConfig()
      event.accepted = true
      return
    }

    // Toggle .gitignore Inclusion (Alt + I)
    if ((event.key === Qt.Key_I) && (event.modifiers & Qt.AltModifier)) {
      root.includeIgnored = !root.includeIgnored
      root.saveConfig()
      if (searchCtrl) searchCtrl.executeSearch()
      event.accepted = true
      return
    }

    // Toggle In-File Search Mode (Ctrl + F)
    if ((event.key === Qt.Key_F) && (event.modifiers & Qt.ControlModifier)) {
      root.isContentSearch = !root.isContentSearch
      if (searchCtrl) searchCtrl.executeSearch()
      event.accepted = true
      return
    }

    // Power Actions Popover (Alt + A)
    if ((event.key === Qt.Key_A) && (event.modifiers & Qt.AltModifier)) {
      if (displayModel && displayModel.count > 0) root.actionsOpen = true
      event.accepted = true
      return
    }

    // In-Place Rename (F2)
    if (event.key === Qt.Key_F2) {
      if (displayModel && displayModel.count > 0) root.startRename()
      event.accepted = true
      return
    }

    // In-Place New File / Note (Ctrl + N)
    if ((event.key === Qt.Key_N) && (event.modifiers & Qt.ControlModifier)) {
      root.startNewFile()
      event.accepted = true
      return
    }

    // Multi-Select Item Toggle (Ctrl + Space)
    if ((event.key === Qt.Key_Space) && (event.modifiers & Qt.ControlModifier)) {
      if (displayModel && displayModel.count > 0) root.toggleMark(root.selectedIndex)
      event.accepted = true
      return
    }

    // Pinned Bookmark Jump: Ctrl+1 to Ctrl+5
    if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier)) {
      if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
        root.jumpBookmark(event.key - Qt.Key_1)
        event.accepted = true
        return
      }
    }

    // Direct Category Switch: Alt+1 to Alt+6
    if (event.modifiers & Qt.AltModifier) {
      if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
        root.setTabByIndex(event.key - Qt.Key_1)
        event.accepted = true
        return
      }
    }

    // Folder Drill-Down (Ctrl + Right) and Drill-Up (Ctrl + Left)
    if ((event.key === Qt.Key_Right) && (event.modifiers & Qt.ControlModifier)) {
      root.drillDownSelected()
      event.accepted = true
      return
    } else if ((event.key === Qt.Key_Left) && (event.modifiers & Qt.ControlModifier)) {
      root.drillUp()
      event.accepted = true
      return
    }

    // Sub-Filter cycling
    if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Right) && (event.modifiers & Qt.AltModifier)) {
      root.cycleSubFilter(1)
      event.accepted = true
      return
    } else if ((event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) && (event.modifiers & Qt.AltModifier)) {
      root.cycleSubFilter(-1)
      event.accepted = true
      return
    }

    // Navigation & Actions
    if (event.key === Qt.Key_Escape) {
      if (getMarkedCount() > 0) root.markedPaths = ({})
      else if (root.filterText) root.setFilter("")
      else root.dismiss()
      event.accepted = true
    } else if (event.key === Qt.Key_Tab) {
      root.cycleTab(event.modifiers & Qt.ShiftModifier ? -1 : 1)
      event.accepted = true
    } else if (event.key === Qt.Key_Backtab) {
      root.cycleTab(-1)
      event.accepted = true
    } else if (event.key === Qt.Key_Up || ((event.key === Qt.Key_K) && (event.modifiers & Qt.ControlModifier))) {
      root.selectDelta(-1)
      event.accepted = true
    } else if (event.key === Qt.Key_Down || ((event.key === Qt.Key_J) && (event.modifiers & Qt.ControlModifier))) {
      root.selectDelta(1)
      event.accepted = true
    } else if (event.key === Qt.Key_PageUp) {
      root.selectDelta(-8)
      event.accepted = true
    } else if (event.key === Qt.Key_PageDown) {
      root.selectDelta(8)
      event.accepted = true
    } else if (event.key === Qt.Key_Home) {
      root.selectAbsolute(0)
      event.accepted = true
    } else if (event.key === Qt.Key_End) {
      if (displayModel) root.selectAbsolute(displayModel.count - 1)
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (displayModel && displayModel.count > 0 && actionCtrl) {
        var it = displayModel.get(root.selectedIndex)
        if (it) {
          if (event.modifiers & Qt.ShiftModifier) actionCtrl.copyPath(it.path)
          else if (event.modifiers & Qt.AltModifier) actionCtrl.revealFolder(it.path, it.isDir)
          else actionCtrl.openItem(it)
        }
      }
      event.accepted = true
    } else if (event.key === Qt.Key_Delete || ((event.key === Qt.Key_D) && (event.modifiers & Qt.ControlModifier))) {
      if (actionCtrl) {
        if (getMarkedCount() > 0) actionCtrl.performBatchTrash(root.getMarkedPathsList())
        else if (displayModel && displayModel.count > 0) {
          var cur = displayModel.get(root.selectedIndex)
          if (cur) actionCtrl.runAction("trash", cur.path, cur.isDir)
        }
      }
      event.accepted = true
    } else if ((event.key === Qt.Key_C) && (event.modifiers & Qt.ControlModifier)) {
      if (actionCtrl) {
        if (getMarkedCount() > 0) actionCtrl.performBatchCopy(root.getMarkedPathsList())
        else if (displayModel && displayModel.count > 0) {
          var cit = displayModel.get(root.selectedIndex)
          if (cit) actionCtrl.copyPath(cit.path)
        }
      }
      event.accepted = true
    } else if (event.key === Qt.Key_Backspace) {
      if (root.filterText.length > 0) root.setFilter(root.filterText.slice(0, -1))
      event.accepted = true
    } else if (Util.editsFilter(event, root.filterText)) {
      root.setFilter(Util.editedFilter(event, root.filterText))
      event.accepted = true
    } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
      root.setFilter(root.filterText + event.text)
      event.accepted = true
    }
  }
}
