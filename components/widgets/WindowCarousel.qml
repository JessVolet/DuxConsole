pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../../core/interaction"
import "../primitives/surfaces"

Item {
    id: wc

    property var windowManager: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property bool defaultFocus: false
    property string layerName: "dashboard"
    property string zoneId: "zone-windows"

    readonly property var windows: windowManager ? windowManager.windows : []
    readonly property bool hasWindows: windows.length > 0
    property int selectedWindowId: -1

    readonly property var selectedWindow: {
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].id === selectedWindowId)
                return windows[i]
        }
        return windows.length > 0 ? windows[0] : null
    }

    signal activateWindowRequested(int windowId)
    signal windowOptionsRequested(int windowId)

    implicitHeight: Math.max(172, carousel.implicitHeight)

    function _syncSelectionFromList() {
        if (windows.length === 0) {
            selectedWindowId = -1
            zone.currentSubIndex = 0
            return
        }
        const idx = windows.findIndex(w => w.id === selectedWindowId)
        if (idx >= 0) {
            if (zone.currentSubIndex !== idx)
                zone.currentSubIndex = idx
        } else {
            const clamped = Math.max(0, Math.min(windows.length - 1, zone.currentSubIndex))
            selectedWindowId = windows[clamped].id
            zone.currentSubIndex = clamped
        }
    }

    onWindowsChanged: _syncSelectionFromList()
    Component.onCompleted: _syncSelectionFromList()

    FocusZone {
        id: zone
        anchors.fill: parent
        zoneId: wc.zoneId
        layerName: wc.layerName
        layerManager: wc.layerManager
        navigationManager: wc.navigationManager
        defaultFocus: wc.defaultFocus
        subItemCount: wc.windows.length
        ringRadius: Theme.cornerRadius
        actionHints: wc.hasWindows ? [
            { action: "I.Accept", labelKey: "windows.hint_focus", fallback: "Focus window" },
            { action: "I.Options", labelKey: "windows.hint_options", fallback: "Window options" },
            { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
        ] : []

        onCurrentSubIndexChanged: {
            if (wc.windows.length > 0 && currentSubIndex >= 0 && currentSubIndex < wc.windows.length)
                wc.selectedWindowId = wc.windows[currentSubIndex].id
        }

        onActivated: {
            if (wc.selectedWindow)
                wc.activateWindowRequested(wc.selectedWindow.id)
        }

        onOptionsTriggered: {
            if (wc.selectedWindow)
                wc.windowOptionsRequested(wc.selectedWindow.id)
        }

        // Estado vacío o Niri no disponible
        SlantedSurface {
            anchors.fill: parent
            visible: !wc.hasWindows
            role: "card"
            styleTokens: wc.styleTokens
            motionTokens: wc.motionTokens
            focused: zone.active

            StyledText {
                anchors.centerIn: parent
                text: {
                    if (!wc.windowManager || !wc.windowManager.available)
                        return wc.i18n ? wc.i18n.t("windows.unavailable", "Niri IPC unavailable") : "Niri IPC unavailable"
                    return wc.i18n ? wc.i18n.t("windows.empty", "No open windows") : "No open windows"
                }
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: wc.styleTokens ? wc.styleTokens.onSurfaceColor("card") : (Theme.surfaceText ?? "#F2F4F8")
            }
        }

        CarouselView {
            id: carousel
            anchors.fill: parent
            visible: wc.hasWindows
            currentIndex: zone.currentSubIndex
            motionTokens: wc.motionTokens
            focused: zone.active
            model: wc.windows
            delegate: SlantedSurface {
                id: winCard
                property int index: 0
                property var itemData: null

                readonly property var win: itemData && typeof itemData === "object" ? itemData : null

                role: "card"
                styleTokens: wc.styleTokens
                motionTokens: wc.motionTokens

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    spacing: 4

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: winCard.win ? winCard.win.appName : ""
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: wc.styleTokens ? wc.styleTokens.onSurfaceColor("card") : (Theme.surfaceText ?? "#F2F4F8")
                            elide: Text.ElideRight
                        }

                        StyledText {
                            visible: Boolean(winCard.win?.isFullscreen)
                            text: "⛶"
                            font.pixelSize: Theme.fontSizeSmall
                            color: wc.styleTokens ? wc.styleTokens.accentColor : Theme.primary
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: winCard.win ? winCard.win.title : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: wc.styleTokens
                               ? Qt.alpha(wc.styleTokens.onSurfaceColor("card"), 0.78)
                               : (Theme.surfaceVariantText ?? "#9CA3AF")
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }

                    StyledText {
                        width: parent.width
                        text: winCard.win
                              ? ("WS " + winCard.win.workspaceIndex
                                 + (winCard.win.workspaceName ? " (" + winCard.win.workspaceName + ")" : "")
                                 + (winCard.win.output ? " · " + winCard.win.output : ""))
                              : ""
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: wc.styleTokens ? wc.styleTokens.accentColor : Theme.primary
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
