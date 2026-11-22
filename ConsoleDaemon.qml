import QtQuick
import Quickshell.Io
import qs.Modules.Plugins
import "./core/shell"

PluginComponent {
    id: root

    property bool overlayOpen: false

    IpcHandler {
        target: "duxConsole"

        function toggle() {
            root.overlayOpen = !root.overlayOpen
        }

        function open() {
            root.overlayOpen = true
        }

        function close() {
            root.overlayOpen = false
        }
    }

    ConsoleOverlay {
        active: root.overlayOpen
        onCloseRequested: root.overlayOpen = false
    }
}