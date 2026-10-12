import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: rowRoot

  property bool isSelected: false
  property string tag: "FILE"
  property string name: ""
  property string dir: ""
  property string sizeText: ""
  property string fullPath: ""
  property string fontFamily: Style.font.menuFamily
  property int contentSize: Style.font.body ? Style.font.body : 13
  property int captionSize: Style.font.caption ? Style.font.caption : 11

  signal clicked()

  width: ListView.view ? ListView.view.width : Style.space(400)
  height: Style.space(46)
  radius: Style.cornerRadius
  color: isSelected
    ? Color.menu.selectedBackground
    : (rowMouse.containsMouse ? Util.alpha(Color.menu.selectedBackground, 0.25) : "transparent")

  Row {
    anchors.fill: parent
    anchors.leftMargin: Style.space(10)
    anchors.rightMargin: Style.space(12)
    spacing: Style.space(10)

    // Tag badge
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(44)
      height: Style.space(22)
      radius: Style.space(4)
      color: rowRoot.isSelected
        ? Util.alpha(Color.menu.selectedText, 0.25)
        : (rowRoot.tag === "DIR" ? Util.alpha(Color.accent, 0.2) : Util.alpha(Color.menu.border, 0.3))

      Text {
        anchors.centerIn: parent
        text: rowRoot.tag
        color: rowRoot.isSelected ? Color.menu.selectedText : (rowRoot.tag === "DIR" ? Color.accent : Color.menu.text)
        font.family: Style.font.family
        font.pixelSize: rowRoot.captionSize
        font.weight: Font.Bold
      }
    }

    // Name & Dir 2-line column
    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - Style.space(44 + 65 + 24)
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: rowRoot.name
        textFormat: Text.PlainText
        color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
        font.family: rowRoot.fontFamily
        font.pixelSize: rowRoot.contentSize
        font.weight: rowRoot.isSelected ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: rowRoot.dir
        textFormat: Text.PlainText
        color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
        opacity: rowRoot.isSelected ? 0.8 : 0.5
        font.family: rowRoot.fontFamily
        font.pixelSize: rowRoot.captionSize
        elide: Text.ElideMiddle
      }
    }

    // Size / Stat
    Text {
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(65)
      text: rowRoot.sizeText
      textFormat: Text.PlainText
      color: rowRoot.isSelected ? Color.menu.selectedText : Color.menu.text
      opacity: rowRoot.isSelected ? 0.9 : 0.6
      font.family: Style.font.family
      font.pixelSize: rowRoot.captionSize
      horizontalAlignment: Text.AlignRight
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
