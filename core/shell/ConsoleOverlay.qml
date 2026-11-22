import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components/chrome"
import "../../services"
import "../interaction"

PanelWindow {
    id: overlay

    property bool active: false
    signal closeRequested()

    visible: active
    onActiveChanged: {
        if (!active) {
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
    LayerManager { id: layerManager }
    I18n { id: i18n }

    IconsPadManager {
        id: iconsPadManager
        inputManager: inputManager
    }

    DconsoleBridge {
        id: dconsoleBridge
        inputManager: inputManager
        overlayActive: overlay.active
    }

    InputManager {
        id: inputManager
        onTriggered: (action, payload) => {
            if (action === "I.Refuse") {
                if (!layerManager.pop())
                    overlay.closeRequested()
            } else if ((action === "I.ActionSlide.R" || action === "I.ActionSlide.L") && layerManager.topLayer !== "dashboard") {
                return
            } else if (action === "I.ActionSlide.R") {
                slideManager.next()
            } else if (action === "I.ActionSlide.L") {
                slideManager.prev()
            } else {
                layerManager.handleAction(action, payload)
            }
        }
    }

    Item {
        id: overlayContent
        anchors.fill: parent
        focus: overlay.active

        Keys.onPressed: event => inputManager.processKeyEvent(event, true)
        Keys.onReleased: event => inputManager.processKeyEvent(event, false)

        Bg {}

        SlideManager {
            id: slideManager
            anchors.fill: parent
            registry: screenRegistry
            inputManager: inputManager
            layerManager: layerManager
            iconsPadManager: iconsPadManager
            i18n: i18n
        }

        FocusRing {
            id: focusRing
            targetZone: layerManager.activeZone
            coordinateSpace: overlayContent
        }
    }
}
