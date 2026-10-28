import Quickshell
import Quickshell.Io
import QtQuick
import "script/Safe.js" as Safe

Item {
  id: previewCtrl

  property var root: null
  property var displayModel: null

  property string previewContent: ""
  property string previewPath: ""
  property string previewName: ""
  property string previewTag: ""
  property string previewSize: ""
  property bool previewIsImage: false
  property bool previewIsDir: false
  property bool previewLoading: false

  function clearPreview() {
    previewContent = ""
    previewPath = ""
    previewName = ""
    previewTag = ""
    previewSize = ""
    previewIsImage = false
    previewIsDir = false
    previewLoading = false
  }

  Timer {
    id: previewDebounce
    interval: 80
    repeat: false
    onTriggered: previewCtrl.executePreview()
  }

  function triggerPreview() {
    previewDebounce.restart()
  }

  function cancelPreview() {
    previewDebounce.stop()
    if (previewProc.running) previewProc.running = false
  }

  function executePreview() {
    if (!root || !root.opened || !displayModel || displayModel.count === 0) {
      clearPreview()
      return
    }
    var item = displayModel.get(root.selectedIndex)
    if (!item) {
      clearPreview()
      return
    }

    previewPath = item.path
    previewName = item.name
    previewTag = item.tag
    previewSize = item.sizeText
    previewIsDir = item.isDir

    if (item.tag === "IMAGE") {
      previewIsImage = true
      previewContent = ""
      previewLoading = false
      return
    }

    previewIsImage = false
    previewLoading = true
    if (previewProc.running) previewProc.running = false

    var pv = Safe.buildPreview(item)
    previewProc.command = pv.argv
    previewProc.running = true
  }

  Process {
    id: previewProc
    stdout: StdioCollector {
      id: previewOutput
      waitForEnd: true
    }
    onExited: function(code) {
      previewLoading = false
      if (root && root.opened) {
        previewContent = String(previewOutput.text || "").trim()
      }
    }
  }
}
