import Quickshell
import QtQuick
import qs.Commons
import qs.Ui

Rectangle {
  id: modalOverlay

  anchors.fill: parent
  color: Util.alpha(Color.menu.scrim, 0.75)
  z: 70
  focus: true
  Keys.priority: Keys.BeforeItem

  property string mode: "rename" // "rename" | "newfile"
  property string targetPath: ""
  property string initialValue: ""
  property string promptText: mode === "rename" ? "Rename Item" : "Create New File / Note"
  property string subText: mode === "rename" ? targetPath : "File will be created in target directory"

  signal confirmed(string mode, string value, string targetPath)
  signal closed()

  function initFocus() {
    inputField.text = initialValue
    inputField.forceActiveFocus()
    if (mode === "rename") {
      var dotIdx = initialValue.lastIndexOf(".")
      if (dotIdx > 0) {
        inputField.select(0, dotIdx)
      } else {
        inputField.selectAll()
      }
    } else {
      inputField.selectAll()
    }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      modalOverlay.closed()
      event.accepted = true
      return
    }
    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      var val = inputField.text.trim()
      if (val) modalOverlay.confirmed(modalOverlay.mode, val, modalOverlay.targetPath)
      event.accepted = true
      return
    }
  }

  // Click outside to cancel
  MouseArea {
    anchors.fill: parent
    onClicked: modalOverlay.closed()
  }

  BorderSurface {
    id: modalCard
    width: Math.min(Style.space(460), parent.width - Style.space(40))
    height: Math.min(Style.space(210), parent.height - Style.space(40))
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
      anchors.topMargin: modalCard.contentTopInset
      anchors.bottomMargin: modalCard.contentBottomInset
      anchors.leftMargin: modalCard.contentLeftInset
      anchors.rightMargin: modalCard.contentRightInset

      // Title & Path
      Column {
        id: titleArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(3)

        Text {
          text: modalOverlay.promptText
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading ? Style.font.heading : 14
          font.weight: Font.Bold
        }

        Text {
          text: modalOverlay.subText
          color: Color.menu.text
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideMiddle
          width: parent.width
        }
      }

      // Input Box
      Rectangle {
        id: inputBox
        anchors.top: titleArea.bottom
        anchors.topMargin: Style.space(12)
        anchors.left: parent.left
        anchors.right: parent.right
        height: Style.space(34)
        radius: Style.cornerRadius
        color: Util.alpha(Color.menu.selectedBackground, 0.15)
        border.width: 2
        border.color: Color.accent

        TextInput {
          id: inputField
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)
          verticalAlignment: TextInput.AlignVCenter
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.space(12)
          clip: true
          selectByMouse: true
          selectionColor: Color.menu.selectedBackground
          selectedTextColor: Color.menu.selectedText

          Keys.onReturnPressed: {
            var val = inputField.text.trim()
            if (val) modalOverlay.confirmed(modalOverlay.mode, val, modalOverlay.targetPath)
          }
        }
      }

      // Action Buttons
      Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: Style.space(10)

        Rectangle {
          width: cancelText.implicitWidth + Style.space(22)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: cancelMouse.containsMouse ? Util.alpha(Color.menu.border, 0.4) : Util.alpha(Color.menu.border, 0.2)
          border.width: 1
          border.color: Util.alpha(Color.menu.border, 0.4)

          Text {
            id: cancelText
            anchors.centerIn: parent
            text: "Cancel (Esc)"
            color: Color.menu.text
            opacity: 0.8
            font.family: Style.font.family
            font.pixelSize: Style.space(11)
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modalOverlay.closed()
          }
        }

        Rectangle {
          width: confirmText.implicitWidth + Style.space(26)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: confirmMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.selectedBackground, 0.85)
          border.width: 1
          border.color: Color.menu.selectedBorder

          Text {
            id: confirmText
            anchors.centerIn: parent
            text: modalOverlay.mode === "rename" ? "Rename (↵)" : "Create (↵)"
            color: Color.menu.selectedText
            font.family: Style.font.family
            font.pixelSize: Style.space(11)
            font.weight: Font.Bold
          }

          MouseArea {
            id: confirmMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var val = inputField.text.trim()
              if (val) modalOverlay.confirmed(modalOverlay.mode, val, modalOverlay.targetPath)
            }
          }
        }
      }
    }
  }
}
