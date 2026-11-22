pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../../components/chrome"
import "../../components/primitives/buttons"
import "../../components/primitives/text"

Rectangle {
    id: modal

    property var windowManager: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var i18n: null
    property string layerName: "modal"
    property int targetWindowId: -1

    // "main" | "monitors" | "workspaces"
    property string viewMode: "main"
    property string statusMessage: ""

    readonly property bool open: layerManager?.topLayer === layerName
    readonly property var targetWindow: windowManager ? windowManager.windowById(targetWindowId) : null

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
            if (navigationManager && modal.open) {
                layerManager.setActiveZone(null)
                navigationManager.ensureFocus(modal.layerName)
            }
        })
    }

    onOpenChanged: {
        if (open) {
            viewMode = "main"
            statusMessage = ""
        }
    }

    anchors.fill: parent
    visible: open
    color: "transparent"

    ModalPanel {
        id: dialogSurface
        anchors.centerIn: parent
        width: Math.max(0, Math.min(440, parent.width - Theme.spacingXL * 2))
        height: col.implicitHeight + Theme.spacingXL * 2
        styleTokens: modal.styleTokens

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingM
            width: dialogSurface.width - Theme.spacingXL * 2

            SectionTitle {
                styleTokens: modal.styleTokens
                title: modal.targetWindow
                       ? modal.targetWindow.appName + " — " + modal.tr("windows.actions_title", "Window Actions")
                       : modal.tr("windows.actions_title", "Window Actions")
                subtitle: modal.targetWindow
                          ? modal.targetWindow.title
                          : modal.tr("windows.closed_notice", "Window no longer exists")
            }

            StatusMessage {
                visible: modal.statusMessage !== ""
                width: col.width
                text: modal.statusMessage
                styleTokens: modal.styleTokens
            }

            // Vista principal
            Column {
                width: col.width
                spacing: Theme.spacingS
                visible: modal.open && modal.targetWindow !== null && modal.viewMode === "main"

                FocusZone {
                    id: actMonitor
                    zoneId: "win-act-monitor"
                    layerName: modal.layerName
                    layerManager: modal.layerManager
                    navigationManager: modal.navigationManager
                    visible: parent.visible
                    defaultFocus: true
                    width: Math.max(0, dialogSurface.width - Theme.spacingXL * 2)
                    height: 48
                    ringRadius: Theme.cornerRadius
                    actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
                    onActivated: modal._switchView("monitors")

                    ActionButton {
                        anchors.fill: parent
                        focused: actMonitor.active
                        styleTokens: modal.styleTokens
                        motionTokens: modal.motionTokens
                        label: modal.tr("windows.action_move_monitor", "Move to monitor")
                    }
                }

                FocusZone {
                    id: actWorkspace
                    zoneId: "win-act-workspace"
                    layerName: modal.layerName
                    layerManager: modal.layerManager
                    navigationManager: modal.navigationManager
                    visible: parent.visible
                    width: Math.max(0, dialogSurface.width - Theme.spacingXL * 2)
                    height: 48
                    ringRadius: Theme.cornerRadius
                    actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
                    onActivated: modal._switchView("workspaces")

                    ActionButton {
                        anchors.fill: parent
                        focused: actWorkspace.active
                        styleTokens: modal.styleTokens
                        motionTokens: modal.motionTokens
                        label: modal.tr("windows.action_move_workspace", "Move to workspace")
                    }
                }

                FocusZone {
                    id: actFullscreen
                    zoneId: "win-act-fullscreen"
                    layerName: modal.layerName
                    layerManager: modal.layerManager
                    navigationManager: modal.navigationManager
                    visible: parent.visible
                    width: col.width
                    height: 48
                    ringRadius: Theme.cornerRadius
                    actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
                    onActivated: {
                        modal.windowManager?.toggleFullscreen(modal.targetWindowId, (ok, err) => {
                            if (ok) modal.layerManager?.pop()
                            else modal.statusMessage = modal.errorText(String(err))
                        })
                    }

                    ActionButton {
                        anchors.fill: parent
                        focused: actFullscreen.active
                        styleTokens: modal.styleTokens
                        motionTokens: modal.motionTokens
                        label: modal.targetWindow?.isFullscreen
                               ? modal.tr("windows.action_exit_fullscreen", "Exit fullscreen")
                               : modal.tr("windows.action_enter_fullscreen", "Enter fullscreen")
                    }
                }

                FocusZone {
                    id: actClose
                    zoneId: "win-act-close"
                    layerName: modal.layerName
                    layerManager: modal.layerManager
                    navigationManager: modal.navigationManager
                    visible: parent.visible
                    width: col.width
                    height: 48
                    ringRadius: Theme.cornerRadius
                    actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
                    onActivated: {
                        modal.windowManager?.closeWindow(modal.targetWindowId, (ok, err) => {
                            if (ok) modal.layerManager?.pop()
                            else modal.statusMessage = modal.errorText(String(err))
                        })
                    }

                    ActionButton {
                        anchors.fill: parent
                        focused: actClose.active
                        styleTokens: modal.styleTokens
                        motionTokens: modal.motionTokens
                        label: modal.tr("windows.action_close", "Close window")
                    }
                }


            }

            // Subvista: Mover a monitor
            Column {
                width: col.width
                spacing: Theme.spacingS
                visible: modal.open && modal.targetWindow !== null && modal.viewMode === "monitors"

                Repeater {
                    model: modal.windowManager ? modal.windowManager.outputs : []
                    delegate: FocusZone {
                        id: outZone
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: modal.targetWindow?.output === modelData.name

                        zoneId: "win-out-" + index
                        layerName: modal.layerName
                        layerManager: modal.layerManager
                        navigationManager: modal.navigationManager
                        visible: modal.open && modal.viewMode === "monitors"
                        defaultFocus: index === 0
                        width: col.width
                        height: 44
                        ringRadius: Theme.cornerRadius
                        onActivated: {
                            modal.windowManager?.moveWindowToMonitor(modal.targetWindowId, modelData.name, (ok, err) => {
                                if (ok) modal.layerManager?.pop()
                                else modal.statusMessage = modal.errorText(String(err))
                            })
                        }

                        ActionButton {
                            anchors.fill: parent
                            focused: outZone.active
                            styleTokens: modal.styleTokens
                            motionTokens: modal.motionTokens
                            label: modelData.name + (outZone.isCurrent ? " (" + modal.tr("windows.current", "current") + ")" : "")
                        }
                    }
                }
            }

            // Subvista: Mover a workspace
            Column {
                width: col.width
                spacing: Theme.spacingS
                visible: modal.open && modal.targetWindow !== null && modal.viewMode === "workspaces"

                Repeater {
                    model: modal.windowManager ? modal.windowManager.workspaces : []
                    delegate: FocusZone {
                        id: wsZone
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: modal.targetWindow?.workspaceId === modelData.id

                        zoneId: "win-ws-" + index
                        layerName: modal.layerName
                        layerManager: modal.layerManager
                        navigationManager: modal.navigationManager
                        visible: modal.open && modal.viewMode === "workspaces"
                        defaultFocus: index === 0
                        width: col.width
                        height: 44
                        ringRadius: Theme.cornerRadius
                        onActivated: {
                            modal.windowManager?.moveWindowToWorkspace(modal.targetWindowId, modelData.id, (ok, err) => {
                                if (ok) modal.layerManager?.pop()
                                else modal.statusMessage = modal.errorText(String(err))
                            })
                        }

                        ActionButton {
                            anchors.fill: parent
                            focused: wsZone.active
                            styleTokens: modal.styleTokens
                            motionTokens: modal.motionTokens
                            label: modal.tr("windows.workspace_prefix", "Workspace") + " " + modelData.idx
                                   + (modelData.name ? " · " + modelData.name : "")
                                   + (modelData.output ? " [" + modelData.output + "]" : "")
                                   + (wsZone.isCurrent ? " (" + modal.tr("windows.current", "current") + ")" : "")
                        }
                    }
                }
            }


        }
    }
}
