pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../../core/interaction"
import "../primitives/surfaces"

Item {
    id: wc

    property var windowManager: null
    property var windowIconProvider: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property bool iconOnly: false
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

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    signal activateWindowRequested(int windowId)
    signal windowOptionsRequested(int windowId)

    implicitHeight: iconOnly ? carousel.implicitHeight : Math.max(200, carousel.implicitHeight)

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
            const focusedIndex = windows.findIndex(w => w.isFocused)
            const clamped = selectedWindowId < 0 && focusedIndex >= 0
                ? focusedIndex
                : Math.max(0, Math.min(windows.length - 1, zone.currentSubIndex))
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
            maxVisibleItems: width < 720 ? 3 : (width < 980 ? 4 : 6)
            cardWidth: Math.min(200, width / maxVisibleItems)
            cardHeight: cardWidth * 0.68
            selectedWidth: Math.min(380, width * 0.48)
            selectedHeight: Math.min(184, selectedWidth * 0.48)
            spacing: Math.min(20, width * 0.018)
            model: wc.windows
            delegate: SlantedSurface {
                id: winCard
                property int index: 0
                property var itemData: null

                readonly property var win: itemData && typeof itemData === "object" ? itemData : null
                readonly property var iconInfo: wc.windowIconProvider && win
                    ? wc.windowIconProvider.resolve(win)
                    : ({ source: "", fallbackLabel: "" })

                role: "card"
                styleTokens: wc.styleTokens
                motionTokens: wc.motionTokens

                SlantedImage {
                    visible: wc.iconOnly
                    anchors.centerIn: parent
                    width: Math.min(
                        winCard.width * 0.72,
                        (winCard.selected ? 112 : 56) * carousel.layoutScale
                    )
                    height: width
                    styleTokens: wc.styleTokens
                    motionTokens: wc.motionTokens
                    source: winCard.iconInfo.source
                    fillMode: Image.PreserveAspectFit
                    showGradientOverlay: false
                    fallbackText: winCard.win?.appName
                                  ? winCard.win.appName.slice(0, 2).toUpperCase()
                                  : ""
                    focused: winCard.focused && winCard.selected
                }

                Column {
                    visible: !wc.iconOnly
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM * carousel.layoutScale
                    spacing: Theme.spacingS * carousel.layoutScale

                    // Área superior: miniatura / icono real de aplicación / fallback
                    Row {
                        width: parent.width
                        spacing: Theme.spacingM * carousel.layoutScale

                        SlantedImage {
                            width: Math.max(12, (winCard.selected ? 52 : 38) * carousel.layoutScale)
                            height: width
                            styleTokens: wc.styleTokens
                            motionTokens: wc.motionTokens
                            source: winCard.iconInfo.source
                            fillMode: Image.PreserveAspectFit
                            showGradientOverlay: false
                            fallbackText: winCard.iconInfo.fallbackLabel || wc.tr("windows.unknown_app", "Application")
                            focused: winCard.focused && winCard.selected
                        }

                        Column {
                            width: Math.max(0, parent.width - ((winCard.selected ? 52 : 38) * carousel.layoutScale) - Theme.spacingM * carousel.layoutScale)
                            spacing: 2
                            visible: winCard.selected

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS

                                StyledText {
                                    width: Math.max(0, parent.width - (winCard.win?.isFullscreen ? Theme.fontSizeSmall + Theme.spacingS : 0))
                                    text: winCard.win && winCard.win.appName
                                          ? winCard.win.appName
                                          : wc.tr("windows.unknown_app", "Application")
                                    font.pixelSize: winCard.selected ? Theme.fontSizeLarge : Theme.fontSizeMedium
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
                                visible: winCard.selected
                                text: winCard.win
                                      ? (wc.tr("windows.workspace_prefix", "Workspace") + " " + winCard.win.workspaceIndex
                                         + (winCard.win.workspaceName ? " (" + winCard.win.workspaceName + ")" : "")
                                         + (winCard.win.output ? " · " + winCard.win.output : ""))
                                      : ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: wc.styleTokens ? wc.styleTokens.accentColor : Theme.primary
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Título de ventana (más líneas visibles cuando está seleccionada)
                    StyledText {
                        width: parent.width
                        visible: winCard.selected
                        text: winCard.win ? winCard.win.title : ""
                        font.pixelSize: Math.max(Theme.fontSizeSmall * 0.75, Theme.fontSizeSmall * carousel.layoutScale)
                        color: wc.styleTokens
                               ? wc.styleTokens.onSurfaceColor("card")
                               : (Theme.surfaceVariantText ?? "#9CA3AF")
                        elide: Text.ElideRight
                        maximumLineCount: winCard.selected ? 2 : 1
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
