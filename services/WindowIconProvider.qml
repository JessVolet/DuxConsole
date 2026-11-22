import QtQuick
import Quickshell

QtObject {
    id: provider

    // Niri 26.04 IPC y Quickshell Wayland no exponen captura de píxeles por ID de ventana
    // sin screencasting PipeWire permanente; se prioriza icono real XDG y fallback limpio.
    readonly property bool thumbnailsSupported: false

    function resolve(win) {
        if (!win)
            return { type: "none", source: "", fallbackLabel: "" }

        const appId = win.appId || ""
        const appName = win.appName || "Window"

        if (appId !== "") {
            let path = Quickshell.iconPath(appId, true)
            if (!path)
                path = Quickshell.iconPath(appId.toLowerCase(), true)
            if (!path && appId.indexOf(".") !== -1) {
                const tail = appId.split(".").pop().toLowerCase()
                path = Quickshell.iconPath(tail, true)
            }
            if (path && path.length > 0) {
                const url = path.startsWith("file://") || path.startsWith("image://")
                    ? path
                    : ("file://" + path)
                return { type: "icon", source: url, fallbackLabel: appName }
            }
        }

        return {
            type: "fallback",
            source: "",
            fallbackLabel: appName.slice(0, 2).toUpperCase()
        }
    }
}
