pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../primitives/buttons"
import "../primitives/text"

Column {
    id: panel

    property var windowManager: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property string layerName: "modal"
    property int targetWindowId: -1
    property bool open: false
    property bool contentReady: false

    property int lockedWindowId: -1
    property string viewMode: "main"
    property string statusMessage: ""

    readonly property var targetWindow: windowManager ? windowManager.windowById(lockedWindowId) : null
    readonly property bool interactive: open && contentReady

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    function errorText(code) {
        return tr("windows.errors." + code, tr("windows.errors.unknown", "Window action failed"))
    }

    function _switchView(nextView) {
        statusMessage = ""
        viewMode = nextView
        Qt.callLater(() => {
            if (navigationManager && panel.open && panel.contentReady) {
                layerManager.setActiveZone(null)
                navigationManager.ensureFocus(panel.layerName)
            }
        })
    }

    onOpenChanged: {
        if (open) {
            lockedWindowId = targetWindowId
            viewMode = "main"
            statusMessage = ""
        }
    }

    spacing: Theme.spacingM

    SectionTitle {
        width: panel.width
        styleTokens: panel.styleTokens
        title: panel.targetWindow
               ? panel.targetWindow.appName + " — " + panel.tr("windows.actions_title", "Window Actions")
               : panel.tr("windows.actions_title", "Window Actions")
        subtitle: panel.targetWindow
                  ? panel.targetWindow.title
                  : panel.tr("windows.closed_notice", "Window no longer exists")
    }

    StatusMessage {
        visible: panel.statusMessage !== ""
        width: panel.width
        text: panel.statusMessage
        styleTokens: panel.styleTokens
    }

    // Vista principal
    Column {
        width: panel.width
        spacing: Theme.spacingS
        visible: panel.open && panel.targetWindow !== null && panel.viewMode === "main"

        FocusZone {
            id: actMonitor
            zoneId: "win-act-monitor"
            layerName: panel.layerName
            layerManager: panel.layerManager
            navigationManager: panel.navigationManager
            visible: parent.visible
            enabled: panel.interactive && visible
            defaultFocus: true
            width: panel.width
            height: 48
            ringRadius: Theme.cornerRadius
            actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
            onActivated: panel._switchView("monitors")

            ActionButton {
                anchors.fill: parent
                focused: actMonitor.active
                enabled: actMonitor.enabled
                styleTokens: panel.styleTokens
                motionTokens: panel.motionTokens
                label: panel.tr("windows.action_move_monitor", "Move to monitor")
            }

            TapHandler {
                enabled: actMonitor.enabled
                onTapped: {
                    if (actMonitor.requestZoneFocus())
                        actMonitor.activate()
                }
            }
        }

        FocusZone {
            id: actWorkspace
            zoneId: "win-act-workspace"
            layerName: panel.layerName
            layerManager: panel.layerManager
            navigationManager: panel.navigationManager
            visible: parent.visible
            enabled: panel.interactive && visible
            width: panel.width
            height: 48
            ringRadius: Theme.cornerRadius
            actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
            onActivated: panel._switchView("workspaces")

            ActionButton {
                anchors.fill: parent
                focused: actWorkspace.active
                enabled: actWorkspace.enabled
                styleTokens: panel.styleTokens
                motionTokens: panel.motionTokens
                label: panel.tr("windows.action_move_workspace", "Move to workspace")
            }

            TapHandler {
                enabled: actWorkspace.enabled
                onTapped: {
                    if (actWorkspace.requestZoneFocus())
                        actWorkspace.activate()
                }
            }
        }

        FocusZone {
            id: actFullscreen
            zoneId: "win-act-fullscreen"
            layerName: panel.layerName
            layerManager: panel.layerManager
            navigationManager: panel.navigationManager
            visible: parent.visible
            enabled: panel.interactive && visible
            width: panel.width
            height: 48
            ringRadius: Theme.cornerRadius
            actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
            onActivated: {
                panel.windowManager?.toggleFullscreen(panel.lockedWindowId, (ok, err) => {
                    if (ok) panel.layerManager?.pop()
                    else panel.statusMessage = panel.errorText(String(err))
                })
            }

            ActionButton {
                anchors.fill: parent
                focused: actFullscreen.active
                enabled: actFullscreen.enabled
                styleTokens: panel.styleTokens
                motionTokens: panel.motionTokens
                label: panel.targetWindow?.isFullscreen
                       ? panel.tr("windows.action_exit_fullscreen", "Exit fullscreen")
                       : panel.tr("windows.action_enter_fullscreen", "Enter fullscreen")
            }

            TapHandler {
                enabled: actFullscreen.enabled
                onTapped: {
                    if (actFullscreen.requestZoneFocus())
                        actFullscreen.activate()
                }
            }
        }

        FocusZone {
            id: actClose
            zoneId: "win-act-close"
            layerName: panel.layerName
            layerManager: panel.layerManager
            navigationManager: panel.navigationManager
            visible: parent.visible
            enabled: panel.interactive && visible
            width: panel.width
            height: 48
            ringRadius: Theme.cornerRadius
            actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
            onActivated: {
                panel.windowManager?.closeWindow(panel.lockedWindowId, (ok, err) => {
                    if (ok) panel.layerManager?.pop()
                    else panel.statusMessage = panel.errorText(String(err))
                })
            }

            ActionButton {
                anchors.fill: parent
                focused: actClose.active
                enabled: actClose.enabled
                styleTokens: panel.styleTokens
                motionTokens: panel.motionTokens
                label: panel.tr("windows.action_close", "Close window")
            }

            TapHandler {
                enabled: actClose.enabled
                onTapped: {
                    if (actClose.requestZoneFocus())
                        actClose.activate()
                }
            }
        }
    }

    // Subvista: Mover a monitor
    Column {
        width: panel.width
        spacing: Theme.spacingS
        visible: panel.open && panel.targetWindow !== null && panel.viewMode === "monitors"

        Repeater {
            model: panel.windowManager ? panel.windowManager.outputs : []
            delegate: FocusZone {
                id: outZone
                required property int index
                required property var modelData
                readonly property bool isCurrent: panel.targetWindow?.output === modelData.name

                zoneId: "win-out-" + index
                layerName: panel.layerName
                layerManager: panel.layerManager
                navigationManager: panel.navigationManager
                visible: panel.open && panel.viewMode === "monitors"
                enabled: panel.interactive && visible
                defaultFocus: index === 0
                width: panel.width
                height: 44
                ringRadius: Theme.cornerRadius
                onActivated: {
                    panel.windowManager?.moveWindowToMonitor(panel.lockedWindowId, modelData.name, (ok, err) => {
                        if (ok) panel.layerManager?.pop()
                        else panel.statusMessage = panel.errorText(String(err))
                    })
                }

                ActionButton {
                    anchors.fill: parent
                    focused: outZone.active
                    enabled: outZone.enabled
                    styleTokens: panel.styleTokens
                    motionTokens: panel.motionTokens
                    label: outZone.modelData.name + (outZone.isCurrent ? " (" + panel.tr("windows.current", "current") + ")" : "")
                }

                TapHandler {
                    enabled: outZone.enabled
                    onTapped: {
                        if (outZone.requestZoneFocus())
                            outZone.activate()
                    }
                }
            }
        }
    }

    // Subvista: Mover a workspace
    Column {
        width: panel.width
        spacing: Theme.spacingS
        visible: panel.open && panel.targetWindow !== null && panel.viewMode === "workspaces"

        Repeater {
            model: panel.windowManager ? panel.windowManager.workspaces : []
            delegate: FocusZone {
                id: wsZone
                required property int index
                required property var modelData
                readonly property bool isCurrent: panel.targetWindow?.workspaceId === modelData.id

                zoneId: "win-ws-" + index
                layerName: panel.layerName
                layerManager: panel.layerManager
                navigationManager: panel.navigationManager
                visible: panel.open && panel.viewMode === "workspaces"
                enabled: panel.interactive && visible
                defaultFocus: index === 0
                width: panel.width
                height: 44
                ringRadius: Theme.cornerRadius
                onActivated: {
                    panel.windowManager?.moveWindowToWorkspace(panel.lockedWindowId, modelData.id, (ok, err) => {
                        if (ok) panel.layerManager?.pop()
                        else panel.statusMessage = panel.errorText(String(err))
                    })
                }

                ActionButton {
                    anchors.fill: parent
                    focused: wsZone.active
                    enabled: wsZone.enabled
                    styleTokens: panel.styleTokens
                    motionTokens: panel.motionTokens
                    label: panel.tr("windows.workspace_prefix", "Workspace") + " " + wsZone.modelData.idx
                           + (wsZone.modelData.name ? " · " + wsZone.modelData.name : "")
                           + (wsZone.modelData.output ? " [" + wsZone.modelData.output + "]" : "")
                           + (wsZone.isCurrent ? " (" + panel.tr("windows.current", "current") + ")" : "")
                }

                TapHandler {
                    enabled: wsZone.enabled
                    onTapped: {
                        if (wsZone.requestZoneFocus())
                            wsZone.activate()
                    }
                }
            }
        }
    }
}
