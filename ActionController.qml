import Quickshell
import QtQuick
import qs.Commons
import "script/Core.js" as Core
import "script/Safe.js" as Safe

Item {
  id: actionCtrl

  property string targetDir: ""
  property var root: null

  signal searchRequested()
  signal dismissRequested()
  signal recordFrecencyRequested(string path)
  signal removeFrecencyRequested(string path)
  signal renameFrecencyRequested(string oldPath, string newPath)
  signal inlineModalRequested(string mode, string targetPath, string initialValue)

  function openItem(item) {
    if (!item || !Safe.isSafeAbsPath(item.path)) return
    recordFrecencyRequested(item.path)

    if (item.tag === "MATCH" && item.sizeText && String(item.sizeText).charAt(0) === "L") {
      var lineNum = parseInt(String(item.sizeText).substring(1), 10) || 1
      Quickshell.execDetached([
        "bash", "-lc",
        'code -g "$1:$2" 2>/dev/null || nvim "+$2" "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null',
        "recon-jump", item.path, String(lineNum)
      ])
    } else {
      Util.execArgv(["xdg-open", item.path])
    }
    dismissRequested()
  }

  function copyPath(path) {
    if (!Safe.isSafeAbsPath(path)) return
    recordFrecencyRequested(path)
    Quickshell.execDetached(["wl-copy", "--", path])
    dismissRequested()
  }

  function copyUri(path) {
    if (!Safe.isSafeAbsPath(path)) return
    recordFrecencyRequested(path)
    Quickshell.execDetached([
      "bash", "-c",
      'printf "file://%s\\r\\n" "$1" | wl-copy --type text/uri-list',
      "recon-copy-uri", path
    ])
    dismissRequested()
  }

  function copyFileContent(filePath) {
    if (!Safe.isSafeAbsPath(filePath) || Safe.isSensitivePath(filePath)) return
    recordFrecencyRequested(filePath)
    Quickshell.execDetached([
      "bash", "-c",
      'if [ -f "$1" ] && [ -r "$1" ]; then ' +
      '  case "$1" in ' +
      '    *.pdf|*.PDF) if command -v pdftotext >/dev/null 2>&1; then timeout 20 pdftotext "$1" - 2>/dev/null | wl-copy --sensitive; else head -c 8388608 -- "$1" | wl-copy --sensitive; fi ;; ' +
      '    *) head -c 8388608 -- "$1" | wl-copy --sensitive ;; ' +
      '  esac; ' +
      'else ' +
      '  wl-copy -- "$1"; ' +
      'fi',
      "recon-copy", filePath
    ])
    dismissRequested()
  }

  function revealFolder(path, isDir) {
    if (!Safe.isSafeAbsPath(path)) return
    recordFrecencyRequested(path)
    var folder = isDir ? path : Core.getDirName(path)
    if (Safe.isSafeAbsPath(folder)) Util.execArgv(["xdg-open", folder])
    dismissRequested()
  }

  function performTrash(path) {
    if (!Safe.isSafeAbsPath(path)) return
    Util.execArgv(["gio", "trash", "--", path])
    removeFrecencyRequested(path)
    searchRequested()
  }

  function performBatchTrash(paths) {
    if (!Array.isArray(paths) || paths.length === 0) return
    for (var i = 0; i < paths.length; i++) {
      var p = paths[i]
      if (Safe.isSafeAbsPath(p)) {
        Util.execArgv(["gio", "trash", "--", p])
        removeFrecencyRequested(p)
      }
    }
    searchRequested()
  }

  function performBatchCopy(paths) {
    if (!Array.isArray(paths) || paths.length === 0) return
    var joined = paths.filter(Safe.isSafeAbsPath).join("\n")
    Quickshell.execDetached([
      "bash", "-c",
      'cat - | wl-copy',
      "recon-batch-copy"
    ], { stdin: joined })
    dismissRequested()
  }

  function runAction(actionId, path, isDir) {
    if (!Safe.isSafeAbsPath(path)) return
    recordFrecencyRequested(path)
    var folder = isDir ? path : Core.getDirName(path)

    if (actionId === "open") {
      Util.execArgv(["xdg-open", path])
      dismissRequested()
    } else if (actionId === "term") {
      if (Safe.isSafeAbsPath(folder)) {
        Quickshell.execDetached(["bash", "-lc",
          'xdg-terminal-exec --working-directory "$1" 2>/dev/null || foot -D "$1" 2>/dev/null',
          "recon-term", folder])
      }
      dismissRequested()
    } else if (actionId === "editor") {
      Quickshell.execDetached(["bash", "-lc",
        'code "$1" 2>/dev/null || nvim "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null',
        "recon-edit", path])
      dismissRequested()
    } else if (actionId === "copyPath") {
      copyPath(path)
    } else if (actionId === "copyUri") {
      copyUri(path)
    } else if (actionId === "copyRelPath") {
      var rel = path.startsWith(targetDir) ? path.substring(targetDir.length).replace(/^\//, "") : path
      Quickshell.execDetached(["wl-copy", "--", rel])
      dismissRequested()
    } else if (actionId === "copyContent") {
      copyFileContent(path)
    } else if (actionId === "duplicate") {
      var base = Core.getBaseName(path)
      var dot = base.lastIndexOf(".")
      var initial = (dot > 0) ? (base.substring(0, dot) + "-copy" + base.substring(dot)) : (base + "-copy")
      inlineModalRequested("duplicate", path, initial)
    } else if (actionId === "move") {
      inlineModalRequested("move", path, folder)
    } else if (actionId === "trash") {
      inlineModalRequested("trash", path, "yes")
    }
  }

  function runInlineConfirm(mode, val, targetPath) {
    if (!val) return

    if (mode === "trash") {
      var answer = String(val).trim().toLowerCase()
      if (answer === "yes" || answer === "y") performTrash(targetPath)
    } else if (mode === "rename") {
      var name = Safe.sanitizeEntryName(val)
      if (!name || !Safe.isSafeAbsPath(targetPath)) return
      var newPath = Core.getDirName(targetPath) + "/" + name
      Util.execArgv(["mv", "-n", "--", targetPath, newPath])
      renameFrecencyRequested(targetPath, newPath)
      searchRequested()
    } else if (mode === "duplicate") {
      var dupName = Safe.sanitizeEntryName(val)
      if (!dupName || !Safe.isSafeAbsPath(targetPath)) return
      var dupPath = Core.getDirName(targetPath) + "/" + dupName
      Util.execArgv(["cp", "-a", "--", targetPath, dupPath])
      searchRequested()
    } else if (mode === "move") {
      var destDir = val.trim()
      if (!Safe.isSafeAbsPath(destDir) || !Safe.isSafeAbsPath(targetPath)) return
      Util.execArgv(["mv", "-n", "--", targetPath, destDir + "/"])
      renameFrecencyRequested(targetPath, destDir.replace(/\/+$/, "") + "/" + Core.getBaseName(targetPath))
      searchRequested()
    } else if (mode === "newfile") {
      var rel = Safe.sanitizeRelPath(val)
      if (!rel || !Safe.isSafeAbsPath(targetDir)) return
      var newFilePath = Safe.joinInside(targetDir, rel)
      Quickshell.execDetached(["bash", "-lc",
        'mkdir -p -- "$(dirname -- "$1")" && touch -- "$1" && xdg-open "$1" 2>/dev/null',
        "recon-new", newFilePath])
      searchRequested()
    }
  }
}
