import QtQuick
import qs.Commons
import "script/Safe.js" as Safe

Item {
  id: overlays

  property var root: null
  property var actionCtrl: null
  property var searchCtrl: null
  property var displayModel: null
  property var keyCatcher: null

  function initHelpFocus() {
    helpDialog.initFocus()
  }

  function initInlineFocus() {
    inlineModal.initFocus()
  }

  function initActionsFocus() {
    actionsMenu.initFocus()
  }

  function initSettingsFocus() {
    settingsDialog.initFocus()
  }

  function restoreFocus() {
    if (keyCatcher) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  // 1. Power Actions Menu
  PowerActionsMenu {
    id: actionsMenu
    visible: root ? root.actionsOpen : false
    targetPath: displayModel && displayModel.count > 0 && root.selectedIndex < displayModel.count ? displayModel.get(root.selectedIndex).path : ""
    targetName: displayModel && displayModel.count > 0 && root.selectedIndex < displayModel.count ? displayModel.get(root.selectedIndex).name : ""
    targetIsDir: displayModel && displayModel.count > 0 && root.selectedIndex < displayModel.count ? displayModel.get(root.selectedIndex).isDir : false
    targetDir: root ? root.targetDir : ""
    onExecuted: function(actId, p) {
      if (root) root.actionsOpen = false
      if (actionCtrl) actionCtrl.runAction(actId, p, actionsMenu.targetIsDir)
    }
    onClosed: {
      if (root) root.actionsOpen = false
      overlays.restoreFocus()
    }
  }

  // 2. Inline Action Modal (Rename / New File / Duplicate / Move / Trash)
  InlineActionModal {
    id: inlineModal
    visible: root ? root.inlineModalOpen : false
    mode: root ? root.inlineModalMode : "rename"
    targetPath: root ? root.inlineModalPath : ""
    initialValue: root ? root.inlineModalInitial : ""
    onConfirmed: function(m, v, t) {
      if (root) root.inlineModalOpen = false
      if (actionCtrl) actionCtrl.runInlineConfirm(m, v, t)
      overlays.restoreFocus()
    }
    onClosed: {
      if (root) root.inlineModalOpen = false
      overlays.restoreFocus()
    }
  }

  // 3. Quick Keyboard Shortcuts Help
  HelpDialog {
    id: helpDialog
    visible: root ? root.helpOpen : false
    onClosed: {
      if (root) root.helpOpen = false
      overlays.restoreFocus()
    }
  }

  // 4. Settings Dialog
  SettingsDialog {
    id: settingsDialog
    visible: root ? root.settingsOpen : false
    targetDir: root ? root.targetDir : ""
    excludeDirs: root ? root.excludeDirs : []
    excludeExts: root ? root.excludeExts : []
    excludeHidden: root ? root.excludeHidden : true
    onClosed: {
      if (root) root.settingsOpen = false
      overlays.restoreFocus()
    }
    onSaved: function(newTarget, newDirs, newExts, newHidden) {
      if (!root) return
      var clean = Safe.sanitizeConfig(
        { targetDir: newTarget, excludeDirs: newDirs, excludeExts: newExts, excludeHidden: newHidden },
        { targetDir: root.targetDir, excludeDirs: root.excludeDirs, excludeExts: root.excludeExts, excludeHidden: root.excludeHidden })
      root.targetDir = clean.targetDir
      root.excludeDirs = clean.excludeDirs
      root.excludeExts = clean.excludeExts
      root.excludeHidden = clean.excludeHidden
      root.saveConfig()
      root.settingsOpen = false
      if (searchCtrl) searchCtrl.executeSearch()
      overlays.restoreFocus()
    }
  }
}
