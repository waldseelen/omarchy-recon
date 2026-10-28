import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: footerRoot

  property string fontFamily: Style.font.family
  property int footerHeight: Style.space(26)

  width: parent ? parent.width : Style.space(600)
  height: footerHeight
  color: "transparent"

  Row {
    anchors.centerIn: parent
    spacing: Style.space(10)

    Repeater {
      model: [
        { key: "↵", desc: "Open" },
        { key: "⎇A", desc: "Actions" },
        { key: "F2", desc: "Rename" },
        { key: "^N", desc: "New" },
        { key: "^Space", desc: "Mark" },
        { key: "⎇I", desc: "Ignored" },
        { key: "⎇P", desc: "Layout" },
        { key: "F1", desc: "Help" },
        { key: "Esc", desc: "Close" }
      ]

      delegate: Row {
        id: fRow
        required property var modelData
        spacing: Style.space(4)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: bTxt.implicitWidth + Style.space(8)
          height: Style.space(18)
          radius: Style.space(3)
          color: Util.alpha(Color.menu.selectedBackground, 0.2)
          border.width: 1
          border.color: Util.alpha(Color.menu.border, 0.4)

          Text {
            id: bTxt
            anchors.centerIn: parent
            text: fRow.modelData.key
            color: Color.menu.selectedText
            font.family: Style.font.family
            font.pixelSize: Style.space(10)
            font.weight: Font.Bold
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: fRow.modelData.desc
          color: Color.menu.text
          opacity: 0.65
          font.family: footerRoot.fontFamily
          font.pixelSize: Style.space(10)
        }
      }
    }
  }
}
