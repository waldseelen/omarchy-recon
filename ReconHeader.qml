import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: headerRoot

  property string filterText: ""
  property int itemCount: 0
  property bool isSearching: false
  property bool isContentSearch: false
  property bool includeIgnored: false
  property string fontFamily: Style.font.family
  property int headingSize: Style.font.heading ? Style.font.heading : 16
  property int captionSize: Style.font.caption ? Style.font.caption : 11

  signal cleared()
  signal settingsClicked()
  signal contentSearchToggled()
  signal includeIgnoredToggled()

  height: Math.max(Style.space(42), Style.font.title + Style.spacing.controlPaddingY * 2)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: Util.alpha(Color.menu.selectedBackground, 0.12)
    border.width: 1
    border.color: headerRoot.isContentSearch ? Color.accent : Util.alpha(Color.menu.border, 0.4)

    // 1. Search Icon on the Left
    Text {
      id: searchIcon
      anchors.left: parent.left
      anchors.leftMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      text: headerRoot.isContentSearch ? "📄" : "🔍"
      font.pixelSize: Style.space(15)
      opacity: 0.85
    }

    // 2. Right Controls (Status Badge + Ignored Toggle + Mode Toggle + Settings Button)
    Row {
      id: rightControls
      anchors.right: parent.right
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(8)

      // Ignored / Gitignore Toggle Badge
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: ignoredText.implicitWidth + Style.space(14)
        height: Style.space(24)
        radius: Style.space(4)
        color: headerRoot.includeIgnored ? Color.accent : Util.alpha(Color.menu.border, 0.25)
        border.width: 1
        border.color: headerRoot.includeIgnored ? Color.menu.selectedBorder : Util.alpha(Color.menu.border, 0.4)

        Text {
          id: ignoredText
          anchors.centerIn: parent
          text: headerRoot.includeIgnored ? "🚫 IGNORED (Alt+I)" : "Gitignore (Alt+I)"
          color: headerRoot.includeIgnored ? Color.menu.selectedText : Color.menu.text
          opacity: headerRoot.includeIgnored ? 1.0 : 0.65
          font.family: Style.font.family
          font.pixelSize: headerRoot.captionSize
          font.weight: headerRoot.includeIgnored ? Font.Bold : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: headerRoot.includeIgnoredToggled()
        }
      }

      // Content Search Mode Toggle Badge
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: inContentText.implicitWidth + Style.space(14)
        height: Style.space(24)
        radius: Style.space(4)
        color: headerRoot.isContentSearch ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.25)
        border.width: 1
        border.color: headerRoot.isContentSearch ? Color.menu.selectedBorder : Util.alpha(Color.menu.border, 0.4)

        Text {
          id: inContentText
          anchors.centerIn: parent
          text: headerRoot.isContentSearch ? "📄 In-File Mode" : "📄 In-File (^F)"
          color: headerRoot.isContentSearch ? Color.menu.selectedText : Color.menu.text
          opacity: headerRoot.isContentSearch ? 1.0 : 0.7
          font.family: Style.font.family
          font.pixelSize: headerRoot.captionSize
          font.weight: headerRoot.isContentSearch ? Font.Bold : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: headerRoot.contentSearchToggled()
        }
      }

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
      text: headerRoot.filterText
        ? headerRoot.filterText
        : (headerRoot.isContentSearch
            ? "Search inside file contents (e.g. def, import, key)..."
            : "Search files & folders (e.g. ALL.md, code, or prefix ? for text)...")
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
