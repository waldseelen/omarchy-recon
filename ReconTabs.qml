import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: tabsRoot

  signal tabSelected(string tab)

  property string activeTab: "all"
  property string fontFamily: Style.font.menuFamily
  property int captionSize: 12
  property int contentSize: 13
  height: Style.space(28)

  readonly property var tabs: [
    { id: "all", label: "All" },
    { id: "folders", label: "Folders" },
    { id: "docs", label: "Docs" },
    { id: "code", label: "Code" },
    { id: "pdf", label: "PDF" },
    { id: "office", label: "Office" },
    { id: "images", label: "Images" }
  ]

  spacing: Style.space(6)

  Repeater {
    model: tabsRoot.tabs

    Rectangle {
      id: chip
      required property var modelData
      required property int index

      width: chipLabel.implicitWidth + Style.space(16)
      height: tabsRoot.height
      radius: Style.cornerRadius
      color: chip.modelData.id === tabsRoot.activeTab
        ? Color.menu.selectedBackground
        : "transparent"
      border.width: 1
      border.color: chip.modelData.id === tabsRoot.activeTab
        ? Color.menu.selectedBackground
        : Util.alpha(Color.menu.border, 0.4)

      Text {
        id: chipLabel
        anchors.centerIn: parent
        text: chip.modelData.label
        textFormat: Text.PlainText
        color: chip.modelData.id === tabsRoot.activeTab
          ? Color.menu.selectedText
          : Color.menu.text
        opacity: chip.modelData.id === tabsRoot.activeTab ? 1 : 0.65
        font.family: tabsRoot.fontFamily
        font.pixelSize: tabsRoot.contentSize
        font.weight: chip.modelData.id === tabsRoot.activeTab ? Font.DemiBold : Font.Normal
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tabsRoot.tabSelected(chip.modelData.id)
      }
    }
  }
}
