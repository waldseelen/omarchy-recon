import Quickshell
import Quickshell.Io
import QtQuick
import "script/Frecency.js" as Frecency
import "script/Safe.js" as Safe

Item {
  id: store

  property var root: null
  property string home: Quickshell.env("HOME")
  readonly property string configPath: home + "/.config/omarchy/recon.json"
  readonly property string frecencyPath: home + "/.config/omarchy/recon_frecency.json"
  property bool stateReady: false
  property var frecencyData: ({})

  Process {
    id: securePrep
    command: [
      "bash", "-c",
      'umask 077; for f in "$@"; do [ -e "$f" ] || : > "$f"; chmod 600 -- "$f"; done',
      "recon-secure", store.configPath, store.frecencyPath
    ]
    onExited: store.stateReady = true
  }

  Timer {
    id: secureAfterSave
    interval: 400
    repeat: false
    onTriggered: if (!securePrep.running) securePrep.running = true
  }

  Component.onCompleted: securePrep.running = true

  FileView {
    id: configFile
    path: store.stateReady ? store.configPath : ""
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: store.loadConfig(text())
    onLoadFailed: store.saveConfig()
  }

  function loadConfig(raw) {
    if (!root) return
    try {
      var data = JSON.parse(String(raw || "").trim() || "{}")
      var clean = Safe.sanitizeConfig(data, {
        targetDir: root.targetDir,
        excludeDirs: root.excludeDirs,
        excludeExts: root.excludeExts,
        excludeHidden: root.excludeHidden,
        pinnedDirs: root.pinnedDirs,
        previewLayout: root.previewLayout,
        includeIgnored: root.includeIgnored
      })
      root.targetDir = clean.targetDir
      root.excludeDirs = clean.excludeDirs
      root.excludeExts = clean.excludeExts
      root.excludeHidden = clean.excludeHidden
      if (clean.pinnedDirs && clean.pinnedDirs.length > 0) root.pinnedDirs = clean.pinnedDirs
      root.previewLayout = clean.previewLayout
      root.includeIgnored = clean.includeIgnored
    } catch(e) {}
  }

  function saveConfig() {
    if (!root) return
    var payload = {
      targetDir: root.targetDir,
      excludeDirs: root.excludeDirs,
      excludeExts: root.excludeExts,
      excludeHidden: root.excludeHidden,
      pinnedDirs: root.pinnedDirs,
      previewLayout: root.previewLayout,
      includeIgnored: root.includeIgnored
    }
    configFile.setText(JSON.stringify(payload, null, 2) + "\n")
    secureAfterSave.restart()
  }

  FileView {
    id: frecencyFile
    path: store.stateReady ? store.frecencyPath : ""
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text() || "{}")
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) store.frecencyData = parsed
      } catch(e) {}
    }
    onLoadFailed: store.saveFrecency()
  }

  function saveFrecency() {
    frecencyFile.setText(JSON.stringify(store.frecencyData, null, 2) + "\n")
    secureAfterSave.restart()
  }

  function recordFrecency(path) {
    if (!path) return
    store.frecencyData = Frecency.recordAccess(store.frecencyData, path)
    store.saveFrecency()
  }

  function removeFrecency(path) {
    if (!path) return
    store.frecencyData = Frecency.removeAccess(store.frecencyData, path)
    store.saveFrecency()
  }

  function renameFrecency(oldPath, newPath) {
    if (!oldPath || !newPath) return
    store.frecencyData = Frecency.renameAccess(store.frecencyData, oldPath, newPath)
    store.saveFrecency()
  }
}
