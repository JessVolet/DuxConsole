import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: bridge
    visible: false

    property var inputManager: null
    property bool overlayActive: false
    readonly property bool connected: socket.connected

    function _sendOverlayState() {
        if (!socket.connected)
            return
        socket.write(JSON.stringify({ type: "overlay", active: bridge.overlayActive }) + "\n")
    }

    onOverlayActiveChanged: _sendOverlayState()

    Socket {
        id: socket
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dconsole.sock"
        connected: true

        onConnectedChanged: {
            if (connected)
                bridge._sendOverlayState()
            else
                bridge.inputManager?.resetState()
        }

        parser: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (!line)
                    return

                let msg
                try {
                    msg = JSON.parse(line)
                } catch (_) {
                    return
                }

                if (!msg || !bridge.inputManager || !bridge.overlayActive)
                    return

                if (msg.type === "axis" && typeof msg.stick === "string") {
                    const action = bridge.inputManager.config?.analog?.[msg.stick]?.action
                    if (action) bridge.inputManager.handleAnalog(action, msg.x, msg.y, msg.device)
                } else if (msg.type === "status" && msg.connected === false) {
                    bridge.inputManager.resetState()
                }

                if (msg.type === "button" && typeof msg.code === "string") {
                    if (msg.pressed === true)
                        bridge.inputManager.handleRawPress("gamepad", msg.code, msg.device)
                    else if (msg.pressed === false)
                        bridge.inputManager.handleRawRelease("gamepad", msg.code)
                }
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: true
        running: !socket.connected
        onTriggered: socket.connected = true
    }
}
