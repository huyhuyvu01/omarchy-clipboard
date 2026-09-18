import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "ClipboardHistory.js" as ClipboardHistory

Panel {
  id: root
  moduleName: "io.github.vuhuy.clipboard-manager"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var history: []
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool clearConfirmOpen: false

  readonly property var barIdentity: hostWidget || root
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
  readonly property string historyPath: Quickshell.env("HOME") + "/.local/state/omarchy/clipboard-history.json"
  readonly property int maxResults: Math.max(10, Math.min(150, Number(setting("maxResults", 50)) || 50))
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() {
    filterText = ""
    selectedIndex = 0
    cursorActive = true
    clearConfirmOpen = false
    historyFile.reload()
    rebuildDisplay()
    controller.show()
  }

  function close() {
    clearConfirmOpen = false
    controller.hide()
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function loadHistory(raw) {
    history = ClipboardHistory.parseHistory(raw)
    rebuildDisplay()
  }

  function saveHistory() {
    historyFile.setText(JSON.stringify(history, null, 2) + "\n")
  }

  function rebuildDisplay() {
    var rows = ClipboardHistory.displayRows(history, filterText, maxResults)
    displayModel.clear()
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      displayModel.append({
        entryType: row.entryType,
        fullText: row.fullText,
        previewText: row.previewText,
        previewImage: row.previewImage ? Util.fileUrl(row.previewImage) : "",
        path: row.path,
        mime: row.mime,
        historyIndex: row.index
      })
    }

    if (displayModel.count === 0) selectedIndex = 0
    else selectedIndex = Math.max(0, Math.min(selectedIndex, displayModel.count - 1))

    Qt.callLater(function() {
      if (displayModel.count > 0)
        resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
  }

  function setFilter(value) {
    filterText = value
    selectedIndex = 0
    cursorActive = true
    rebuildDisplay()
  }

  function moveSelection(delta) {
    if (displayModel.count === 0) return
    cursorActive = true
    selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function removeIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var historyIndex = displayModel.get(index).historyIndex
    history = ClipboardHistory.removeEntryAt(history, historyIndex)
    if (selectedIndex >= displayModel.count - 1) selectedIndex = Math.max(0, displayModel.count - 2)
    saveHistory()
    rebuildDisplay()
  }

  function clearHistory() {
    history = []
    selectedIndex = 0
    cursorActive = false
    clearConfirmOpen = false
    saveHistory()
    rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function activateIndex(index, copyOnly) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    close()

    if (row.entryType === "image") {
      var imageArgs = [omarchyPath + "/bin/omarchy-clipboard-paste-file"]
      if (copyOnly) imageArgs.push("--copy-only")
      imageArgs.push(row.mime, row.path)
      Quickshell.execDetached(imageArgs)
    } else if (row.fullText) {
      var textArgs = [omarchyPath + "/bin/omarchy-clipboard-paste-text"]
      if (copyOnly) textArgs.push("--copy-only")
      else textArgs.push("--shift-insert")
      textArgs.push("--history-index", String(row.historyIndex))
      Quickshell.execDetached(textArgs)
    }
  }

  function openIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    close()
    Quickshell.execDetached([
      omarchyPath + "/bin/omarchy-clipboard-open",
      "--history-index",
      String(row.historyIndex)
    ])
  }

  FileView {
    id: historyFile
    path: root.historyPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadHistory(text())
    onLoadFailed: root.loadHistory("[]")
    onFileChanged: reload()
  }

  ListModel { id: displayModel }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.cappedContentHeight(Style.space(440))

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (root.clearConfirmOpen) {
          if (event.key === Qt.Key_Escape) {
            root.clearConfirmOpen = false
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clearHistory()
            event.accepted = true
          }
          return
        }

        if (event.key === Qt.Key_Escape) {
          if (root.filterText) root.setFilter("")
          else root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
          if (root.filterText.length > 0)
            root.setFilter(root.filterText.substring(0, root.filterText.length - 1))
          event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
          if (event.modifiers & Qt.ShiftModifier) root.clearConfirmOpen = root.history.length > 0
          else root.removeIndex(root.selectedIndex)
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.moveSelection(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.moveSelection(1)
          event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
          root.moveSelection(-7)
          event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
          root.moveSelection(7)
          event.accepted = true
        } else if (event.key === Qt.Key_Home) {
          root.selectedIndex = 0
          resultList.positionViewAtBeginning()
          event.accepted = true
        } else if (event.key === Qt.Key_End) {
          root.selectedIndex = Math.max(0, displayModel.count - 1)
          resultList.positionViewAtEnd()
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (event.modifiers & Qt.AltModifier) root.openIndex(root.selectedIndex)
          else root.activateIndex(root.selectedIndex, !!(event.modifiers & Qt.ShiftModifier))
          event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_U) {
          root.setFilter("")
          event.accepted = true
        } else if (event.text && event.text.length === 1
                   && event.text.charCodeAt(0) >= 32
                   && event.text.charCodeAt(0) !== 127) {
          root.setFilter(root.filterText + event.text)
          event.accepted = true
        }
      }

      Column {
        anchors.fill: parent
        spacing: Style.space(8)

        // Compact search row: filter field, entry count, clear-all.
        Rectangle {
          width: parent.width
          height: Style.space(34)
          radius: Style.cornerRadius
          color: Style.normalFillFor(root.foreground)

          Text {
            id: searchGlyph
            anchors.left: parent.left
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Row {
            id: searchTrailing
            anchors.right: parent.right
            anchors.rightMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: root.history.length > 0
              text: String(root.history.length)
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Rectangle {
              id: clearAllButton
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(24)
              height: Style.space(24)
              radius: Style.cornerRadius
              enabled: root.history.length > 0
              opacity: enabled ? 1 : 0
              color: clearArea.containsMouse
                ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"

              Text {
                anchors.centerIn: parent
                text: "󰆼"
                color: clearArea.containsMouse ? root.foreground : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }

              MouseArea {
                id: clearArea
                anchors.fill: parent
                enabled: clearAllButton.enabled
                hoverEnabled: true
                cursorShape: clearAllButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.clearConfirmOpen = true
              }
            }
          }

          Text {
            anchors.left: searchGlyph.right
            anchors.leftMargin: Style.space(8)
            anchors.right: searchTrailing.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "Type to search…"
            color: root.filterText ? root.foreground : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
        }

        Item {
          width: parent.width
          height: parent.height - Style.space(34) - Style.space(18) - parent.spacing * 2
          clip: true

          ListView {
            id: resultList
            anchors.fill: parent
            model: displayModel
            spacing: Style.space(3)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              id: row
              required property int index
              required property string entryType
              required property string previewText
              required property string previewImage

              readonly property bool selected: root.cursorActive && index === root.selectedIndex

              width: ListView.view.width
              height: Style.space(30)
              radius: Style.cornerRadius
              color: selected || rowArea.containsMouse
                ? Style.hoverFillFor(root.foreground, root.accent)
                : "transparent"

              Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(3)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(2)
                height: parent.height - Style.space(12)
                radius: 1
                visible: row.selected
                color: root.accent
              }

              Item {
                id: lead
                anchors.left: parent.left
                anchors.leftMargin: Style.space(9)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(22)
                height: Style.space(22)

                Rectangle {
                  anchors.fill: parent
                  visible: row.previewImage.length > 0
                  radius: Math.max(2, Style.cornerRadius - 2)
                  color: Style.normalFillFor(root.foreground)
                  clip: true

                  Image {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: row.previewImage.length > 0
                    source: row.previewImage
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                  }
                }

                Text {
                  anchors.centerIn: parent
                  visible: row.previewImage.length === 0
                  text: row.entryType === "file" ? "" : "󰅌"
                  color: row.selected ? root.accent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }
              }

              Text {
                anchors.left: lead.right
                anchors.leftMargin: Style.space(8)
                anchors.right: deleteButton.left
                anchors.rightMargin: Style.space(4)
                anchors.verticalCenter: parent.verticalCenter
                text: row.previewText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Rectangle {
                id: deleteButton
                anchors.right: parent.right
                anchors.rightMargin: Style.space(4)
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(22)
                height: Style.space(22)
                radius: Style.cornerRadius
                opacity: row.selected || rowArea.containsMouse || deleteArea.containsMouse ? 1 : 0
                color: deleteArea.containsMouse
                  ? Style.hoverFillFor(Color.urgent, Color.urgent) : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "󰆴"
                  color: deleteArea.containsMouse ? Color.urgent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  id: deleteArea
                  anchors.fill: parent
                  enabled: deleteButton.opacity > 0
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.removeIndex(row.index)
                }
              }

              MouseArea {
                id: rowArea
                anchors.fill: parent
                z: 0
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.cursorActive = true
                  root.selectedIndex = row.index
                }
                onClicked: function(mouse) {
                  root.activateIndex(row.index, mouse.button === Qt.RightButton)
                }
              }
            }
          }

          Column {
            anchors.centerIn: parent
            visible: displayModel.count === 0
            spacing: Style.space(6)

            Text {
              width: parent.width
              text: root.history.length === 0 ? "󰅌" : ""
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              width: parent.width
              text: root.history.length === 0
                ? "Clipboard history is empty"
                : "No matches for “" + root.filterText + "”"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }

        Item {
          width: parent.width
          height: Style.space(18)

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ paste   ⇧↵ copy   ⌥↵ open"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "Del remove"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }

      Rectangle {
        anchors.fill: parent
        visible: root.clearConfirmOpen
        z: 20
        color: Color.popups.background

        MouseArea { anchors.fill: parent }

        Column {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(40), Style.space(300))
          spacing: Style.space(12)

          Text {
            width: parent.width
            text: "Clear clipboard history?"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width
            text: "This removes all saved text, files, and image references."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(10)

            Rectangle {
              width: Style.space(88)
              height: Style.space(30)
              radius: Style.cornerRadius
              color: cancelArea.containsMouse ? Style.hoverFillFor(root.foreground, root.accent) : "transparent"
              border.width: Style.normalBorderWidth
              border.color: root.dim

              Text {
                anchors.centerIn: parent
                text: "Cancel"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              MouseArea {
                id: cancelArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.clearConfirmOpen = false
                  keyCatcher.forceActiveFocus()
                }
              }
            }

            Rectangle {
              width: Style.space(88)
              height: Style.space(30)
              radius: Style.cornerRadius
              color: confirmArea.containsMouse ? Color.urgent : Style.normalFillFor(Color.urgent)

              Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              MouseArea {
                id: confirmArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearHistory()
              }
            }
          }

          Text {
            width: parent.width
            text: "Enter to confirm · Esc to cancel"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }
}
