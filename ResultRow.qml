import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: rowRoot

  property bool isSelected: false
  property string rowTag: "FILE"
  property string rowName: ""
  property string rowDir: ""
  property string rowSize: ""
  property string rowPath: ""
  property string fontFamily: Style.font.family
  property int contentSize: Style.font.body ? Style.font.body : 13
  property int captionSize: Style.font.caption ? Style.font.caption : 11

  signal clicked()

  width: ListView.view ? ListView.view.width : Style.space(400)
  height: Style.space(46)
  radius: Style.cornerRadius
  color: isSelected
    ? Color.menu.selectedBackground
    : (rowMouse.containsMouse ? Util.alpha(Color.menu.selectedBackground, 0.25) : "transparent")

  // 1. Tag Badge on the Left
  Rectangle {
    id: tagBadge
    anchors.left: parent.left
    anchors.leftMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(44)
    height: Style.space(22)
    radius: Style.space(4)
    color: rowRoot.isSelected
      ? Util.alpha(Color.menu.selectedText, 0.25)
      : (rowRoot.rowTag === "DIR" ? Util.alpha(Color.accent, 0.2) : Util.alpha(Color.menu.border, 0.3))

    Text {
      anchors.centerIn: parent
      text: rowRoot.rowTag
      color: rowRoot.isSelected ? Color.menu.selectedText : (rowRoot.rowTag === "DIR" ? Color.accent : Color.menu.text)
      font.family: rowRoot.fontFamily
      font.pixelSize: rowRoot.captionSize
      font.weight: Font.Bold
    }
  }

  // 2. Size / Stat on the Right
  Text {
    id: sizeLabel
    anchors.right: parent.right
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(Style.space(65), implicitWidth)
    text: rowRoot.rowSize
    textFormat: Text.PlainText
    color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
    opacity: rowRoot.isSelected ? 0.9 : 0.6
    font.family: rowRoot.fontFamily
    font.pixelSize: rowRoot.captionSize
    horizontalAlignment: Text.AlignRight
  }

  // 3. Name & Dir Column in the Middle (flexible width anchored between badge and size)
  Column {
    anchors.left: tagBadge.right
    anchors.leftMargin: Style.space(10)
    anchors.right: sizeLabel.left
    anchors.rightMargin: Style.space(10)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Text {
      width: parent.width
      text: rowRoot.rowName
      textFormat: Text.PlainText
      color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
      font.family: rowRoot.fontFamily
      font.pixelSize: rowRoot.contentSize
      font.weight: rowRoot.isSelected ? Font.DemiBold : Font.Normal
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: rowRoot.rowDir
      textFormat: Text.PlainText
      color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
      opacity: rowRoot.isSelected ? 0.8 : 0.5
      font.family: rowRoot.fontFamily
      font.pixelSize: rowRoot.captionSize
      elide: Text.ElideMiddle
    }
  }

  MouseArea {
    id: rowMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: rowRoot.clicked()
  }
}
