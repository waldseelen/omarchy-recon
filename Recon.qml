import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "script/Core.js" as Core
import "script/Safe.js" as Safe

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property string home: Quickshell.env("HOME")
  property string targetDir: Quickshell.env("HOME")
  property string filterText: ""
  property string activeTab: "all"
  property string activeSubFilter: "all"
  property int selectedIndex: 0
  property bool cursorActive: true
  property bool isSearching: false
  property bool isAnimatingOut: false
  property int animationDurationIn: 130
  property int animationDurationOut: 80

  // Modes & Toggles
  property bool isContentSearch: false
  property bool includeIgnored: false
  property string previewLayout: "side" // "side" | "bottom"
  property var pinnedDirs: [root.home + "/Documents", root.home + "/Downloads", root.home + "/Work"]
  property var markedPaths: ({})

  // Overlays State
  property bool settingsOpen: false
  property bool actionsOpen: false
  property bool inlineModalOpen: false
  property bool helpOpen: false
  property string inlineModalMode: "rename"
  property string inlineModalPath: ""
  property string inlineModalInitial: ""

  // Config State
  property var excludeDirs: ["node_modules", ".git", "__pycache__", ".venv", ".cache"]
  property var excludeExts: ["tmp", "bak", "log", "iso", "bin"]
  property bool excludeHidden: true

  // UI Theme Tokens
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.family
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int footerHeight: Style.space(26)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(1040), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(660), panel.height - Style.gapsOut * 2)

  // State Persistence & 0600 Security
  StateStore { id: store; root: root }

  function saveConfig() { store.saveConfig() }
  function recordFrecency(p) { store.recordFrecency(p) }
  function removeFrecency(p) { store.removeFrecency(p) }
  function renameFrecency(o, n) { store.renameFrecency(o, n) }

  // Multi-Select Helpers
  function toggleMark(idx) {
    if (idx < 0 || idx >= displayModel.count) return
    var item = displayModel.get(idx)
    if (!item || !item.path) return
    var marks = Object.assign({}, root.markedPaths)
    if (marks[item.path]) delete marks[item.path]
    else marks[item.path] = true
    root.markedPaths = marks
  }

  function getMarkedPathsList() {
    var list = []
    for (var p in root.markedPaths) { if (root.markedPaths[p]) list.push(p) }
    return list
  }

  // Lifecycle
  function open(payloadJson) {
    var payload = {}
    try { payload = JSON.parse(payloadJson || "{}") } catch(e) { payload = {} }
    if (payload && Safe.isSafeAbsPath(payload.dir)) root.targetDir = payload.dir
    root.opened = true; root.isAnimatingOut = false; root.settingsOpen = false;
    root.actionsOpen = false; root.inlineModalOpen = false; root.helpOpen = false;
    root.isContentSearch = false; root.filterText = ""; root.selectedIndex = 0;
    root.cursorActive = true; root.activeTab = "all"; root.activeSubFilter = "all";
    root.markedPaths = ({}); displayModel.clear(); previewCtrl.clearPreview();
    searchCtrl.executeSearch()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function dismiss() {
    if (root.helpOpen) { root.helpOpen = false; return; }
    if (root.inlineModalOpen) { root.inlineModalOpen = false; return; }
    if (root.actionsOpen) { root.actionsOpen = false; return; }
    if (root.settingsOpen) { root.settingsOpen = false; return; }
    if (root.isAnimatingOut) return
    root.isAnimatingOut = true
    searchCtrl.cancelSearch()
    previewCtrl.cancelPreview()
    dismissTimer.restart()
  }

  Timer {
    id: dismissTimer
    interval: root.animationDurationOut
    repeat: false
    onTriggered: {
      root.opened = false; root.isAnimatingOut = false;
      if (root.shell && typeof root.shell.hide === "function") {
        root.shell.hide(root.manifest ? root.manifest.id : "waldseelen.recon")
      }
    }
  }

  // Navigation & Drill-Down
  function setFilter(txt) { root.filterText = txt; searchCtrl.triggerSearch(); }
  function selectDelta(d) {
    if (displayModel.count === 0) return
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(displayModel.count - 1, root.selectedIndex + d))
    bodySplitView.activeResultView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    previewCtrl.triggerPreview()
  }
  function selectAbsolute(i) {
    if (displayModel.count === 0) return
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(displayModel.count - 1, i))
    bodySplitView.activeResultView.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    previewCtrl.triggerPreview()
  }
  function drillDownSelected() {
    if (displayModel.count > 0) {
      var it = displayModel.get(root.selectedIndex)
      if (it && it.isDir && Safe.isSafeAbsPath(it.path)) {
        root.targetDir = it.path; root.filterText = ""; root.markedPaths = ({}); searchCtrl.executeSearch();
      }
    }
  }
  function drillUp() {
    var p = Core.getDirName(root.targetDir)
    if (Safe.isSafeAbsPath(p) && p !== root.targetDir) {
      root.targetDir = p; root.filterText = ""; root.markedPaths = ({}); searchCtrl.executeSearch();
    }
  }
  function jumpBookmark(idx) {
    if (Array.isArray(root.pinnedDirs) && idx < root.pinnedDirs.length) {
      var bd = root.pinnedDirs[idx]
      if (Safe.isSafeAbsPath(bd)) {
        root.targetDir = bd; root.filterText = ""; root.markedPaths = ({}); searchCtrl.executeSearch();
      }
    }
  }
  function cycleTab(delta) {
    var tabs = ["all", "folders", "docs", "code", "office", "images"]
    root.activeTab = tabs[(tabs.indexOf(root.activeTab) + delta + tabs.length) % tabs.length]
    root.activeSubFilter = "all"
    searchCtrl.triggerSearch()
  }
  function setTabByIndex(idx) {
    var tabs = ["all", "folders", "docs", "code", "office", "images"]
    if (idx >= 0 && idx < tabs.length) {
      root.activeTab = tabs[idx]; root.activeSubFilter = "all"; searchCtrl.triggerSearch();
    }
  }
  function cycleSubFilter(delta) {
    var list = tabsRow ? tabsRow.currentSubFilters : []
    if (!list || list.length === 0) return
    var cur = 0
    for (var i = 0; i < list.length; i++) { if (list[i].id === root.activeSubFilter) { cur = i; break; } }
    root.activeSubFilter = list[(cur + delta + list.length) % list.length].id
    searchCtrl.triggerSearch()
  }
  function startRename() {
    var c = displayModel.get(root.selectedIndex)
    if (c) {
      root.inlineModalMode = "rename"; root.inlineModalPath = c.path;
      root.inlineModalInitial = Core.getBaseName(c.path); root.inlineModalOpen = true;
      Qt.callLater(function() { overlays.initInlineFocus() })
    }
  }
  function startNewFile() {
    root.inlineModalMode = "newfile"; root.inlineModalPath = root.targetDir;
    root.inlineModalInitial = ""; root.inlineModalOpen = true;
    Qt.callLater(function() { overlays.initInlineFocus() })
  }
  function openHelp() {
    root.helpOpen = true; Qt.callLater(function() { overlays.initHelpFocus() })
  }

  ListModel { id: displayModel }

  PreviewController {
    id: previewCtrl
    root: root
    displayModel: displayModel
  }

  SearchController {
    id: searchCtrl
    displayModel: displayModel
    filterText: root.filterText
    isContentSearch: root.isContentSearch
    targetDir: root.targetDir
    activeTab: root.activeTab
    activeSubFilter: root.activeSubFilter
    excludeDirs: root.excludeDirs
    excludeExts: root.excludeExts
    excludeHidden: root.excludeHidden
    includeIgnored: root.includeIgnored
    frecencyData: store.frecencyData
    home: root.home
    onSearchCompleted: function(cnt) {
      root.isSearching = false
      if (cnt === 0) { root.selectedIndex = 0; previewCtrl.clearPreview(); }
      else {
        if (root.selectedIndex >= cnt) root.selectedIndex = cnt - 1
        if (root.selectedIndex < 0) root.selectedIndex = 0
        previewCtrl.executePreview()
      }
    }
  }

  ActionController {
    id: actionCtrl
    targetDir: root.targetDir
    root: root
    onSearchRequested: searchCtrl.executeSearch()
    onDismissRequested: root.dismiss()
    onRecordFrecencyRequested: function(p) { root.recordFrecency(p) }
    onRemoveFrecencyRequested: function(p) { root.removeFrecency(p) }
    onRenameFrecencyRequested: function(o, n) { root.renameFrecency(o, n) }
    onInlineModalRequested: function(m, t, i) {
      root.inlineModalMode = m; root.inlineModalPath = t; root.inlineModalInitial = i;
      root.inlineModalOpen = true; Qt.callLater(function() { overlays.initInlineFocus() })
    }
  }

  KeyController {
    id: keyCtrl
    root: root
    actionCtrl: actionCtrl
    searchCtrl: searchCtrl
    displayModel: displayModel
  }

  // UI Surface
  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "recon-finder"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: root.isAnimatingOut ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn } }
    }

    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      opacity: root.isAnimatingOut ? 0 : 1
      scale: root.isAnimatingOut ? 0.98 : 1.0
      Behavior on opacity { NumberAnimation { duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn } }
      Behavior on scale { NumberAnimation { duration: root.isAnimatingOut ? root.animationDurationOut : root.animationDurationIn } }
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(e) { keyCtrl.handleKey(e) }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        ReconHeader {
          width: parent.width
          height: root.headerHeight
          filterText: root.filterText
          itemCount: displayModel.count
          isSearching: searchCtrl.isSearching
          isContentSearch: root.isContentSearch || root.filterText.trim().startsWith("?")
          includeIgnored: root.includeIgnored
          onSettingsClicked: { root.settingsOpen = !root.settingsOpen; if (root.settingsOpen) Qt.callLater(function() { overlays.initSettingsFocus() }) }
          onContentSearchToggled: { root.isContentSearch = !root.isContentSearch; searchCtrl.executeSearch(); }
          onIncludeIgnoredToggled: { root.includeIgnored = !root.includeIgnored; root.saveConfig(); searchCtrl.executeSearch(); }
        }

        ReconTabs {
          id: tabsRow
          width: parent.width
          activeTab: root.activeTab
          activeSubFilter: root.activeSubFilter
          onTabSelected: function(t) { root.activeTab = t; root.activeSubFilter = "all"; searchCtrl.triggerSearch(); }
          onSubFilterSelected: function(e) { root.activeSubFilter = e; searchCtrl.triggerSearch(); }
        }

        MainSplitView {
          id: bodySplitView
          width: parent.width
          height: Math.max(Style.space(120), parent.height - root.headerHeight - tabsRow.implicitHeight - root.footerHeight - root.contentSpacing * 3)
          root: root
          displayModel: displayModel
          actionCtrl: actionCtrl
          searchCtrl: searchCtrl
          previewCtrl: previewCtrl
          previewLayout: root.previewLayout
        }

        ReconFooter {
          width: parent.width
          height: root.footerHeight
          fontFamily: root.fontFamily
        }
      }

      OverlayContainer {
        id: overlays
        root: root
        actionCtrl: actionCtrl
        searchCtrl: searchCtrl
        displayModel: displayModel
        keyCatcher: keyCatcher
      }
    }
  }
}
