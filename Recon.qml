import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "script/Core.js" as Core

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property string home: Quickshell.env("HOME")
  property string targetDir: "/run/media/hp/SSS"
  property string filterText: ""
  property string activeTab: "all"
  property string activeSubFilter: "all"
  property int selectedIndex: 0
  property bool cursorActive: true
  property bool isSearching: false
  property bool isAnimatingOut: false
  property int animationDurationIn: 130
  property int animationDurationOut: 80

  // Settings State
  property bool settingsOpen: false
  property var excludeDirs: ["DOTFILES", "BRAIN", "KUBUNTU", "WIN", "MEDIA", ".Trash-1000", "node_modules", ".git"]
  property var excludeExts: ["tmp", "bak", "log", "iso", "bin"]
  property bool excludeHidden: true

  // Preview state
  property string previewContent: ""
  property string previewPath: ""
  property string previewName: ""
  property string previewTag: ""
  property string previewSize: ""
  property bool previewIsImage: false
  property bool previewIsDir: false
  property bool previewLoading: false

  // Native Omarchy UI Theme tokens
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.family
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int footerHeight: Style.space(26)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(1040), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(660), panel.height - Style.gapsOut * 2)

  // ---- Settings Persistence ----
  FileView {
    id: configFile
    path: root.home + "/.config/omarchy/recon.json"
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onLoadFailed: root.saveConfig()
  }

  function loadConfig(raw) {
    try {
      var data = JSON.parse(String(raw || "").trim() || "{}")
      if (data.targetDir && typeof data.targetDir === "string") root.targetDir = data.targetDir
      if (Array.isArray(data.excludeDirs)) root.excludeDirs = data.excludeDirs
      if (Array.isArray(data.excludeExts)) root.excludeExts = data.excludeExts
      if (typeof data.excludeHidden === "boolean") root.excludeHidden = data.excludeHidden
    } catch(e) {}
  }

  function saveConfig() {
    var payload = {
      targetDir: root.targetDir,
      excludeDirs: root.excludeDirs,
      excludeExts: root.excludeExts,
      excludeHidden: root.excludeHidden
    }
    configFile.setText(JSON.stringify(payload, null, 2) + "\n")
  }

  // ---- Lifecycle ----
  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch(e) { payload = {} }
    if (payload.dir && typeof payload.dir === "string") {
      root.targetDir = payload.dir
    }
    root.opened = true
    root.isAnimatingOut = false
    root.settingsOpen = false
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    root.activeTab = "all"
    root.activeSubFilter = "all"
    displayModel.clear()
    clearPreview()
    root.executeSearch()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
    root.isAnimatingOut = false
    root.settingsOpen = false
    if (searchProc.running) searchProc.running = false
    if (previewProc.running) previewProc.running = false
    searchDebounce.stop()
    previewDebounce.stop()
  }

  function dismiss() {
    if (root.settingsOpen) {
      root.settingsOpen = false
      return
    }
    if (root.isAnimatingOut) return
    root.isAnimatingOut = true
    if (searchProc.running) searchProc.running = false
    if (previewProc.running) previewProc.running = false
    searchDebounce.stop()
    previewDebounce.stop()
    dismissTimer.restart()
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  Timer {
    id: dismissTimer
    interval: root.animationDurationOut
    repeat: false
    onTriggered: {
      root.opened = false
      root.isAnimatingOut = false
      if (root.shell && typeof root.shell.hide === "function") {
        root.shell.hide(root.manifest ? root.manifest.id : "recon.finder")
      }
    }
  }

  // ---- Navigation & Selection ----
  function setFilter(text) {
    root.filterText = text
    searchDebounce.restart()
  }

  function setActiveTab(tab) {
    if (root.activeTab === tab && root.activeSubFilter === "all") return
    root.activeTab = tab
    root.activeSubFilter = "all"
    searchDebounce.restart()
  }

  function setActiveSubFilter(ext) {
    if (root.activeSubFilter === ext) return
    root.activeSubFilter = ext
    searchDebounce.restart()
  }

  function cycleTab(delta) {
    var tabs = ["all", "folders", "docs", "code", "office", "images"]
    var idx = tabs.indexOf(root.activeTab)
    if (idx === -1) idx = 0
    var nextIdx = (idx + delta + tabs.length) % tabs.length
    root.setActiveTab(tabs[nextIdx])
  }

  function select(delta) {
    if (displayModel.count === 0) return
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(displayModel.count - 1, root.selectedIndex + delta))
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    previewDebounce.restart()
  }

  function selectAbsolute(index) {
    if (displayModel.count === 0) return
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(displayModel.count - 1, index))
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    previewDebounce.restart()
  }

  function openSelected() {
    if (displayModel.count === 0) return
    var item = displayModel.get(root.selectedIndex)
    if (item && item.path) {
      Util.execDetached("xdg-open " + Util.shellQuote(item.path))
    }
    root.dismiss()
  }

  function copySelectedPath() {
    if (displayModel.count === 0) return
    var item = displayModel.get(root.selectedIndex)
    if (item && item.path) {
      Util.execDetached("wl-copy " + Util.shellQuote(item.path))
    }
    root.dismiss()
  }

  function revealSelectedFolder() {
    if (displayModel.count === 0) return
    var item = displayModel.get(root.selectedIndex)
    if (item && item.path) {
      var folder = item.isDir ? item.path : Core.getDirName(item.path)
      Util.execDetached("xdg-open " + Util.shellQuote(folder))
    }
    root.dismiss()
  }

  function trashSelected() {
    if (displayModel.count === 0) return
    var item = displayModel.get(root.selectedIndex)
    if (item && item.path) {
      Util.execDetached("gio trash " + Util.shellQuote(item.path))
      displayModel.remove(root.selectedIndex)
      if (root.selectedIndex >= displayModel.count) root.selectedIndex = Math.max(0, displayModel.count - 1)
      if (displayModel.count > 0) root.executePreview()
      else root.clearPreview()
    }
  }

  function clearPreview() {
    root.previewContent = ""
    root.previewPath = ""
    root.previewName = ""
    root.previewTag = ""
    root.previewSize = ""
    root.previewIsImage = false
    root.previewIsDir = false
    root.previewLoading = false
  }

  // ---- Search Engine ----
  Timer {
    id: searchDebounce
    interval: 100
    repeat: false
    onTriggered: root.executeSearch()
  }

  function executeSearch() {
    if (!root.opened) return
    var target = root.targetDir
    var q = root.filterText.trim()
    var tab = root.activeTab
    var sub = root.activeSubFilter

    var typeFlags = ""
    if (tab === "folders") {
      typeFlags = "-t d"
    } else if (tab === "docs") {
      if (sub === "md") typeFlags = "-t f -e md"
      else if (sub === "pdf") typeFlags = "-t f -e pdf"
      else if (sub === "txt") typeFlags = "-t f -e txt"
      else if (sub === "org") typeFlags = "-t f -e org"
      else typeFlags = "-t f -e md -e txt -e org -e pdf"
    } else if (tab === "code") {
      if (sub === "all") typeFlags = "-t f -e py -e js -e ts -e html -e css -e lua -e c -e cpp -e rs -e go -e json"
      else if (sub === "c") typeFlags = "-t f -e c -e cpp -e h -e hpp"
      else typeFlags = "-t f -e " + sub
    } else if (tab === "office") {
      if (sub === "all") typeFlags = "-t f -e docx -e doc -e odt -e xlsx -e pptx -e csv"
      else typeFlags = "-t f -e " + sub
    } else if (tab === "images") {
      if (sub === "all") typeFlags = "-t f -e png -e jpg -e jpeg -e webp -e gif -e svg"
      else if (sub === "jpg") typeFlags = "-t f -e jpg -e jpeg"
      else typeFlags = "-t f -e " + sub
    }

    var excludeFlags = ""
    for (var i = 0; i < root.excludeDirs.length; i++) {
      var d = String(root.excludeDirs[i] || "").trim()
      if (d) excludeFlags += " --exclude " + Util.shellQuote(d)
    }
    for (var j = 0; j < root.excludeExts.length; j++) {
      var ext = String(root.excludeExts[j] || "").trim().replace(/^\./, "")
      if (ext) excludeFlags += " -E '*." + ext + "'"
    }

    var hiddenFlag = root.excludeHidden ? "" : "-H"
    var depthFlag = q ? "" : "--max-depth 3"
    var quotedTarget = Util.shellQuote(target)
    var patternArg = q ? Util.shellQuote(q) : "''"

    var cmd = "t=" + quotedTarget + "; [[ ! -d \"$t\" ]] && t=\"$HOME\"; " +
              "fd -i " + hiddenFlag + " " + excludeFlags + " " +
              typeFlags + " " + depthFlag + " " + patternArg + " \"$t\" 2>/dev/null | head -n 250 | xargs -d '\\n' -r stat --printf='%F\\t%s\\t%n\\n' 2>/dev/null"

    if (searchProc.running) searchProc.running = false
    root.isSearching = true
    searchProc.command = ["bash", "-c", cmd]
    searchProc.running = true
  }

  Process {
    id: searchProc
    stdout: StdioCollector {
      id: searchOutput
      waitForEnd: true
    }
    onExited: function(code) {
      root.isSearching = false
      if (!root.opened) return
      displayModel.clear()
      var raw = String(searchOutput.text || "").trim()
      if (raw) {
        var lines = raw.split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (!line) continue
          var parts = line.split("\t")
          if (parts.length < 3) continue
          var type = parts[0]
          var bytes = parseInt(parts[1], 10) || 0
          var fullPath = parts[2]
          var isDir = (type === "directory")
          var name = Core.getBaseName(fullPath) + (isDir ? "/" : "")
          var dir = Core.collapsePath(Core.getDirName(fullPath), root.home, root.targetDir)
          var sizeText = isDir ? "DIR" : Core.formatBytes(bytes)
          var tag = Core.getTag(fullPath, isDir)

          displayModel.append({
            path: fullPath,
            name: name,
            dir: dir,
            sizeText: sizeText,
            tag: tag,
            isDir: isDir,
            bytes: bytes
          })
        }
      }
      if (displayModel.count === 0) {
        root.selectedIndex = 0
        root.clearPreview()
      } else {
        if (root.selectedIndex >= displayModel.count) root.selectedIndex = displayModel.count - 1
        if (root.selectedIndex < 0) root.selectedIndex = 0
        root.executePreview()
      }
    }
  }

  // ---- Preview Engine ----
  Timer {
    id: previewDebounce
    interval: 80
    repeat: false
    onTriggered: root.executePreview()
  }

  function executePreview() {
    if (!root.opened || displayModel.count === 0) {
      clearPreview()
      return
    }
    var item = displayModel.get(root.selectedIndex)
    if (!item || !item.path) {
      clearPreview()
      return
    }

    root.previewPath = item.path
    root.previewName = item.name
    root.previewTag = item.tag
    root.previewSize = item.sizeText
    root.previewIsDir = item.isDir

    if (item.tag === "IMAGE") {
      root.previewIsImage = true
      root.previewContent = ""
      root.previewLoading = false
      return
    }

    root.previewIsImage = false
    root.previewLoading = true

    if (previewProc.running) previewProc.running = false

    var cmd = ""
    var quoted = Util.shellQuote(item.path)
    if (item.isDir) {
      cmd = "ls -1 -p " + quoted + " 2>/dev/null | head -n 40"
    } else if (item.tag === "PDF") {
      cmd = "pdftotext -l 5 " + quoted + " - 2>/dev/null | head -n 100 || file -b " + quoted
    } else {
      cmd = "head -n 250 " + quoted + " 2>/dev/null || file -b " + quoted
    }

    previewProc.command = ["bash", "-c", cmd]
    previewProc.running = true
  }

  Process {
    id: previewProc
    stdout: StdioCollector {
      id: previewOutput
      waitForEnd: true
    }
    onExited: function(code) {
      root.previewLoading = false
      if (!root.opened) return
      root.previewContent = String(previewOutput.text || "").trim()
    }
  }

  ListModel {
    id: displayModel
  }

  // ---- Overlay Surface UI ----
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "recon-finder"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Scrim with smooth fade
    Rectangle {
      id: scrimRect
      anchors.fill: parent
      color: root.scrim
      opacity: root.isAnimatingOut ? 0 : 1
      Behavior on opacity {
        NumberAnimation {
          duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn
          easing.type: Easing.OutCubic
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      opacity: root.isAnimatingOut ? 0 : 1
      scale: root.isAnimatingOut ? 0.98 : 1.0
      Behavior on opacity {
        NumberAnimation {
          duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn
          easing.type: Easing.OutCubic
        }
      }
      Behavior on scale {
        NumberAnimation {
          duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn
          easing.type: Easing.OutCubic
        }
      }
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (root.settingsOpen) {
            if (event.key === Qt.Key_Escape) {
              root.settingsOpen = false
              event.accepted = true
            }
            return
          }

          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.dismiss()
            event.accepted = true
          } else if ((event.key === Qt.Key_Comma) && (event.modifiers & Qt.ControlModifier)) {
            root.settingsOpen = !root.settingsOpen
            event.accepted = true
          } else if (event.key === Qt.Key_Tab) {
            root.cycleTab(event.modifiers & Qt.ShiftModifier ? -1 : 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Backtab) {
            root.cycleTab(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up || ((event.key === Qt.Key_K) && (event.modifiers & Qt.ControlModifier))) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down || ((event.key === Qt.Key_J) && (event.modifiers & Qt.ControlModifier))) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-8)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(8)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectAbsolute(0)
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectAbsolute(displayModel.count - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (event.modifiers & Qt.ShiftModifier) root.copySelectedPath()
            else if (event.modifiers & Qt.AltModifier) root.revealSelectedFolder()
            else root.openSelected()
            event.accepted = true
          } else if (event.key === Qt.Key_Delete || ((event.key === Qt.Key_D) && (event.modifiers & Qt.ControlModifier))) {
            root.trashSelected()
            event.accepted = true
          } else if ((event.key === Qt.Key_C) && (event.modifiers & Qt.ControlModifier)) {
            root.copySelectedPath()
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

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        // Search Header (with ⚙ Settings button)
        ReconHeader {
          width: parent.width
          height: root.headerHeight
          filterText: root.filterText
          itemCount: displayModel.count
          isSearching: root.isSearching
          onSettingsClicked: root.settingsOpen = !root.settingsOpen
        }

        // Category Filter Tabs (with Dynamic Sub-Filters)
        ReconTabs {
          id: tabsRow
          width: parent.width
          activeTab: root.activeTab
          activeSubFilter: root.activeSubFilter
          onTabSelected: function(tab) { root.setActiveTab(tab) }
          onSubFilterSelected: function(ext) { root.setActiveSubFilter(ext) }
        }

        // Split Main View: Results List + Preview Pane
        Item {
          id: bodyArea
          width: parent.width
          height: Math.max(Style.space(120), parent.height - root.headerHeight - tabsRow.implicitHeight - root.footerHeight - root.contentSpacing * 3)

          Row {
            anchors.fill: parent
            spacing: Style.space(12)

            // Results List (52% width)
            Item {
              width: parent.width * 0.52
              height: parent.height
              clip: true

              ListView {
                id: resultList
                anchors.fill: parent
                model: displayModel
                clip: true
                spacing: Style.space(3)
                boundsBehavior: Flickable.StopAtBounds

                delegate: ResultRow {
                  required property int index
                  required property string path
                  required property string name
                  required property string dir
                  required property string sizeText
                  required property string tag
                  required property bool isDir

                  isSelected: root.cursorActive && index === root.selectedIndex
                  rowTag: tag
                  rowName: name
                  rowDir: dir
                  rowSize: sizeText
                  rowPath: path

                  onClicked: {
                    root.selectAbsolute(index)
                    root.openSelected()
                  }
                }
              }

              // Empty Results Placeholder
              Column {
                anchors.centerIn: parent
                spacing: Style.space(8)
                visible: displayModel.count === 0 && !root.isSearching

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: "🔍"
                  font.pixelSize: Style.space(32)
                  opacity: 0.5
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: root.filterText ? "No matches found" : "No files found in target"
                  color: Color.menu.text
                  opacity: 0.55
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
              }
            }

            // Split Preview Pane (48% width)
            PreviewPane {
              width: parent.width * 0.48 - Style.space(12)
              height: parent.height
              fullPath: root.previewPath
              fileName: root.previewName
              tag: root.previewTag
              sizeText: root.previewSize
              content: root.previewContent
              isImage: root.previewIsImage
              isDir: root.previewIsDir
              isLoading: root.previewLoading
              onCopyRequested: {
                var textToCopy = root.previewContent.length > 0 ? root.previewContent : root.previewPath
                if (textToCopy) Util.execDetached("wl-copy " + Util.shellQuote(textToCopy))
              }
            }
          }
        }

        // Bottom Ergonomic Action Footer
        Rectangle {
          width: parent.width
          height: root.footerHeight
          color: "transparent"

          Row {
            anchors.centerIn: parent
            spacing: Style.space(14)

            Repeater {
              model: [
                { key: "↵ Enter", desc: "Open" },
                { key: "⇧ Shift+Enter", desc: "Copy Path" },
                { key: "⎇ Alt+Enter", desc: "Folder" },
                { key: "Tab", desc: "Category" },
                { key: "^,", desc: "Settings" },
                { key: "Del / ^D", desc: "Trash" },
                { key: "Esc", desc: "Close" }
              ]

              delegate: Row {
                id: footerItem
                required property var modelData
                spacing: Style.space(5)

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: badgeText.implicitWidth + Style.space(10)
                  height: Style.space(18)
                  radius: Style.space(3)
                  color: Util.alpha(Color.menu.selectedBackground, 0.2)
                  border.width: 1
                  border.color: Util.alpha(Color.menu.border, 0.4)

                  Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: footerItem.modelData.key
                    color: Color.menu.selectedText
                    font.family: Style.font.family
                    font.pixelSize: Style.space(10)
                    font.weight: Font.Bold
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: footerItem.modelData.desc
                  color: Color.menu.text
                  opacity: 0.65
                  font.family: root.fontFamily
                  font.pixelSize: Style.space(11)
                }
              }
            }
          }
        }
      }

      // Settings Modal Dialog Overlay
      SettingsDialog {
        visible: root.settingsOpen
        targetDir: root.targetDir
        excludeDirs: root.excludeDirs
        excludeExts: root.excludeExts
        excludeHidden: root.excludeHidden
        onClosed: root.settingsOpen = false
        onSaved: function(newTarget, newDirs, newExts, newHidden) {
          root.targetDir = newTarget
          root.excludeDirs = newDirs
          root.excludeExts = newExts
          root.excludeHidden = newHidden
          root.saveConfig()
          root.settingsOpen = false
          root.executeSearch()
        }
      }
    }
  }
}
