import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: headerRoot

  property string filterText: ""
  property int itemCount: 0
  property bool isSearching: false
  property string fontFamily: Style.font.family
  property int headingSize: Style.font.heading ? Style.font.heading : 16
  property int captionSize: Style.font.caption ? Style.font.caption : 11

  signal cleared()
  signal settingsClicked()

  height: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(Color.menu.selectedBackground, 0.12)
    border.width: 1
    border.color: Util.alpha(Color.menu.border, 0.4)

    // 1. Search Icon on the Left
    Text {
      id: searchIcon
      anchors.left: parent.left
      anchors.leftMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      text: "🔍"
      font.pixelSize: Style.space(15)
      opacity: 0.8
    }

    // 2. Right Controls (Status Badge + Settings Button)
    Row {
      id: rightControls
      anchors.right: parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(8)

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

      // Settings Button ⚙
      Rectangle {
        id: settingsBtn
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(26)
        height: Style.space(24)
        radius: Style.space(4)
        color: settingsMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.25)
        border.width: 1
        border.color: settingsMouse.containsMouse ? Color.menu.selectedBorder : Util.alpha(Color.menu.border, 0.4)

        Text {
          anchors.centerIn: parent
          text: "⚙"
          font.pixelSize: Style.space(13)
          color: settingsMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
          opacity: settingsMouse.containsMouse ? 1 : 0.8
        }

        MouseArea {
          id: settingsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: headerRoot.settingsClicked()
        }
      }
    }

    // 3. Search Text in Middle (Elastic Width - Zero Overflow)
    Text {
      id: searchLabel
      anchors.left: searchIcon.right
      anchors.leftMargin: Style.space(10)
      anchors.right: rightControls.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      text: headerRoot.filterText ? headerRoot.filterText : "Search files & folders (e.g. ALL.md, pdf, code)..."
      textFormat: Text.PlainText
      color: Color.menu.text
      opacity: headerRoot.filterText ? 1.0 : 0.45
      font.family: headerRoot.fontFamily
      font.pixelSize: headerRoot.headingSize
      elide: Text.ElideRight
      clip: true
    }
  }
}
