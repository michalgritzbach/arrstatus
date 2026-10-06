// Omarchy bar widget: download activity across qBittorrent, SABnzbd and the
// *arr services.
//
// The bar button carries the headline (total speed and active count); the
// popup panel is the detail view — one section per service, one row per item,
// with a progress meter, status and ETA.
//
// Data comes from `waybar/arrstatus.py --json` in this repo, which fetches
// every enabled service in one pass and prints a structured report. The panel
// only draws what that report contains.

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "michal.arrstatus"
  ipcTarget: "michal.arrstatus"
  // Our own handler below adds refresh, so the base must not claim the target.
  manageIpc: false

  // ---------------------------------------------------------------- theme

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // ---------------------------------------------------------------- state

  property var report: null
  // Set when the script itself could not run — a missing interpreter, a broken
  // path, a config the script refuses. Service-level failures live in the
  // report and are drawn per section instead.
  property string loadError: ""
  property double updatedAtMs: 0
  // Countdowns read this instead of Date.now() so "updated 40s ago" keeps
  // counting while the panel sits open.
  property double nowMs: Date.now()

  readonly property var services: report && report.services ? report.services : []
  readonly property var totals: report && report.totals ? report.totals : null
  readonly property real dlSpeed: totals ? Number(totals.dlSpeed || 0) : 0
  readonly property real upSpeed: totals ? Number(totals.upSpeed || 0) : 0
  readonly property int activeCount: totals ? Number(totals.activeCount || 0) : 0
  readonly property bool serviceErrors: !!(totals && totals.hasErrors)
  readonly property bool alarming: serviceErrors || loadError !== ""

  // Same rule the Waybar module had: nothing downloading and nothing broken
  // means nothing in the bar. An open panel keeps the button around so it does
  // not vanish from under the pointer.
  visible: activeCount > 0 || alarming || opened

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

  // ---------------------------------------------------------------- format

  function formatSpeed(bytesPerSecond) {
    var value = Number(bytesPerSecond) || 0
    if (value >= 1073741824) return (value / 1073741824).toFixed(1) + " GB/s"
    if (value >= 1048576) return (value / 1048576).toFixed(1) + " MB/s"
    if (value >= 1024) return Math.round(value / 1024) + " KB/s"
    return Math.round(value) + " B/s"
  }

  function plural(count, singular) {
    return count + " " + singular + (count === 1 ? "" : "s")
  }

  function barText() {
    if (activeCount > 0) return "↓ " + formatSpeed(dlSpeed) + "  ≡ " + activeCount
    if (alarming) return "⚠"
    return ""
  }

  function heroMeta() {
    if (loadError !== "") return "arrstatus unavailable"
    if (!report) return "loading"
    var parts = [activeCount + " active"]
    if (dlSpeed > 0) parts.push("↓ " + formatSpeed(dlSpeed))
    if (upSpeed > 0) parts.push("↑ " + formatSpeed(upSpeed))
    return parts.join(" · ")
  }

  function agoText() {
    if (updatedAtMs <= 0) return ""
    var seconds = Math.max(0, Math.round((nowMs - updatedAtMs) / 1000))
    if (seconds < 60) return "Updated " + seconds + "s ago"
    var minutes = Math.round(seconds / 60)
    if (minutes < 60) return "Updated " + minutes + "m ago"
    return "Updated " + Math.round(minutes / 60) + "h ago"
  }

  // A service row's trailing text: whatever the item knows, in reading order.
  function itemMeta(item) {
    var parts = []
    if (item.status) parts.push(String(item.status))
    if (item.detail) parts.push(String(item.detail))
    if (item.eta) parts.push(String(item.eta))
    return parts.join(" · ")
  }

  function serviceMeta(service) {
    if (service.error) return String(service.error)
    if (service.summary) return String(service.summary)
    return service.activeCount > 0 ? plural(service.activeCount, "item") : "idle"
  }

  // ---------------------------------------------------------------- actions

  function openService(service) {
    if (!service || !service.url || !root.bar) return
    root.bar.run("xdg-open " + root.bar.shellQuote(String(service.url)))
    root.close()
  }

  function openFirstService() {
    for (var i = 0; i < services.length; i++) {
      if (services[i].url) return openService(services[i])
    }
  }

  function refreshNow() {
    if (proc.running) return
    if (bar && typeof bar.runProcess === "function") bar.runProcess(proc)
    else proc.running = true
  }

  function update(raw) {
    var trimmed = String(raw || "").trim()
    if (trimmed === "") {
      loadError = "no output from arrstatus.py --json"
      return
    }

    var parsed = null
    try {
      parsed = JSON.parse(trimmed)
    } catch (e) {
      loadError = "unreadable output: " + e
      return
    }

    if (!parsed || !parsed.services) {
      loadError = "unexpected report shape"
      return
    }

    loadError = ""
    report = parsed
    updatedAtMs = Date.now()
    nowMs = updatedAtMs
  }

  // ---------------------------------------------------------------- plumbing

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")

  // Plugin nested in the repo first, then a standalone install that carries
  // the script next to the QML.
  readonly property var scriptCandidates: [
    pluginDir + "/../waybar/arrstatus.py",
    pluginDir + "/arrstatus.py"
  ]

  Process {
    id: proc
    command: {
      var custom = String(root.setting("command", ""))
      if (custom !== "") return ["bash", "-lc", custom + " --json"]
      // First candidate that exists and is executable wins.
      return ["bash", "-c",
        "for candidate in \"$@\"; do [ -x \"$candidate\" ] && exec \"$candidate\" --json; done; exit 127",
        root.moduleName].concat(root.scriptCandidates)
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.update(text)
    }
    onExited: function (exitCode) {
      if (exitCode === 127) root.loadError = "arrstatus.py not found or not executable"
    }
  }

  Timer {
    interval: Math.max(1, Number(root.setting("interval", 5))) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNow()
  }

  // Only the relative labels need this, and only while they are on screen.
  Timer {
    interval: 10000
    running: root.opened
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refreshNow(); return "ok" }
  }

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    panelFlick.contentY = 0
    refreshNow()
    Qt.callLater(function () { keyCatcher.forceActiveFocus() })
  }

  // ---------------------------------------------------------------- bar

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // Idle with the panel open still needs a button to anchor the panel to.
    text: root.barText() !== "" ? root.barText() : "󰇚"
    active: root.alarming
    tooltipText: root.opened ? "" : root.heroMeta()
    fontSize: Number(root.setting("fontSize", Style.font.body))
    horizontalMargin: Number(root.setting("horizontalMargin", 7.5))

    onPressed: function (buttonCode) {
      if (buttonCode === Qt.RightButton) root.openFirstService()
      else if (buttonCode === Qt.MiddleButton) root.refreshNow()
      else root.toggle()
    }
  }

  // ---------------------------------------------------------------- panel

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function (dx, dy) {
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onActivateRequested: root.refreshNow()
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }
      onTextKey: function (t) {
        if (t === "r" || t === "R") root.refreshNow()
        if (t === "o" || t === "O") root.openFirstService()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "Downloads"
            meta: root.heroMeta()
            detail: root.alarming ? "ERROR" : ""
            foreground: root.foreground
            fontFamily: root.fontFamily

            iconComponent: Component {
              Text {
                text: "󰇚"
                color: root.alarming ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
          }

          // The script could not run at all: everything below would be blank,
          // so say why instead.
          Column {
            visible: root.loadError !== ""
            width: parent.width
            spacing: Style.space(6)

            PanelSeparator { foreground: root.foreground }

            Text {
              width: parent.width
              text: root.loadError
              color: root.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
          }

          // A report with no sections means the config enables nothing.
          Column {
            visible: root.loadError === "" && !!root.report && root.services.length === 0
            width: parent.width
            spacing: Style.space(6)

            PanelSeparator { foreground: root.foreground }

            Text {
              width: parent.width
              text: "No services enabled in ~/.config/arrstatus/arrstatus.conf"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          Repeater {
            model: root.services

            Column {
              id: section
              required property var modelData

              readonly property var service: modelData
              readonly property var items: modelData.items || []
              readonly property bool failed: !!modelData.error

              width: column.width
              spacing: Style.space(8)

              PanelSeparator { foreground: root.foreground }

              // Header row: service name on the left, its own headline on the
              // right — speed for the download clients, item count for the
              // *arrs, the error when there is one.
              Item {
                width: parent.width
                implicitHeight: Math.max(sectionName.implicitHeight, sectionMeta.implicitHeight)

                PanelSectionHeader {
                  id: sectionName
                  text: String(section.service.name).toUpperCase()
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  id: sectionMeta
                  text: root.serviceMeta(section.service)
                  color: section.failed ? root.urgent : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  anchors.left: sectionName.right
                  anchors.leftMargin: Style.spacing.sm
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  horizontalAlignment: Text.AlignRight
                }

                MouseArea {
                  anchors.fill: parent
                  enabled: !!section.service.url
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.openService(section.service)
                }
              }

              Text {
                visible: !section.failed && section.items.length === 0
                width: parent.width
                text: "No active items"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              Repeater {
                model: section.items

                ItemRow {
                  required property var modelData
                  width: section.width
                  item: modelData
                  service: section.service
                }
              }
            }
          }

          Text {
            visible: text !== ""
            width: parent.width
            topPadding: Style.space(2)
            text: root.agoText()
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  // One queue item: title, percentage, meter, and whatever the service knows
  // about its state. Clicking opens the service that owns it.
  component ItemRow: Item {
    id: itemRow
    property var item: null
    property var service: null

    readonly property int percent: itemRow.item && itemRow.item.percent !== null
      && itemRow.item.percent !== undefined ? Number(itemRow.item.percent) : -1
    readonly property bool stalled: String(itemRow.item ? itemRow.item.status : "").toLowerCase().indexOf("stalled") >= 0

    implicitHeight: rowContent.implicitHeight

    // Declared before the content so the labels sit on top of it; Text items
    // do not take mouse events, so the whole row still clicks through to here.
    MouseArea {
      anchors.fill: parent
      enabled: !!(itemRow.service && itemRow.service.url)
      cursorShape: Qt.PointingHandCursor
      onClicked: root.openService(itemRow.service)
    }

    Column {
      id: rowContent
      width: parent.width
      spacing: Style.space(4)

      Item {
        width: parent.width
        implicitHeight: Math.max(itemTitle.implicitHeight, itemPercent.implicitHeight)

        Text {
          id: itemTitle
          text: itemRow.item ? String(itemRow.item.title) : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
          anchors.left: parent.left
          anchors.right: itemPercent.left
          anchors.rightMargin: Style.spacing.sm
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: itemPercent
          text: itemRow.percent >= 0 ? itemRow.percent + "%" : ""
          color: itemRow.stalled ? root.urgent : root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Meter {
        visible: itemRow.percent >= 0
        width: parent.width
        value: itemRow.percent / 100
        alarming: itemRow.stalled
      }

      Text {
        visible: text !== ""
        width: parent.width
        text: itemRow.item ? root.itemMeta(itemRow.item) : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }

  // Rounded track showing how far along an item is.
  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.12))

    implicitHeight: thickness

    Rectangle {
      id: meterTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: meterTrack.left
      anchors.verticalCenter: meterTrack.verticalCenter
      height: meterTrack.height
      radius: meterTrack.radius
      width: meterTrack.width * root.clamp(meter.value, 0, 1)
      color: meter.alarming ? root.urgent : root.foreground

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }
  }
}
