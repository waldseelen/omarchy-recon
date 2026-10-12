import Quickshell
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Rectangle {
  id: settingsOverlay

  anchors.fill: parent
  color: Util.alpha(Color.menu.scrim, 0.75)
  z: 50

  property string targetDir: "/run/media/hp/SSS"
  property var excludeDirs: []
  property var excludeExts: []
  property bool excludeHidden: true
  property string fontFamily: Style.font.family

  signal saved(string newTarget, var newDirs, var newExts, bool newHidden)
  signal closed()

  // Local editable copies
  property string localTargetDir: targetDir
  property var localDirs: []
  property var localExts: []
  property bool localHidden: excludeHidden

  Component.onCompleted: {
    resetToCurrent()
  }

  onTargetDirChanged: resetToCurrent()
  onExcludeDirsChanged: resetToCurrent()
  onExcludeExtsChanged: resetToCurrent()
  onExcludeHiddenChanged: resetToCurrent()

  function resetToCurrent() {
    localTargetDir = targetDir
    localDirs = (excludeDirs || []).slice(0)
    localExts = (excludeExts || []).slice(0)
    localHidden = excludeHidden
  }

  function addFolder(name) {
    var n = String(name || "").trim()
    if (!n) return
    var arr = localDirs.slice(0)
    if (arr.indexOf(n) === -1) {
      arr.push(n)
      localDirs = arr
    }
  }

  function removeFolder(index) {
    var arr = localDirs.slice(0)
    arr.splice(index, 1)
    localDirs = arr
  }

  function addExt(ext) {
    var e = String(ext || "").trim().replace(/^\./, "").toLowerCase()
    if (!e) return
    var arr = localExts.slice(0)
    if (arr.indexOf(e) === -1) {
      arr.push(e)
      localExts = arr
    }
  }

  function removeExt(index) {
    var arr = localExts.slice(0)
    arr.splice(index, 1)
    localExts = arr
  }

  function applyDefaults() {
    localTargetDir = "/run/media/hp/SSS"
    localDirs = ["DOTFILES", "BRAIN", "KUBUNTU", "WIN", "MEDIA", ".Trash-1000", "node_modules", ".git"]
    localExts = ["tmp", "bak", "log", "iso", "bin"]
    localHidden = true
  }

  function saveAndClose() {
    settingsOverlay.saved(localTargetDir, localDirs, localExts, localHidden)
  }

  // Click outside to cancel
  MouseArea {
    anchors.fill: parent
    onClicked: settingsOverlay.closed()
  }

  BorderSurface {
    id: dialogCard
    width: Math.min(Style.space(800), parent.width - Style.space(40))
    height: Math.min(Style.space(560), parent.height - Style.space(40))
    radius: Style.cornerRadius
    anchors.centerIn: parent
    color: Color.menu.background
    borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
    padding: Style.spacing.panelPadding

    // Prevent clicks from falling through
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Column {
      anchors.fill: parent
      spacing: Style.space(12)

      // Header Bar
      Rectangle {
        width: parent.width
        height: Style.space(34)
        color: "transparent"

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "⚙ Recon Settings & Exclusions"
          color: Color.menu.text
          font.family: settingsOverlay.fontFamily
          font.pixelSize: Style.font.heading ? Style.font.heading : 15
          font.weight: Font.Bold
        }

        Rectangle {
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
            onClicked: settingsOverlay.closed()
          }
        }
      }

      // Divider
      Rectangle {
        width: parent.width
        height: 1
        color: Util.alpha(Color.menu.border, 0.3)
      }

      // Scrollable Settings Content
      Flickable {
        width: parent.width
        height: parent.height - Style.space(34 + 1 + 12 + 36 + 12)
        contentHeight: settingsContent.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: settingsContent
          width: parent.width
          spacing: Style.space(14)

          // 1. Target Directory
          Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "📁 Target Search Directory"
              color: Color.menu.text
              font.family: settingsOverlay.fontFamily
              font.pixelSize: Style.space(12)
              font.weight: Font.DemiBold
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              Rectangle {
                width: parent.width - Style.space(190)
                height: Style.space(32)
                radius: Style.cornerRadius
                color: Util.alpha(Color.menu.selectedBackground, 0.15)
                border.width: 1
                border.color: Util.alpha(Color.menu.border, 0.4)

                TextInput {
                  id: targetInput
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  verticalAlignment: TextInput.AlignVCenter
                  text: settingsOverlay.localTargetDir
                  color: Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(12)
                  clip: true
                  onTextChanged: settingsOverlay.localTargetDir = text
                }
              }

              Rectangle {
                width: Style.space(85)
                height: Style.space(32)
                radius: Style.cornerRadius
                color: sssBtnMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.3)

                Text {
                  anchors.centerIn: parent
                  text: "SSS Drive"
                  color: sssBtnMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                }

                MouseArea {
                  id: sssBtnMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsOverlay.localTargetDir = "/run/media/hp/SSS"
                }
              }

              Rectangle {
                width: Style.space(85)
                height: Style.space(32)
                radius: Style.cornerRadius
                color: homeBtnMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.3)

                Text {
                  anchors.centerIn: parent
                  text: "Home (~)"
                  color: homeBtnMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                }

                MouseArea {
                  id: homeBtnMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: settingsOverlay.localTargetDir = Quickshell.env("HOME")
                }
              }
            }
          }

          // 2. Excluded Directories
          Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "🚫 Excluded Directories (Skipped from indexing and recursive search)"
              color: Color.menu.text
              font.family: settingsOverlay.fontFamily
              font.pixelSize: Style.space(12)
              font.weight: Font.DemiBold
            }

            // Excluded Folders Chips Flow
            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: settingsOverlay.localDirs

                Rectangle {
                  id: dirChip
                  required property string modelData
                  required property int index

                  width: chipRow.implicitWidth + Style.space(14)
                  height: Style.space(24)
                  radius: Style.space(4)
                  color: Util.alpha(Color.menu.selectedBackground, 0.25)
                  border.width: 1
                  border.color: Util.alpha(Color.menu.border, 0.4)

                  Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Style.space(6)

                    Text {
                      text: "📁 " + dirChip.modelData
                      color: Color.menu.text
                      font.family: settingsOverlay.fontFamily
                      font.pixelSize: Style.space(11)
                    }

                    Text {
                      text: "✕"
                      color: Color.urgent ? Color.urgent : "#ff6b6b"
                      font.pixelSize: Style.space(11)
                      font.weight: Font.Bold

                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsOverlay.removeFolder(dirChip.index)
                      }
                    }
                  }
                }
              }
            }

            // Add Folder Row
            Row {
              width: parent.width
              spacing: Style.space(8)

              Rectangle {
                width: Style.space(320)
                height: Style.space(30)
                radius: Style.cornerRadius
                color: Util.alpha(Color.menu.selectedBackground, 0.15)
                border.width: 1
                border.color: Util.alpha(Color.menu.border, 0.4)

                TextInput {
                  id: folderInput
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  verticalAlignment: TextInput.AlignVCenter
                  color: Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                  clip: true

                  Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !folderInput.text
                    text: "+ Folder name (e.g. private, cache)..."
                    color: Color.menu.text
                    opacity: 0.45
                    font.family: settingsOverlay.fontFamily
                    font.pixelSize: Style.space(11)
                  }

                  Keys.onReturnPressed: {
                    settingsOverlay.addFolder(folderInput.text)
                    folderInput.text = ""
                  }
                }
              }

              Rectangle {
                width: Style.space(80)
                height: Style.space(30)
                radius: Style.cornerRadius
                color: addDirMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.3)

                Text {
                  anchors.centerIn: parent
                  text: "+ Add"
                  color: addDirMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                }

                MouseArea {
                  id: addDirMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    settingsOverlay.addFolder(folderInput.text)
                    folderInput.text = ""
                  }
                }
              }
            }

            // Hidden dot-folders toggle on dedicated line (ZERO overflow)
            Rectangle {
              height: Style.space(26)
              width: checkRow.implicitWidth + Style.space(12)
              radius: Style.cornerRadius
              color: "transparent"

              Row {
                id: checkRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(8)

                Rectangle {
                  width: Style.space(16)
                  height: Style.space(16)
                  radius: Style.space(3)
                  anchors.verticalCenter: parent.verticalCenter
                  color: settingsOverlay.localHidden ? Color.menu.selectedBackground : "transparent"
                  border.width: 1
                  border.color: settingsOverlay.localHidden ? Color.menu.selectedBorder : Util.alpha(Color.menu.border, 0.5)

                  Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: Color.menu.selectedText
                    font.pixelSize: Style.space(10)
                    font.weight: Font.Bold
                    visible: settingsOverlay.localHidden
                  }
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Exclude all hidden dot-folders (.* e.g. .git, .cache, .config)"
                  color: Color.menu.text
                  opacity: 0.85
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: settingsOverlay.localHidden = !settingsOverlay.localHidden
              }
            }
          }

          // 3. Excluded File Extensions
          Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "📄 Excluded File Extensions (Hidden from search results)"
              color: Color.menu.text
              font.family: settingsOverlay.fontFamily
              font.pixelSize: Style.space(12)
              font.weight: Font.DemiBold
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: settingsOverlay.localExts

                Rectangle {
                  id: extChip
                  required property string modelData
                  required property int index

                  width: extChipRow.implicitWidth + Style.space(14)
                  height: Style.space(24)
                  radius: Style.space(4)
                  color: Util.alpha(Color.menu.selectedBackground, 0.25)
                  border.width: 1
                  border.color: Util.alpha(Color.menu.border, 0.4)

                  Row {
                    id: extChipRow
                    anchors.centerIn: parent
                    spacing: Style.space(6)

                    Text {
                      text: "." + extChip.modelData
                      color: Color.menu.text
                      font.family: settingsOverlay.fontFamily
                      font.pixelSize: Style.space(11)
                      font.weight: Font.Medium
                    }

                    Text {
                      text: "✕"
                      color: Color.urgent ? Color.urgent : "#ff6b6b"
                      font.pixelSize: Style.space(11)
                      font.weight: Font.Bold

                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsOverlay.removeExt(extChip.index)
                      }
                    }
                  }
                }
              }
            }

            // Add Ext Row
            Row {
              width: parent.width
              spacing: Style.space(8)

              Rectangle {
                width: Style.space(320)
                height: Style.space(30)
                radius: Style.cornerRadius
                color: Util.alpha(Color.menu.selectedBackground, 0.15)
                border.width: 1
                border.color: Util.alpha(Color.menu.border, 0.4)

                TextInput {
                  id: extInput
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  verticalAlignment: TextInput.AlignVCenter
                  color: Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                  clip: true

                  Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: !extInput.text
                    text: "+ Extension (e.g. tmp, bak, log)..."
                    color: Color.menu.text
                    opacity: 0.45
                    font.family: settingsOverlay.fontFamily
                    font.pixelSize: Style.space(11)
                  }

                  Keys.onReturnPressed: {
                    settingsOverlay.addExt(extInput.text)
                    extInput.text = ""
                  }
                }
              }

              Rectangle {
                width: Style.space(80)
                height: Style.space(30)
                radius: Style.cornerRadius
                color: addExtMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.3)

                Text {
                  anchors.centerIn: parent
                  text: "+ Add"
                  color: addExtMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
                  font.family: settingsOverlay.fontFamily
                  font.pixelSize: Style.space(11)
                }

                MouseArea {
                  id: addExtMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    settingsOverlay.addExt(extInput.text)
                    extInput.text = ""
                  }
                }
              }
            }
          }
        }
      }

      // Footer Action Buttons (Anchored Layout - Zero Overflow)
      Item {
        width: parent.width
        height: Style.space(36)

        // Left Action: Reset
        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: resetText.implicitWidth + Style.space(24)
          height: parent.height
          radius: Style.cornerRadius
          color: resetMouse.containsMouse ? Util.alpha(Color.menu.border, 0.4) : Util.alpha(Color.menu.border, 0.2)
          border.width: 1
          border.color: Util.alpha(Color.menu.border, 0.4)

          Text {
            id: resetText
            anchors.centerIn: parent
            text: "Reset Defaults"
            color: Color.menu.text
            opacity: 0.8
            font.family: settingsOverlay.fontFamily
            font.pixelSize: Style.space(11)
          }

          MouseArea {
            id: resetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsOverlay.applyDefaults()
          }
        }

        // Right Actions: Cancel & Save
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(10)

          Rectangle {
            width: cancelText.implicitWidth + Style.space(24)
            height: parent.parent.height
            radius: Style.cornerRadius
            color: cancelMouse.containsMouse ? Util.alpha(Color.menu.border, 0.4) : Util.alpha(Color.menu.border, 0.2)
            border.width: 1
            border.color: Util.alpha(Color.menu.border, 0.4)

            Text {
              id: cancelText
              anchors.centerIn: parent
              text: "Cancel"
              color: Color.menu.text
              opacity: 0.85
              font.family: settingsOverlay.fontFamily
              font.pixelSize: Style.space(11)
            }

            MouseArea {
              id: cancelMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: settingsOverlay.closed()
            }
          }

          Rectangle {
            width: saveText.implicitWidth + Style.space(28)
            height: parent.parent.height
            radius: Style.cornerRadius
            color: saveMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.selectedBackground, 0.85)
            border.width: 1
            border.color: Color.menu.selectedBorder

            Text {
              id: saveText
              anchors.centerIn: parent
              text: "Save & Apply"
              color: Color.menu.selectedText
              font.family: settingsOverlay.fontFamily
              font.pixelSize: Style.space(11)
              font.weight: Font.Bold
            }

            MouseArea {
              id: saveMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: settingsOverlay.saveAndClose()
            }
          }
        }
      }
    }
  }
}
