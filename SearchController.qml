import Quickshell
import Quickshell.Io
import QtQuick
import "script/Core.js" as Core
import "script/Fuzzy.js" as Fuzzy
import "script/Frecency.js" as Frecency
import "script/Safe.js" as Safe

Item {
  id: searchCtrl

  property var displayModel: null
  property bool isSearching: false
  property string filterText: ""
  property bool isContentSearch: false
  property string targetDir: ""
  property string activeTab: "all"
  property string activeSubFilter: "all"
  property var excludeDirs: []
  property var excludeExts: []
  property bool excludeHidden: true
  property bool includeIgnored: false
  property var frecencyData: ({})
  property string home: Quickshell.env("HOME")
  property bool active: true

  signal searchCompleted(int count)

  Timer {
    id: searchDebounce
    interval: 100
    repeat: false
    onTriggered: searchCtrl.executeSearch()
  }

  function triggerSearch() {
    searchDebounce.restart()
  }

  function cancelSearch() {
    searchDebounce.stop()
    if (searchProc.running) searchProc.running = false
    isSearching = false
  }

  function executeSearch() {
    if (!active || !displayModel) return
    var rawQ = filterText.trim()
    var isRg = isContentSearch || rawQ.startsWith("?")
    var q = rawQ.startsWith("?") ? rawQ.slice(1).trim() : rawQ

    if (isRg && !q) {
      displayModel.clear()
      isSearching = false
      searchCompleted(0)
      return
    }

    var built = Safe.buildSearch({
      isRg: isRg,
      q: q,
      target: targetDir,
      excludeDirs: excludeDirs,
      excludeExts: excludeExts,
      excludeHidden: excludeHidden,
      includeIgnored: includeIgnored,
      tab: activeTab,
      sub: activeSubFilter
    })

    if (searchProc.running) searchProc.running = false
    isSearching = true
    searchProc.environment = built.env
    searchProc.command = built.argv
    searchProc.running = true
  }

  Process {
    id: searchProc
    stdout: StdioCollector {
      id: searchOutput
      waitForEnd: true
    }
    onExited: function(code) {
      isSearching = false
      if (!active || !displayModel) return
      displayModel.clear()
      var raw = String(searchOutput.text || "").trim()
      if (!raw) {
        searchCompleted(0)
        return
      }

      var rawQ = filterText.trim()
      var isRg = isContentSearch || rawQ.startsWith("?")
      var q = rawQ.startsWith("?") ? rawQ.slice(1).trim() : rawQ
      var lines = raw.split("\n")

      if (isRg) {
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (!line) continue
          var firstColon = line.indexOf(":")
          if (firstColon === -1) continue
          var secondColon = line.indexOf(":", firstColon + 1)
          if (secondColon === -1) continue
          var fullPath = line.substring(0, firstColon)
          var lineNum = line.substring(firstColon + 1, secondColon)
          var matchText = line.substring(secondColon + 1).trim()

          var name = Core.getBaseName(fullPath) + " :" + lineNum
          var dir = Core.collapsePath(Core.getDirName(fullPath), home, targetDir) + " — " + matchText
          displayModel.append({
            path: fullPath,
            name: name,
            dir: dir,
            sizeText: "L" + lineNum,
            tag: "MATCH",
            isDir: false,
            bytes: 0
          })
        }
      } else {
        var scoredItems = []
        for (var j = 0; j < lines.length; j++) {
          var lineStr = lines[j]
          if (!lineStr) continue
          var parts = lineStr.split("\t")
          if (parts.length < 3) continue
          var type = parts[0]
          var bytes = parseInt(parts[1], 10) || 0
          var path = parts[2]
          var isDir = (type === "directory")
          var baseName = Core.getBaseName(path) + (isDir ? "/" : "")
          var collapsedDir = Core.collapsePath(Core.getDirName(path), home, targetDir)
          var size = isDir ? "DIR" : Core.formatBytes(bytes)
          var tagBadge = Core.getTag(path, isDir)

          var fz = q ? Fuzzy.score(q, baseName) : { score: 1 }
          if (!fz && q) fz = Fuzzy.score(q, path)
          var frecency = Frecency.getScore(frecencyData, path)
          var totalScore = (fz ? fz.score : 0) + frecency

          scoredItems.push({
            data: {
              path: path,
              name: baseName,
              dir: collapsedDir,
              sizeText: size,
              tag: tagBadge,
              isDir: isDir,
              bytes: bytes
            },
            score: totalScore
          })
        }

        scoredItems.sort(function(a, b) { return b.score - a.score })
        for (var k = 0; k < scoredItems.length; k++) {
          displayModel.append(scoredItems[k].data)
        }
      }

      searchCompleted(displayModel.count)
    }
  }
}
