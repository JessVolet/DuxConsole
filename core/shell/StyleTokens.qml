import QtQuick
import Quickshell.Io
import qs.Common

Item {
    id: tokens
    visible: false

    property string themeMode: "hybrid"          // "hybrid" | "dark" | "light"
    property string accentSource: "primary"      // "primary" | "secondary" | "tertiary" | "custom"
    property color customAccent: "#A855F7"
    property real skewAngle: -8
    property bool blurEnabled: true
    property real surfaceOpacity: 0.80
    property real uiScale: 1.0

    property string iconColorMode: "dms"         // "dms" | "colored" | "custom"
    property string iconStyle: "filled"          // "filled" | "outline"
    property color iconCustomColor: "#FFFFFF"
    property bool iconShowBackdrop: true

    readonly property color accentColor: {
        switch (accentSource) {
        case "secondary":
            return Theme.secondary
        case "tertiary":
            return Theme.tertiary ?? Theme.primary
        case "custom":
            return customAccent
        default:
            return Theme.primary
        }
    }

    readonly property bool iconTintEnabled: iconColorMode === "dms" || iconColorMode === "custom"
    readonly property color iconTintColor: {
        switch (iconColorMode) {
        case "custom":
            return iconCustomColor
        case "dms":
            return accentColor
        default:
            return Theme.onSurface
        }
    }

    function _isLightRole(role) {
        return themeMode === "light" || (themeMode === "hybrid" && role === "chrome")
    }

    function surfaceColor(role) {
        const base = _isLightRole(role) ? "#F2F4F8" : "#14161D"
        return Qt.alpha(base, surfaceOpacity)
    }

    function onSurfaceColor(role) {
        return _isLightRole(role) ? "#14161D" : "#F2F4F8"
    }

    function borderColor(role) {
        return _isLightRole(role) ? Qt.rgba(0, 0, 0, 0.14) : Qt.rgba(1, 1, 1, 0.14)
    }

    FileView {
        id: uiConfigFile
        path: Qt.resolvedUrl("../../uiconfig.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const cfg = JSON.parse(text())
                if (cfg?.theme) {
                    if (typeof cfg.theme.mode === "string")
                        tokens.themeMode = cfg.theme.mode
                    if (typeof cfg.theme.accentSource === "string")
                        tokens.accentSource = cfg.theme.accentSource
                    if (typeof cfg.theme.customAccent === "string")
                        tokens.customAccent = cfg.theme.customAccent
                    if (typeof cfg.theme.skewAngle === "number")
                        tokens.skewAngle = cfg.theme.skewAngle
                    if (typeof cfg.theme.blurEnabled === "boolean")
                        tokens.blurEnabled = cfg.theme.blurEnabled
                    if (typeof cfg.theme.surfaceOpacity === "number")
                        tokens.surfaceOpacity = cfg.theme.surfaceOpacity
                    if (typeof cfg.theme.scale === "number")
                        tokens.uiScale = cfg.theme.scale
                }
                if (cfg?.icons) {
                    if (typeof cfg.icons.colorMode === "string")
                        tokens.iconColorMode = cfg.icons.colorMode
                    if (typeof cfg.icons.style === "string")
                        tokens.iconStyle = cfg.icons.style
                    if (typeof cfg.icons.customColor === "string")
                        tokens.iconCustomColor = cfg.icons.customColor
                    if (typeof cfg.icons.showBackdrop === "boolean")
                        tokens.iconShowBackdrop = cfg.icons.showBackdrop
                }
            } catch (e) {
                console.warn("DuxConsole [StyleTokens]: Error en uiconfig.json ->", e)
            }
        }
    }
}
