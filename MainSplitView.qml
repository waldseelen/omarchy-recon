import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: splitArea

  property var root: null
  property var displayModel: null
  property var actionCtrl: null
  property var searchCtrl: null
  property var previewCtrl: null
  property string previewLayout: "side"

  readonly property var activeResultView: splitArea.previewLayout === "side" ? sideResultView : bottomResultView

  // Side-by-side Layout Mode
  Row {
    visible: splitArea.previewLayout === "side"
    anchors.fill: parent
    spacing: Style.space(12)

    ResultView {
      id: sideResultView
      width: parent.width * 0.52
      height: parent.height
      root: splitArea.root
      displayModel: splitArea.displayModel
      actionCtrl: splitArea.actionCtrl
      isSearching: splitArea.searchCtrl ? splitArea.searchCtrl.isSearching : false
      filterText: splitArea.root ? splitArea.root.filterText : ""
    }

    PreviewPane {
      width: parent.width * 0.48 - Style.space(12)
      height: parent.height
      layout: "side"
      fullPath: splitArea.previewCtrl ? splitArea.previewCtrl.previewPath : ""
      fileName: splitArea.previewCtrl ? splitArea.previewCtrl.previewName : ""
      tag: splitArea.previewCtrl ? splitArea.previewCtrl.previewTag : ""
      sizeText: splitArea.previewCtrl ? splitArea.previewCtrl.previewSize : ""
      content: splitArea.previewCtrl ? splitArea.previewCtrl.previewContent : ""
      isImage: splitArea.previewCtrl ? splitArea.previewCtrl.previewIsImage : false
      isDir: splitArea.previewCtrl ? splitArea.previewCtrl.previewIsDir : false
      isLoading: splitArea.previewCtrl ? splitArea.previewCtrl.previewLoading : false
      onCopyRequested: {
        if (splitArea.previewCtrl && splitArea.previewCtrl.previewPath && splitArea.actionCtrl) {
          splitArea.actionCtrl.copyFileContent(splitArea.previewCtrl.previewPath)
        }
      }
    }
  }

  // Bottom-preview Layout Mode
  Column {
    visible: splitArea.previewLayout === "bottom"
    anchors.fill: parent
    spacing: Style.space(8)

    ResultView {
      id: bottomResultView
      width: parent.width
      height: parent.height * 0.55
      root: splitArea.root
      displayModel: splitArea.displayModel
      actionCtrl: splitArea.actionCtrl
      isSearching: splitArea.searchCtrl ? splitArea.searchCtrl.isSearching : false
      filterText: splitArea.root ? splitArea.root.filterText : ""
    }

    PreviewPane {
      width: parent.width
      height: parent.height * 0.45 - Style.space(8)
      layout: "bottom"
      fullPath: splitArea.previewCtrl ? splitArea.previewCtrl.previewPath : ""
      fileName: splitArea.previewCtrl ? splitArea.previewCtrl.previewName : ""
      tag: splitArea.previewCtrl ? splitArea.previewCtrl.previewTag : ""
      sizeText: splitArea.previewCtrl ? splitArea.previewCtrl.previewSize : ""
      content: splitArea.previewCtrl ? splitArea.previewCtrl.previewContent : ""
      isImage: splitArea.previewCtrl ? splitArea.previewCtrl.previewIsImage : false
      isDir: splitArea.previewCtrl ? splitArea.previewCtrl.previewIsDir : false
      isLoading: splitArea.previewCtrl ? splitArea.previewCtrl.previewLoading : false
      onCopyRequested: {
        if (splitArea.previewCtrl && splitArea.previewCtrl.previewPath && splitArea.actionCtrl) {
          splitArea.actionCtrl.copyFileContent(splitArea.previewCtrl.previewPath)
        }
      }
    }
  }
}
