pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
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

    screenActionHints: windowCarousel.hasWindows ? [
        { action: "I.Accept", labelKey: "windows.hint_focus", fallback: "Focus window" },
        { action: "I.Options", labelKey: "windows.hint_options", fallback: "Window options" },
        { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
        { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
    ] : []

    function handleScreenAction(action, payload) {
        if (action === "I.ActionOption.L")
            return windowCarousel.cycle(-1)
        if (action === "I.ActionOption.R")
            return windowCarousel.cycle(1)
        if (action === "I.Accept" && root.selectedWindow) {
            root.focusAndClose(root.selectedWindow.id)
            return true
        }
        if (action === "I.Options" && root.selectedWindow) {
            root.openWindowOptions(root.selectedWindow.id)
            return true
        }
        return false
    }

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

                ActionPill {
                    id: continueButton
                    text: root.tr("home.continue", "Continue")
                    glyphAction: "I.Accept"
                    iconsPadManager: root.iconsPadManager
                    styleTokens: root.styleTokens
                    primary: true
                    enabled: Boolean(root.selectedWindow)
                    onClicked: {
                        if (root.selectedWindow)
                            root.focusAndClose(root.selectedWindow.id)
                    }
                }

                ActionPill {
                    id: optionsButton
                    text: root.tr("windows.hint_options", "Window options")
                    glyphAction: "I.Options"
                    iconsPadManager: root.iconsPadManager
                    styleTokens: root.styleTokens
                    enabled: Boolean(root.selectedWindow)
                    onClicked: {
                        if (root.selectedWindow)
                            root.openWindowOptions(root.selectedWindow.id)
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
                role: "card"
                titleSize: Theme.fontSizeLarge
                styleTokens: root.styleTokens
            }

            WindowCarousel {
                id: windowCarousel
                width: parent.width
                height: Math.min(implicitHeight, root.compactLayout ? pageLayout.height * 0.34 : pageLayout.height * 0.42)
                iconOnly: true
                focusable: false
                leftCount: 1
                rightCount: 3
                alignLeft: true
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
            width: root.compactLayout ? parent.width : Math.min(360, parent.width * 0.30)
            height: root.compactLayout ? 84 : 104
            compact: root.compactLayout
            defaultFocus: true
            mediaService: root.mediaService
            layerManager: root.layerManager
            navigationManager: root.navigationManager
            styleTokens: root.styleTokens
            motionTokens: root.motionTokens
            i18n: root.i18n
            onExpandRequested: root.layerManager?.push("media-player")
        }
    }

    MediaPlayerModal {
        mediaService: root.mediaService
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        iconsPadManager: root.iconsPadManager
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        i18n: root.i18n
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
