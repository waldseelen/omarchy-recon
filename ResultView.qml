import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: viewRoot

  property var root: null
  property var displayModel: null
  property var actionCtrl: null
  property bool isSearching: false
  property string filterText: ""
  property string fontFamily: Style.font.family

  function positionViewAtIndex(idx, mode) {
    resultList.positionViewAtIndex(idx, mode)
  }

  clip: true

  ListView {
    id: resultList
    anchors.fill: parent
    model: viewRoot.displayModel
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

      isSelected: viewRoot.root ? (viewRoot.root.cursorActive && index === viewRoot.root.selectedIndex) : false
      isMarked: viewRoot.root ? !!viewRoot.root.markedPaths[path] : false
      rowTag: tag
      rowName: name
      rowDir: dir
      rowSize: sizeText
      rowPath: path

      onClicked: {
        if (viewRoot.root) viewRoot.root.selectAbsolute(index)
        if (viewRoot.actionCtrl && viewRoot.displayModel) {
          viewRoot.actionCtrl.openItem(viewRoot.displayModel.get(index))
        }
      }
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: Style.space(8)
    visible: viewRoot.displayModel && viewRoot.displayModel.count === 0 && !viewRoot.isSearching

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: "🔍"
      font.pixelSize: Style.space(32)
      opacity: 0.5
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: viewRoot.filterText ? "No matches found" : "No files found in target"
      color: Color.menu.text
      opacity: 0.55
      font.family: viewRoot.fontFamily
      font.pixelSize: Style.font.body
    }
  }
}
