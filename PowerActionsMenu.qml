import Quickshell
import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: actionsOverlay

  anchors.fill: parent
  color: Util.alpha(Color.menu.scrim, 0.75)
  z: 60
  focus: true
  Keys.priority: Keys.BeforeItem

  property string targetPath: ""
  property string targetName: ""
  property bool targetIsDir: false
  property string targetDir: ""
  property int selectedIndex: 0

  signal executed(string actionId, string path)
  signal closed()

  readonly property var actionsList: [
    { id: "open", icon: "🚀", title: "Open in Default App", desc: "Launch with xdg-open" },
    { id: "term", icon: "💻", title: "Open in Terminal", desc: "Open containing folder in terminal" },
    { id: "editor", icon: "✏️", title: "Open in Editor", desc: "Open file in text editor" },
    { id: "copyPath", icon: "📍", title: "Copy Full Path", desc: "Copy absolute path to clipboard" },
    { id: "copyRelPath", icon: "📋", title: "Copy Relative Path", desc: "Copy path relative to target drive" },
    { id: "copyContent", icon: "📄", title: "Copy File Content", desc: "Copy entire preview text to clipboard" },
    { id: "trash", icon: "🗑️", title: "Move to Trash", desc: "Send safely to system trash" }
  ]

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      actionsOverlay.closed()
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Up || ((event.key === Qt.Key_K) && (event.modifiers & Qt.ControlModifier))) {
      actionsOverlay.selectedIndex = Math.max(0, actionsOverlay.selectedIndex - 1)
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Down || ((event.key === Qt.Key_J) && (event.modifiers & Qt.ControlModifier))) {
      actionsOverlay.selectedIndex = Math.min(actionsList.length - 1, actionsOverlay.selectedIndex + 1)
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      var act = actionsList[actionsOverlay.selectedIndex]
      if (act) actionsOverlay.executed(act.id, actionsOverlay.targetPath)
      event.accepted = true
      return
    }
  }

  // Click outside to cancel
  MouseArea {
    anchors.fill: parent
    onClicked: actionsOverlay.closed()
  }

  BorderSurface {
    id: actionCard
    width: Math.min(Style.space(480), parent.width - Style.space(40))
    height: Math.min(Style.space(380), parent.height - Style.space(40))
    radius: Style.cornerRadius
    anchors.centerIn: parent
    color: Color.menu.background
    borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
    padding: Style.spacing.panelPadding

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Item {
      anchors.fill: parent
      anchors.topMargin: actionCard.contentTopInset
      anchors.bottomMargin: actionCard.contentBottomInset
      anchors.leftMargin: actionCard.contentLeftInset
      anchors.rightMargin: actionCard.contentRightInset

      // Header
      Rectangle {
        id: actHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(38)
        color: "transparent"

        Column {
          anchors.left: parent.left
          anchors.right: closeBtn.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            text: "⚡ Power Actions"
            color: Color.menu.text
            font.family: Style.font.family
            font.pixelSize: Style.font.heading ? Style.font.heading : 14
            font.weight: Font.Bold
          }

          Text {
            text: actionsOverlay.targetName || actionsOverlay.targetPath
            color: Color.menu.text
            opacity: 0.6
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
            width: parent.width
          }
        }

        Rectangle {
          id: closeBtn
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(26)
          height: Style.space(26)
          radius: Style.cornerRadius
          color: closeMouse.containsMouse ? Color.menu.selectedBackground : "transparent"

          Text {
            anchors.centerIn: parent
            text: "✕"
            color: closeMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
            font.pixelSize: Style.space(12)
          }

          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionsOverlay.closed()
          }
        }
      }

      // Divider
      Rectangle {
        id: actDivider
        anchors.top: actHeader.bottom
        anchors.topMargin: Style.space(6)
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Util.alpha(Color.menu.border, 0.3)
      }

      // Action List
      ListView {
        id: actList
        anchors.top: actDivider.bottom
        anchors.topMargin: Style.space(8)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: actFooter.top
        anchors.bottomMargin: Style.space(6)
        model: actionsOverlay.actionsList
        clip: true
        spacing: Style.space(3)
        currentIndex: actionsOverlay.selectedIndex

        delegate: Rectangle {
          id: actItem
          required property var modelData
          required property int index

          width: actList.width
          height: Style.space(36)
          radius: Style.space(4)
          color: index === actionsOverlay.selectedIndex ? Color.menu.selectedBackground : "transparent"

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.space(10)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: actItem.modelData.icon
              font.pixelSize: Style.space(14)
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              spacing: 1

              Text {
                text: actItem.modelData.title
                color: actItem.index === actionsOverlay.selectedIndex ? Color.menu.selectedText : Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.space(12)
                font.weight: actItem.index === actionsOverlay.selectedIndex ? Font.DemiBold : Font.Normal
              }

              Text {
                text: actItem.modelData.desc
                color: actItem.index === actionsOverlay.selectedIndex ? Color.menu.selectedText : Color.menu.text
                opacity: 0.7
                font.family: Style.font.family
                font.pixelSize: Style.space(10)
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: actionsOverlay.selectedIndex = actItem.index
            onClicked: actionsOverlay.executed(actItem.modelData.id, actionsOverlay.targetPath)
          }
        }
      }

      // Keyboard Hints Footer
      Row {
        id: actFooter
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: Style.space(20)
        spacing: Style.space(12)
        opacity: 0.7

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "↑↓ Navigate  •  ↵ Execute  •  Esc Return"
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.space(11)
        }
      }
    }
  }
}
