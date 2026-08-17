import QtQuick
import qs.Ui

// The host injects `bar`, `moduleName`, and the inline `settings` object into
// every BarWidget. Shared qs.Ui controls inherit the active Omarchy theme.
BarWidget {
  id: root
  moduleName: "io.github.vuhuy.starter-widget"

  readonly property string label: String(setting("label", "Hello, Omarchy!"))
  readonly property string tooltip: String(setting("tooltip", "Left click to run the configured action"))
  readonly property string actionCommand: String(setting("command", "")).trim()
  readonly property bool useAccent: setting("accent", false) === true
  readonly property real horizontalMargin: Number(setting("horizontalMargin", 8))

  function activate() {
    if (!root.bar) return

    if (root.actionCommand) {
      root.bar.run(root.actionCommand)
    } else {
      root.bar.run("omarchy-notification-send " + root.bar.shellQuote(root.label))
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    tooltipText: root.tooltip
    active: root.useAccent
    horizontalMargin: root.horizontalMargin
    textRotation: root.vertical ? -90 : 0
    fixedHeight: root.vertical
      ? Math.max(root.barSize, labelWidth + scaledHorizontalMargin * 2)
      : -1

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.activate()
    }
  }
}
