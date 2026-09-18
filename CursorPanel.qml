import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// A cursor-positioned host for the same content used by the bar panel.
PanelWindow {
  id: root

  property bool open: false
  property point cursorPosition: Qt.point(0, 0)
  property Item focusTarget: null
  property bool focusPrimed: false
  property int margin: Style.gapsOut
  property int contentWidth: Math.min(Style.space(400), Math.max(1, width - margin * 2))
  property int contentHeight: Math.min(Style.space(440), Math.max(1, height - margin * 2))
  property alias contentHost: contentHolder
  signal dismissed()

  visible: open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.namespace: "omarchy-keyboard-panel"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: !open ? WlrKeyboardFocus.None
    : (focusPrimed ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive)

  function focusContent() {
    if (!open || !backingWindowVisible) return
    focusPrimeTimer.restart()
    Qt.callLater(function() {
      if (root.open && root.focusTarget) root.focusTarget.forceActiveFocus()
    })
  }

  onOpenChanged: {
    focusPrimed = false
    if (open) focusContent()
    else focusPrimeTimer.stop()
  }
  onBackingWindowVisibleChanged: focusContent()

  Timer {
    id: focusPrimeTimer
    interval: 75
    onTriggered: if (root.open) root.focusPrimed = true
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: root.dismissed()
  }

  BorderSurface {
    id: card
    // Keep the search row under the pointer, clamping at display edges.
    x: Math.max(root.margin, Math.min(root.cursorPosition.x - width / 2, root.width - width - root.margin))
    y: Math.max(root.margin, Math.min(root.cursorPosition.y - Style.space(30), root.height - height - root.margin))
    width: root.contentWidth
    height: root.contentHeight
    color: Color.popups.background
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    padding: Style.spacing.popupPadding
    radius: Style.cornerRadius

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.topMargin: card.contentTopInset
      anchors.rightMargin: card.contentRightInset
      anchors.bottomMargin: card.contentBottomInset
      anchors.leftMargin: card.contentLeftInset
    }
  }

  Variants {
    model: root.open ? Quickshell.screens : []
    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData
        visible: root.open && !!root.screen && modelData.name !== root.screen.name
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "omarchy-keyboard-panel-dismiss"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          onPressed: root.dismissed()
        }
      }
    }
  }
}
