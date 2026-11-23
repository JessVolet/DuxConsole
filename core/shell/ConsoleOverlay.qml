pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common as DmsCommon
import "../../components/chrome"
import "../../services"
import "../interaction"
import "../motion"

PanelWindow {
    id: overlay

    property bool active: false
    property bool fixtureMode: false
    property bool fixtureControllerAvailable: false
    property bool fixtureWheelOpen: false
    property string fixtureScene: "home"
    property string wheelSide: "left"
    property string noticeKey: ""
    property size previewSize: Qt.size(0, 0)
    readonly property var mockSession: fixtureSession.item
    readonly property real dashboardOpacity: fixtureWheelOpen ? 0.52 : 1.0
    readonly property var bridge: bridgeLoader.item
    readonly property var wheelMenu: wheelLoader.item
    signal closeRequested()

    function showFixture(scene) {
        if (!fixtureMode)
            return
        layerManager.reset()
        wheelMenu?.resetScene()
        fixtureWheelOpen = false
        noticeKey = ""
        fixtureScene = scene
        mockSession?.resetSelection()
        const spec = mockSession?.sceneSpec ?? ({})
        slideManager.select(spec.slide ?? scene.split("-")[0])
        slideManager.reloadCurrent()
        if (scene === "home-options") {
            noticeKey = "mockup.capture.savedVideo"
            noticeTimer.restart()
        }
        if (spec.wheel) {
            openWheel(spec.wheel)
            wheelMenu?.applyScene()
        }
        if (spec.backdropOnly)
            closeRequested()
    }

    function openWheel(side) {
        if (!fixtureMode || !["dashboard", "wheel"].includes(layerManager.topLayer))
            return
        wheelSide = side
        fixtureWheelOpen = true
        layerManager.push("wheel")
    }

    function handleFixtureButton(code, pressed) {
        if (!fixtureMode || !inputManager.config.gamepad?.[code])
            return
        if (pressed)
            inputManager.handleRawPress("gamepad", code, "xbox")
        else
            inputManager.handleRawRelease("gamepad", code)
    }

    function dispatchAction(action, payload) {
        if (fixtureMode && (action === "I.SystemWheel" || action === "I.QuickWheel")) {
            openWheel(action === "I.QuickWheel" ? "right" : "left")
        } else if (action === "I.Refuse") {
            if (!layerManager.pop())
                closeRequested()
        } else if (action === "I.ActionSlide.R" || action === "I.ActionSlide.L") {
            if (layerManager.topLayer === "dashboard" && active) {
                if (action === "I.ActionSlide.R")
                    slideManager.next()
                else
                    slideManager.prev()
            } else if (fixtureWheelOpen && layerManager.topLayer === "wheel") {
                wheelSide = action === "I.ActionSlide.R" ? "right" : "left"
            }
        } else {
            navigationManager.handleAction(action, payload)
        }
    }

    function previewState() {
        return JSON.stringify({
            visible: overlay.visible,
            controller: fixtureControllerAvailable,
            dashboard: overlay.active,
            layer: layerManager.topLayer,
            zone: layerManager.activeZone?.zoneId ?? "",
            item: layerManager.activeZone?.currentSubIndex ?? -1,
            selection: mockSession?.selectedWindowId ?? -1,
            slideSelection: slideManager.fixtureSelection,
            slide: slideManager.currentScreenMeta?.id ?? "",
            loadError: slideManager.loadError,
            wheelReady: wheelLoader.status === Loader.Ready
        })
    }

    function saveFrame(path) {
        if (!overlay.visible || !overlayContent.width || !overlayContent.height)
            return false
        return overlayContent.grabToImage(result => {
            if (!result.saveToFile(path))
                console.warn("DuxConsole fixture frame could not be saved")
        })
    }

    visible: active || fixtureWheelOpen
    onActiveChanged: {
        if (active) {
            navigationManager.ensureFocus(layerManager.topLayer)
        } else if (!fixtureWheelOpen) {
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
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    color: "transparent"

    ScreenRegistry { id: screenRegistry; fixtureMode: overlay.fixtureMode }
    LayerManager {
        id: layerManager
        navigationManager: navigationManager
        onLayerPopped: layer => {
            if (layer === "wheel") {
                overlay.fixtureWheelOpen = false
                if (!overlay.active)
                    inputManager.resetState()
            }
        }
    }
    NavigationManager {
        id: navigationManager
        layerManager: layerManager
        rootContainer: overlayContent
    }
    I18n { id: i18n }
    StyleTokens { id: styleTokens; fixturePalette: overlay.mockSession?.appearance ?? ({}) }
    MotionTokens {
        id: motionTokens
        suppressAnimations: overlay.mockSession?.wheelChoices?.["reduced-motion"] === "on"
    }

    IconsPadManager {
        id: iconsPadManager
        inputManager: inputManager
        styleTokens: styleTokens
    }

    Loader {
        id: bridgeLoader
        active: !overlay.fixtureMode
        sourceComponent: DconsoleBridge {
            inputManager: inputManager
            overlayActive: overlay.active
        }
    }

    Loader {
        id: windowLoader
        active: !overlay.fixtureMode
        sourceComponent: WindowManager {}
    }

    Loader {
        id: iconLoader
        active: !overlay.fixtureMode
        sourceComponent: WindowIconProvider {}
    }

    Loader {
        id: fixtureSession
        active: overlay.fixtureMode
        sourceComponent: MockSession { scene: overlay.fixtureScene }
    }

    InputManager {
        id: inputManager
        onTriggered: (action, payload) => overlay.dispatchAction(action, payload)
    }

    Connections {
        target: overlay.mockSession
        function onNotice(messageKey) {
            overlay.noticeKey = messageKey
            noticeTimer.restart()
        }
    }

    Timer {
        id: noticeTimer
        interval: motionTokens.noticeMs
        onTriggered: overlay.noticeKey = ""
    }

    Item {
        id: overlayContent
        anchors.centerIn: parent
        width: overlay.fixtureMode && overlay.previewSize.width > 0
            ? Math.min(parent.width, overlay.previewSize.width) : parent.width
        height: overlay.fixtureMode && overlay.previewSize.height > 0
            ? Math.min(parent.height, overlay.previewSize.height) : parent.height
        focus: overlay.visible

        Keys.onPressed: event => inputManager.processKeyEvent(event, true)
        Keys.onReleased: event => inputManager.processKeyEvent(event, false)

        Image {
            anchors.fill: parent
            visible: overlay.fixtureMode
            source: overlay.fixtureMode ? Qt.resolvedUrl("../../fixtures/mockup/art/backdrop.png") : ""
            fillMode: Image.PreserveAspectCrop
        }

        Bg {
            styleTokens: styleTokens
        }

        // Chrome persistente del dashboard (no se destruye al cambiar de slide)
        TopBar {
            id: topBar
            visible: overlay.active
            opacity: overlay.dashboardOpacity
            tabControlsEnabled: overlay.fixtureMode && layerManager.topLayer === "dashboard"
            fixtureTime: overlay.mockSession?.sceneSpec?.time ?? ""
            onSlideRequested: slideId => slideManager.select(slideId)
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: DmsCommon.Theme.spacingXL
            anchors.leftMargin: overlay.fixtureMode ? overlayContent.width * 0.042 : DmsCommon.Theme.spacingXL
            anchors.rightMargin: overlay.fixtureMode ? overlayContent.width * 0.042 : DmsCommon.Theme.spacingXL
            styleTokens: styleTokens
            motionTokens: motionTokens
            i18n: i18n
            iconsPadManager: iconsPadManager
            screens: screenRegistry.screens
            currentIndex: slideManager.currentIndex
            gamepadConnected: (overlay.fixtureControllerAvailable || (overlay.bridge?.connected ?? false)) && inputManager.activeDevice !== "keyboard"
        }

        CaptureQuickActions {
            anchors.top: topBar.bottom
            anchors.topMargin: DmsCommon.Theme.spacingS
            anchors.right: topBar.right
            visible: overlay.fixtureMode && overlay.active
            opacity: overlay.dashboardOpacity
            showShortcuts: slideManager.currentScreenMeta?.id === "home"
            elapsed: overlay.mockSession?.capture?.elapsed ?? 0
            controlsEnabled: layerManager.topLayer === "dashboard"
            styleTokens: styleTokens
            i18n: i18n
            recording: overlay.mockSession?.capture?.recording ?? false
            onActionRequested: intent => overlay.mockSession?.dispatch(intent)
        }

        SlideManager {
            id: slideManager
            visible: overlay.active
            opacity: overlay.dashboardOpacity
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
            windowManager: windowLoader.item
            windowIconProvider: iconLoader.item
            mockSession: overlay.mockSession
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

        Loader {
            id: wheelLoader
            anchors.fill: parent
            active: overlay.fixtureMode
            visible: overlay.fixtureWheelOpen
            source: screenRegistry.wheelSource
            onLoaded: {
                item.side = Qt.binding(() => overlay.wheelSide)
                item.layerManager = layerManager
                item.navigationManager = navigationManager
                item.i18n = i18n
                item.styleTokens = styleTokens
                item.motionTokens = motionTokens
                item.iconsPadManager = iconsPadManager
                item.mockSession = Qt.binding(() => overlay.mockSession)
            }
        }

        Toast {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: DmsCommon.Theme.spacingXL
            message: overlay.noticeKey ? i18n.t(overlay.noticeKey) : ""
            styleTokens: styleTokens
            motionTokens: motionTokens
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
