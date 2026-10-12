import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: tabsRoot

  signal tabSelected(string tab)
  signal subFilterSelected(string ext)

  property string activeTab: "all"
  property string activeSubFilter: "all"
  property string fontFamily: Style.font.family
  property int captionSize: 11
  property int contentSize: 12

  readonly property var tabs: [
    { id: "all", label: "All" },
    { id: "folders", label: "Folders" },
    { id: "docs", label: "Docs" },
    { id: "code", label: "Code" },
    { id: "office", label: "Office" },
    { id: "images", label: "Images" }
  ]

  readonly property var subFiltersMap: ({
    "docs": [
      { id: "all", label: "All Docs" },
      { id: "md", label: "Markdown (.md)" },
      { id: "pdf", label: "PDF (.pdf)" },
      { id: "txt", label: "Text (.txt)" },
      { id: "org", label: "Org (.org)" }
    ],
    "code": [
      { id: "all", label: "All Code" },
      { id: "py", label: ".py" },
      { id: "js", label: ".js" },
      { id: "ts", label: ".ts" },
      { id: "sh", label: ".sh" },
      { id: "json", label: ".json" },
      { id: "html", label: ".html" },
      { id: "css", label: ".css" },
      { id: "lua", label: ".lua" },
      { id: "c", label: ".c / .cpp" },
      { id: "rs", label: ".rs" }
    ],
    "office": [
      { id: "all", label: "All Office" },
      { id: "docx", label: "Word (.docx)" },
      { id: "xlsx", label: "Excel (.xlsx)" },
      { id: "pptx", label: "PPT (.pptx)" },
      { id: "csv", label: "CSV (.csv)" }
    ],
    "images": [
      { id: "all", label: "All Images" },
      { id: "png", label: "PNG (.png)" },
      { id: "jpg", label: "JPG (.jpg)" },
      { id: "webp", label: "WebP (.webp)" },
      { id: "svg", label: "SVG (.svg)" }
    ]
  })

  readonly property var currentSubFilters: subFiltersMap[activeTab] || []
  readonly property bool hasSubFilters: currentSubFilters.length > 0

  spacing: Style.space(6)

  // Row 1: Main Category Chips
  Row {
    spacing: Style.space(6)
    height: Style.space(28)

    Repeater {
      model: tabsRoot.tabs

      Rectangle {
        id: chip
        required property var modelData
        required property int index

        width: chipLabel.implicitWidth + Style.space(16)
        height: Style.space(28)
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

  // Row 2: Dynamic Sub-Filters wrapped in Flickable (Prevents any horizontal overflow)
  Flickable {
    id: subFlick
    visible: tabsRoot.hasSubFilters
    opacity: tabsRoot.hasSubFilters ? 1 : 0
    width: parent.width
    height: tabsRoot.hasSubFilters ? Style.space(24) : 0
    contentWidth: subRow.implicitWidth
    contentHeight: height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.HorizontalFlick

    Behavior on opacity {
      NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Row {
      id: subRow
      spacing: Style.space(5)
      height: parent.height

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "↳"
        color: Color.accent
        opacity: 0.8
        font.family: tabsRoot.fontFamily
        font.pixelSize: tabsRoot.captionSize
      }

      Repeater {
        model: tabsRoot.currentSubFilters

        Rectangle {
          id: subChip
          required property var modelData
          required property int index

          width: subLabel.implicitWidth + Style.space(12)
          height: Style.space(22)
          radius: Style.space(3)
          color: subChip.modelData.id === tabsRoot.activeSubFilter
            ? Util.alpha(Color.menu.selectedBackground, 0.5)
            : Util.alpha(Color.menu.border, 0.15)
          border.width: 1
          border.color: subChip.modelData.id === tabsRoot.activeSubFilter
            ? Color.menu.selectedBackground
            : Util.alpha(Color.menu.border, 0.35)

          Text {
            id: subLabel
            anchors.centerIn: parent
            text: subChip.modelData.label
            textFormat: Text.PlainText
            color: subChip.modelData.id === tabsRoot.activeSubFilter
              ? Color.menu.selectedText
              : Color.menu.text
            opacity: subChip.modelData.id === tabsRoot.activeSubFilter ? 1 : 0.75
            font.family: tabsRoot.fontFamily
            font.pixelSize: tabsRoot.captionSize
            font.weight: subChip.modelData.id === tabsRoot.activeSubFilter ? Font.Bold : Font.Normal
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tabsRoot.subFilterSelected(subChip.modelData.id)
          }
        }
      }
    }
  }
}
