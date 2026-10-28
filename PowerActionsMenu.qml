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
    { id: "copyUri", icon: "📎", title: "Copy File (URI)", desc: "Copy file:// URI for file managers" },
    { id: "copyRelPath", icon: "📋", title: "Copy Relative Path", desc: "Copy path relative to target drive" },
    { id: "copyContent", icon: "📄", title: "Copy File Content", desc: "Copy entire preview text to clipboard" },
    { id: "duplicate", icon: "📑", title: "Duplicate Item", desc: "Create an exact copy of file" },
    { id: "move", icon: "📦", title: "Move Item", desc: "Move item to destination folder" },
    { id: "trash", icon: "🗑️", title: "Move to Trash", desc: "Send safely to system trash" }
  ]

  function selectDelta(delta) {
    selectedIndex = Math.max(0, Math.min(actionsList.length - 1, selectedIndex + delta))
  }

  function triggerSelected() {
    var act = actionsList[selectedIndex]
    if (act) executed(act.id, targetPath)
  }

  function initFocus() {
    selectedIndex = 0
    forceActiveFocus()
  }

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
    height: Math.min(Style.space(420), parent.height - Style.space(40))
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
      Column {
        id: headerBox
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(2)

        Text {
          text: "Actions for " + (actionsOverlay.targetName || "Item")
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading ? Style.font.heading : 14
          font.weight: Font.Bold
          elide: Text.ElideRight
          width: parent.width
        }

        Text {
          text: actionsOverlay.targetPath
          color: Color.menu.text
          opacity: 0.55
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideMiddle
          width: parent.width
        }
      }

      // Actions List
      ListView {
        id: actionsView
        anchors.top: headerBox.bottom
        anchors.topMargin: Style.space(10)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerHint.top
        anchors.bottomMargin: Style.space(8)
        model: actionsOverlay.actionsList
        clip: true
        spacing: Style.space(4)
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
          id: actionItem
          required property int index
          required property var modelData

          width: ListView.view ? ListView.view.width : Style.space(440)
          height: Style.space(34)
          radius: Style.cornerRadius
          color: index === actionsOverlay.selectedIndex ? Color.menu.selectedBackground : (itemMouse.containsMouse ? Util.alpha(Color.menu.selectedBackground, 0.2) : "transparent")

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.space(10)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: actionItem.modelData.icon
              font.pixelSize: Style.space(14)
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width - Style.space(32)
              spacing: Style.space(1)

              Text {
                text: actionItem.modelData.title
                color: index === actionsOverlay.selectedIndex ? Color.menu.selectedText : Color.menu.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body ? Style.font.body : 12
                font.weight: index === actionsOverlay.selectedIndex ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: actionItem.modelData.desc
                color: index === actionsOverlay.selectedIndex ? Color.menu.selectedText : Color.menu.text
                opacity: index === actionsOverlay.selectedIndex ? 0.85 : 0.55
                font.family: Style.font.family
                font.pixelSize: Style.font.caption ? Style.font.caption : 10
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              actionsOverlay.selectedIndex = actionItem.index
              actionsOverlay.executed(actionItem.modelData.id, actionsOverlay.targetPath)
            }
          }
        }
      }

      // Footer Hint
      Text {
        id: footerHint
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: "↑/↓ or ^J/^K to navigate  ·  ↵ to execute  ·  Esc to cancel"
        color: Color.menu.text
        opacity: 0.5
        font.family: Style.font.family
        font.pixelSize: Style.space(10)
      }
    }
  }
}
