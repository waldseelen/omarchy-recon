import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: headerRoot

  property string filterText: ""
  property int itemCount: 0
  property bool isSearching: false
  property string fontFamily: Style.font.menuFamily
  property int headingSize: Style.font.heading ? Style.font.heading : 16
  property int captionSize: Style.font.caption ? Style.font.caption : 11

  signal cleared()

  height: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(Color.menu.selectedBackground, 0.12)
    border.width: 1
    border.color: Util.alpha(Color.menu.border, 0.4)

    Row {
      anchors.fill: parent
      anchors.leftMargin: Style.space(12)
      anchors.rightMargin: Style.space(12)
      spacing: Style.space(10)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "🔍"
        font.pixelSize: Style.space(16)
        opacity: 0.8
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Style.space(180)
        text: headerRoot.filterText ? headerRoot.filterText : "Search files & folders in SSS (e.g. ALL.md, pdf, code)..."
        textFormat: Text.PlainText
        color: Color.menu.text
        opacity: headerRoot.filterText ? 1.0 : 0.45
        font.family: headerRoot.fontFamily
        font.pixelSize: headerRoot.headingSize
        elide: Text.ElideRight
      }

      Item { width: 1; height: 1 } // Spacer

      // Status Badge
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: countText.implicitWidth + Style.space(14)
        height: Style.space(24)
        radius: Style.space(4)
        color: Util.alpha(Color.menu.border, 0.3)

        Text {
          id: countText
          anchors.centerIn: parent
          text: headerRoot.isSearching ? "Searching..." : (headerRoot.itemCount + " items")
          color: Color.menu.text
          opacity: 0.75
          font.family: Style.font.family
          font.pixelSize: headerRoot.captionSize
        }
      }
    }
  }
}
