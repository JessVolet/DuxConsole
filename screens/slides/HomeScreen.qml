pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
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
    readonly property real heroScale: Math.max(0.48, Math.min(0.75, width / 1920, height / 870))
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

    Item {
        id: pageLayout
        anchors.fill: parent
        anchors.leftMargin: root.width * 0.024
        anchors.rightMargin: root.width * 0.024

        Column {
            id: heroColumn
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: root.compactLayout ? Theme.spacingM : parent.height * 0.08
            width: Math.min(parent.width * (root.compactLayout ? 0.96 : 0.62), 860)
            spacing: Theme.spacingM

            SessionHero {
                id: hero
                width: parent.width
                scaleFactor: root.heroScale
                spacing: Theme.spacingM
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

        Column {
            id: carouselColumn
            anchors.left: parent.left
            anchors.right: root.compactLayout ? parent.right : mediaCard.left
            anchors.rightMargin: root.compactLayout ? 0 : Theme.spacingL
            anchors.bottom: root.compactLayout ? mediaCard.top : parent.bottom
            anchors.bottomMargin: root.compactLayout ? Theme.spacingM : 0
            spacing: Theme.spacingS

            SectionTitle {
                id: carouselHeader
                width: parent.width
                title: root.tr("home.windows_section", "Open windows")
                badgeText: String(windowCarousel.count)
                role: "chrome"
                titleSize: Theme.fontSizeLarge
                styleTokens: root.styleTokens
            }

            WindowCarousel {
                id: windowCarousel
                width: parent.width
                height: Math.min(implicitHeight, root.compactLayout ? pageLayout.height * 0.34 : pageLayout.height * 0.42)
                iconOnly: true
                defaultFocus: true
                leftCount: 1
                rightCount: 3
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

        MediaPlayerCard {
            id: mediaCard
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: root.compactLayout ? parent.width : Math.min(340, parent.width * 0.28)
            height: root.compactLayout ? Math.min(120, pageLayout.height * 0.24) : Math.min(200, pageLayout.height * 0.34)
            compact: root.compactLayout
            styleTokens: root.styleTokens
            motionTokens: root.motionTokens
            i18n: root.i18n
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
