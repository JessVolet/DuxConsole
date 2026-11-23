import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common as DmsCommon
import qs.Services as DmsServices
import "../../components/chrome"
import "../../services"
import "../interaction"
import "../motion"

PanelWindow {
    id: overlay

    property bool active: false
    property var pluginService: null
    signal closeRequested()

    visible: active
    onActiveChanged: {
        if (active) {
            navigationManager.ensureFocus(layerManager.topLayer)
        } else {
            inputManager.resetState()
            layerManager.reset()
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dms:plugins:dux-console"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    ScreenRegistry { id: screenRegistry }
    LayerManager {
        id: layerManager
        navigationManager: navigationManager
    }
    NavigationManager {
        id: navigationManager
        layerManager: layerManager
        rootContainer: overlayContent
        screenHints: slideManager.activeScreen?.screenActionHints ?? []
    }
    I18n { id: i18n }
    StyleTokens { id: styleTokens }
    MotionTokens { id: motionTokens }

    IconsPadManager {
        id: iconsPadManager
        inputManager: inputManager
        styleTokens: styleTokens
    }

    DconsoleBridge {
        id: dconsoleBridge
        inputManager: inputManager
        overlayActive: overlay.active
    }

    WindowManager {
        id: windowManager
    }

    WindowIconProvider {
        id: windowIconProvider
    }

    MediaService {
        id: mediaService
    }
    AudioControlService {
        id: audioService
        backend: DmsServices.AudioService
        stateStore: overlay.pluginService
        live: overlay.active && slideManager.currentScreenMeta?.id === "test2"
    }

    InputManager {
        id: inputManager
        onTriggered: (action, payload) => {
            if (!overlay.active)
                return
            if (action === "I.Refuse") {
                if (!layerManager.pop())
                    overlay.closeRequested()
            } else if ((action === "I.ActionSlide.R" || action === "I.ActionSlide.L") && layerManager.topLayer === "dashboard") {
                if (action === "I.ActionSlide.R")
                    slideManager.next()
                else
                    slideManager.prev()
            } else if (layerManager.topLayer === "dashboard" && slideManager.activeScreen?.handleScreenAction?.(action, payload)) {
                return
            } else {
                navigationManager.handleAction(action, payload)
            }
        }
    }

    Item {
        id: overlayContent
        anchors.fill: parent
        focus: overlay.active

        Keys.onPressed: event => inputManager.processKeyEvent(event, true)
        Keys.onReleased: event => inputManager.processKeyEvent(event, false)

        Bg {
            styleTokens: styleTokens
        }

        // Chrome persistente del dashboard (no se destruye al cambiar de slide)
        TopBar {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: DmsCommon.Theme.spacingXL
            styleTokens: styleTokens
            motionTokens: motionTokens
            i18n: i18n
            iconsPadManager: iconsPadManager
            screens: screenRegistry.screens
            currentIndex: slideManager.currentIndex
            tabControlsEnabled: layerManager.topLayer === "dashboard"
            gamepadConnected: dconsoleBridge.connected && inputManager.activeDevice !== "keyboard"
            onSlideRequested: slideId => {
                if (layerManager.topLayer === "dashboard")
                    slideManager.select(slideId)
            }
        }

        SlideManager {
            id: slideManager
            anchors.top: topBar.bottom
            anchors.topMargin: DmsCommon.Theme.spacingM
            anchors.bottom: footerBar.top
            anchors.bottomMargin: DmsCommon.Theme.spacingM
            anchors.left: parent.left
            anchors.right: parent.right
            registry: screenRegistry
            inputManager: inputManager
            layerManager: layerManager
            navigationManager: navigationManager
            iconsPadManager: iconsPadManager
            i18n: i18n
            styleTokens: styleTokens
            motionTokens: motionTokens
            windowManager: windowManager
            windowIconProvider: windowIconProvider
            mediaService: mediaService
            audioService: audioService
            onCloseOverlayRequested: overlay.closeRequested()
        }

        FooterBar {
            id: footerBar
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: DmsCommon.Theme.spacingXL
            iconsPadManager: iconsPadManager
            styleTokens: styleTokens
            motionTokens: motionTokens
            i18n: i18n
            hints: navigationManager.activeHints
        }

        FocusRing {
            id: focusRing
            targetZone: layerManager.activeZone
            coordinateSpace: overlayContent
            motionTokens: motionTokens
            styleTokens: styleTokens
        }

        ErrorBanner {
            i18n: i18n
            sourcePath: slideManager.failedSource
            errorMessage: slideManager.loadError
        }
    }
}
