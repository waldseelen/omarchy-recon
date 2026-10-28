import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
  id: previewRoot

  property string fullPath: ""
  property string fileName: ""
  property string tag: ""
  property string sizeText: ""
  property string content: ""
  property bool isImage: false
  property bool isDir: false
  property bool isLoading: false
  property string layout: "side" // "side" | "bottom"

  signal copyRequested()

  clip: true

  onContentChanged: {
    textFlickable.contentY = 0
  }

  // Divider (Vertical for side layout, Horizontal for bottom layout)
  Rectangle {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: previewRoot.layout === "side" ? parent.bottom : undefined
    anchors.right: previewRoot.layout === "bottom" ? parent.right : undefined
    width: previewRoot.layout === "side" ? 1 : parent.width
    height: previewRoot.layout === "bottom" ? 1 : parent.height
    color: Util.alpha(Color.menu.border, 0.4)
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: previewRoot.layout === "side" ? Style.space(16) : Style.space(4)
    anchors.topMargin: previewRoot.layout === "bottom" ? Style.space(8) : Style.space(0)

    // Preview Header Bar
    Rectangle {
      id: headerBar
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: Style.space(42)
      color: "transparent"

      Row {
        id: titleRow
        anchors.left: parent.left
        anchors.right: copyBtn.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)

        // Type Badge
        Rectangle {
          id: previewTagBadge
          visible: previewRoot.tag.length > 0
          anchors.verticalCenter: parent.verticalCenter
          width: pTagText.implicitWidth + Style.space(10)
          height: Style.space(20)
          radius: Style.space(3)
          color: previewRoot.tag === "ARCHIVE" ? Util.alpha(Color.accent, 0.3) :
            (previewRoot.tag === "MEDIA" ? Util.alpha(Color.accent, 0.25) :
            (previewRoot.tag === "MATCH" ? Util.alpha(Color.accent, 0.35) : Util.alpha(Color.menu.border, 0.3)))

          Text {
            id: pTagText
            anchors.centerIn: parent
            text: previewRoot.tag
            color: (previewRoot.tag === "ARCHIVE" || previewRoot.tag === "MEDIA" || previewRoot.tag === "MATCH") ? Color.accent : Color.menu.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.weight: Font.Bold
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - (previewTagBadge.visible ? previewTagBadge.width + Style.space(8) : 0)
          spacing: Style.space(2)

          Text {
            text: previewRoot.fileName || "Preview"
            color: Color.menu.text
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: (previewRoot.sizeText ? previewRoot.sizeText + "  ·  " : "") + previewRoot.fullPath
            color: Color.menu.text
            opacity: 0.55
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            elide: Text.ElideMiddle
            width: parent.width
          }
        }
      }

      // Quick Copy Content Button
      Rectangle {
        id: copyBtn
        visible: previewRoot.fullPath.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: copyLabel.implicitWidth + Style.space(16)
        height: Style.space(26)
        radius: Style.space(4)
        color: copyMouse.containsMouse ? Color.menu.selectedBackground : Util.alpha(Color.menu.border, 0.3)

        Text {
          id: copyLabel
          anchors.centerIn: parent
          text: previewRoot.content.length > 0 ? "Copy All" : "Copy Path"
          color: copyMouse.containsMouse ? Color.menu.selectedText : Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.weight: Font.Medium
        }

        MouseArea {
          id: copyMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: previewRoot.copyRequested()
        }
      }
    }

    // Horizontal Divider
    Rectangle {
      id: subDivider
      anchors.top: headerBar.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: Util.alpha(Color.menu.border, 0.25)
    }

    // Content Body
    Item {
      anchors.top: subDivider.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.topMargin: Style.space(10)

      // Image Preview
      Image {
        id: imgPreview
        visible: previewRoot.isImage
        anchors.fill: parent
        source: previewRoot.isImage ? "file://" + previewRoot.fullPath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
      }

      // Selectable Text Area (Mouse selection works natively!)
      Flickable {
        id: textFlickable
        visible: !previewRoot.isImage && previewRoot.content.length > 0
        anchors.fill: parent
        contentWidth: width
        contentHeight: textEdit.paintedHeight
        clip: true

        TextEdit {
          id: textEdit
          width: textFlickable.width
          height: Math.max(textFlickable.height, paintedHeight)
          readOnly: true
          selectByMouse: true
          selectionColor: Color.menu.selectedBackground
          selectedTextColor: Color.menu.selectedText
          color: Color.menu.text
          text: previewRoot.content
          textFormat: TextEdit.PlainText
          wrapMode: TextEdit.WrapAnywhere
          font.family: Style.font.family
          font.pixelSize: Style.space(12)
        }
      }

      // Empty / Placeholder State
      Column {
        anchors.centerIn: parent
        spacing: Style.space(10)
        visible: previewRoot.content.length === 0 && !previewRoot.isImage

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: previewRoot.isDir ? "📁" : (previewRoot.tag === "ARCHIVE" ? "📦" : (previewRoot.tag === "MEDIA" ? "🎵" : "📄"))
          font.pixelSize: Style.space(32)
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: previewRoot.fullPath ? (previewRoot.isLoading ? "Loading preview..." : "No preview available") : "Select an item to preview"
          color: Color.menu.text
          opacity: 0.5
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }
    }
  }
}
