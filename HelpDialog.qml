import Quickshell
import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: helpOverlay

  anchors.fill: parent
  color: Util.alpha(Color.menu.scrim, 0.75)
  z: 80
  focus: true
  Keys.priority: Keys.BeforeItem

  signal closed()

  function initFocus() {
    forceActiveFocus()
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape || event.key === Qt.Key_F1 || event.key === Qt.Key_Slash) {
      helpOverlay.closed()
      event.accepted = true
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: helpOverlay.closed()
  }

  BorderSurface {
    id: helpCard
    width: Math.min(Style.space(620), parent.width - Style.space(40))
    height: Math.min(Style.space(480), parent.height - Style.space(40))
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
      anchors.topMargin: helpCard.contentTopInset
      anchors.bottomMargin: helpCard.contentBottomInset
      anchors.leftMargin: helpCard.contentLeftInset
      anchors.rightMargin: helpCard.contentRightInset

      // Title
      Row {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(32)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: "⌨️ Recon Keyboard Shortcuts"
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading ? Style.font.heading : 15
          font.weight: Font.Bold
        }

        Rectangle {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: closeText.implicitWidth + Style.space(16)
          height: Style.space(24)
          radius: Style.space(4)
          color: closeMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.25)

          Text {
            id: closeText
            anchors.centerIn: parent
            text: "Close (Esc)"
            color: closeMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
          }

          MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: helpOverlay.closed()
          }
        }
      }

      // Shortcut Grid
      Flickable {
        anchors.top: titleBar.bottom
        anchors.topMargin: Style.space(8)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: shortcutsCol.implicitHeight
        clip: true

        Column {
          id: shortcutsCol
          width: parent.width
          spacing: Style.space(10)

          Repeater {
            model: [
              { section: "Navigation & Drill-down", items: [
                { key: "↑ / ↓  or  ^J / ^K", desc: "Select previous / next item" },
                { key: "Ctrl + →", desc: "Drill down into selected directory" },
                { key: "Ctrl + ←", desc: "Navigate up to parent directory" },
                { key: "Ctrl + 1..5", desc: "Jump to pinned directory bookmark" },
                { key: "PgUp / PgDn / Home / End", desc: "Jump across result list" }
              ]},
              { section: "Categories & Toggles", items: [
                { key: "Tab / Shift+Tab", desc: "Cycle category tabs" },
                { key: "Alt + 1..6", desc: "Direct category switch" },
                { key: "Ctrl + F  or  prefix '?'", desc: "Toggle in-file content search" },
                { key: "Alt + I", desc: "Toggle .gitignore exclusion" },
                { key: "Alt + P", desc: "Toggle preview layout (Side vs Bottom)" }
              ]},
              { section: "Actions & File Operations", items: [
                { key: "Enter (↵)", desc: "Open item in default app (or jump to line)" },
                { key: "Alt + Enter", desc: "Reveal containing folder" },
                { key: "Ctrl + Space", desc: "Toggle item selection (multi-select)" },
                { key: "Alt + A", desc: "Open Power Actions menu" },
                { key: "F2", desc: "In-place rename" },
                { key: "Ctrl + N", desc: "In-place create new file / note" },
                { key: "Delete / Ctrl + D", desc: "Move selected / marked to trash" },
                { key: "Ctrl + C", desc: "Copy path (or all marked paths)" }
              ]}
            ]

            delegate: Column {
              id: secDelegate
              required property var modelData
              width: shortcutsCol.width
              spacing: Style.space(4)

              Text {
                text: secDelegate.modelData.section
                color: Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.weight: Font.DemiBold
              }

              Repeater {
                model: secDelegate.modelData.items
                delegate: Row {
                  id: itemRow
                  required property var modelData
                  width: secDelegate.width
                  height: Style.space(22)
                  spacing: Style.space(12)

                  Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.space(170)
                    height: Style.space(20)
                    radius: Style.space(3)
                    color: Util.alpha(Color.menu.selectedBackground, 0.15)
                    border.width: 1
                    border.color: Util.alpha(Color.menu.border, 0.3)

                    Text {
                      anchors.centerIn: parent
                      text: itemRow.modelData.key
                      color: Color.menu.selectedText
                      font.family: Style.font.family
                      font.pixelSize: Style.space(10)
                      font.weight: Font.Bold
                    }
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: itemRow.modelData.desc
                    color: Color.menu.text
                    opacity: 0.8
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
