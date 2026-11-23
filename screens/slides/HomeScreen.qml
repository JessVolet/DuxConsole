pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/buttons"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root
    screenId: "home"
    title: root.tr("nav.home", "Home")

    property int modalTargetWindowId: -1
    property string ipcErrorNotice: ""
    readonly property bool compactLayout: width < 900 || height < 520
    readonly property real scaleFactor: Math.max(0.65, Math.min(1.4, width / 1920, height / 870))
    readonly property var selectedWindow: windowCarousel.selectedWindow

    function errorText(code) {
        return root.tr("windows.errors." + code, root.tr("windows.errors.unknown", "The window action could not be completed."))
    }

    function selectedWindowDescription(win) {
        if (!win)
            return root.tr("windows.empty", "No open windows")

        const details = []
        if (win.appId && win.title && win.appId !== win.title)
            details.push(win.appId)
        if (win.workspaceIndex >= 0)
            details.push(root.tr("windows.workspace_prefix", "Workspace") + " " + win.workspaceIndex)
        if (win.output)
            details.push(root.tr("windows.output_prefix", "Display") + " " + win.output)
        return details.length > 0 ? details.join(" · ") : root.tr("home.no_active_app", "No active application")
    }

    function focusAndClose(winId) {
        if (winId < 0 || !root.windowManager)
            return
        root.ipcErrorNotice = ""
        root.windowManager.focusWindow(winId, (ok, err) => {
            if (ok)
                root.closeOverlayRequested()
            else
                root.ipcErrorNotice = root.errorText(String(err))
        })
    }

    function openWindowOptions(winId) {
        if (winId < 0)
            return
        root.ipcErrorNotice = ""
        root.modalTargetWindowId = winId
        root.layerManager?.push("modal")
    }

    Column {
        id: pageLayout
        anchors.fill: parent
        anchors.leftMargin: root.width * 0.024
        anchors.rightMargin: root.width * 0.024
        spacing: Theme.spacingL

        Item {
            id: selectedWindowArea
            width: pageLayout.width
            height: pageLayout.height * (root.compactLayout ? 0.54 : 0.48)

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width * (root.compactLayout ? 0.96 : 0.64), 920)
                spacing: Theme.spacingM

                SessionHero {
                    id: hero
                    width: parent.width
                    scaleFactor: root.scaleFactor
                    styleTokens: root.styleTokens
                    fallbackTitle: root.tr("home.no_active_app", "No active application")
                    session: root.selectedWindow
                        ? ({
                            title: root.selectedWindow.title || root.selectedWindow.appId || root.tr("windows.unknown_app", "Application"),
                            metadata: [root.selectedWindowDescription(root.selectedWindow)]
                        })
                        : ({
                            title: root.tr("home.no_active_app", "No active application"),
                            metadata: [root.tr("windows.empty", "No open windows")]
                        })

                    FocusZone {
                        id: continueZone
                        zoneId: "home-continue"
                        layerManager: root.layerManager
                        navigationManager: root.navigationManager
                        navRight: optionsZone
                        navDown: windowCarousel.focusZone
                        showFocusRing: false
                        width: continueButton.implicitWidth
                        height: continueButton.implicitHeight
                        enabled: Boolean(root.selectedWindow)
                        actionHints: [{ action: "I.Accept", labelKey: "home.continue", fallback: "Continue" }]

                        onActivated: {
                            if (root.selectedWindow)
                                root.focusAndClose(root.selectedWindow.id)
                        }

                        ActionPill {
                            id: continueButton
                            anchors.fill: parent
                            text: root.tr("home.continue", "Continue")
                            glyphAction: "I.Accept"
                            iconsPadManager: root.iconsPadManager
                            styleTokens: root.styleTokens
                            primary: true
                            highlighted: continueZone.active
                            enabled: continueZone.enabled && !continueZone.inert
                            onClicked: {
                                if (continueZone.requestZoneFocus())
                                    continueZone.activate()
                            }
                        }
                    }

                    FocusZone {
                        id: optionsZone
                        zoneId: "home-options"
                        layerManager: root.layerManager
                        navigationManager: root.navigationManager
                        navLeft: continueZone
                        navDown: windowCarousel.focusZone
                        showFocusRing: false
                        width: optionsButton.implicitWidth
                        height: optionsButton.implicitHeight
                        enabled: Boolean(root.selectedWindow)
                        actionHints: [{ action: "I.Accept", labelKey: "windows.hint_options", fallback: "Window options" }]

                        onActivated: {
                            if (root.selectedWindow)
                                root.openWindowOptions(root.selectedWindow.id)
                        }

                        ActionPill {
                            id: optionsButton
                            anchors.fill: parent
                            text: root.tr("windows.hint_options", "Window options")
                            glyphAction: "I.Select"
                            iconsPadManager: root.iconsPadManager
                            styleTokens: root.styleTokens
                            highlighted: optionsZone.active
                            enabled: optionsZone.enabled && !optionsZone.inert
                            onClicked: {
                                if (optionsZone.requestZoneFocus())
                                    optionsZone.activate()
                            }
                        }
                    }
                }

                StatusMessage {
                    visible: root.ipcErrorNotice !== ""
                    width: parent.width
                    text: root.ipcErrorNotice
                    styleTokens: root.styleTokens
                }
            }
        }

        Flow {
            id: bottomRegion
            width: pageLayout.width
            height: Math.max(0, pageLayout.height - selectedWindowArea.height - pageLayout.spacing)
            spacing: Theme.spacingM
            property bool stacked: root.compactLayout

            Column {
                id: carouselSlot
                width: bottomRegion.stacked
                       ? bottomRegion.width
                       : Math.max(0, bottomRegion.width - mediaSlot.width - bottomRegion.spacing)
                height: bottomRegion.stacked
                        ? Math.min(windowCarousel.implicitHeight + carouselHeader.implicitHeight + Theme.spacingS, bottomRegion.height * 0.58)
                        : bottomRegion.height
                spacing: Theme.spacingS

                Row {
                    id: carouselHeader
                    width: parent.width
                    spacing: Theme.spacingM

                    SectionTitle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: implicitWidth
                        title: root.tr("home.windows_section", "Open windows")
                        role: "chrome"
                        titleSize: Theme.fontSizeLarge
                        styleTokens: root.styleTokens
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(windowCarousel.count)
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: root.styleTokens
                            ? Qt.alpha(root.styleTokens.onSurfaceColor("chrome"), 0.7)
                            : Theme.surfaceVariantText
                    }
                }

                WindowCarousel {
                    id: windowCarousel
                    width: parent.width
                    height: Math.max(0, Math.min(implicitHeight, parent.height - carouselHeader.implicitHeight - parent.spacing))
                    iconOnly: true
                    defaultFocus: true
                    navUp: continueZone
                    windowManager: root.windowManager
                    windowIconProvider: root.windowIconProvider
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    i18n: root.i18n

                    onActivateWindowRequested: winId => root.focusAndClose(winId)
                    onWindowOptionsRequested: winId => root.openWindowOptions(winId)
                }
            }

            Item {
                id: mediaSlot
                width: bottomRegion.stacked
                       ? bottomRegion.width
                       : Math.min(340, bottomRegion.width * 0.30)
                height: bottomRegion.stacked
                        ? Math.max(0, bottomRegion.height - carouselSlot.height - bottomRegion.spacing)
                        : bottomRegion.height

                MediaPlayerCard {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: bottomRegion.stacked ? parent.height : Math.min(240, parent.height)
                    compact: bottomRegion.stacked
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    i18n: root.i18n
                }
            }
        }
    }

    WindowActionsModal {
        windowManager: root.windowManager
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        iconsPadManager: root.iconsPadManager
        i18n: root.i18n
        targetWindowId: root.modalTargetWindowId
    }
}
