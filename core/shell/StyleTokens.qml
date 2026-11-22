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
    property real scrimOpacity: 0.58
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

    readonly property bool iconTintEnabled: iconColorMode !== "colored"
    readonly property color iconTintColor: {
        if (iconColorMode === "custom")
            return iconCustomColor
        if (iconColorMode === "dms")
            return accentColor
        return "#14161D"
    }

    function _isLightRole(role) {
        return themeMode === "light" || (themeMode === "hybrid" && role === "chrome")
    }

    function surfaceColor(role) {
        // Política visual: superficies de componentes siempre sólidas y opacas (alfa 1.0)
        return _isLightRole(role) ? Qt.rgba(0.95, 0.96, 0.97, 1.0) : Qt.rgba(0.08, 0.09, 0.11, 1.0)
    }

    function disabledSurfaceColor(role) {
        return _isLightRole(role) ? Qt.rgba(0.85, 0.86, 0.90, 1.0) : Qt.rgba(0.11, 0.13, 0.17, 1.0)
    }

    function onSurfaceColor(role) {
        return _isLightRole(role) ? "#14161D" : "#F2F4F8"
    }

    function disabledOnSurfaceColor(role) {
        return _isLightRole(role) ? "#6B7280" : "#64748B"
    }

    readonly property color errorColor: Theme.error ?? "#B00020"

    function borderColor(role) {
        return _isLightRole(role) ? Qt.rgba(0, 0, 0, 0.14) : Qt.rgba(1, 1, 1, 0.14)
    }

    function scrimColor(alphaMultiplier) {
        const mult = alphaMultiplier ?? 1.0
        const alpha = Math.max(0, Math.min(0.92, scrimOpacity * mult))
        // Scrim global siempre oscuro incluso en theme.mode = "light"
        return Qt.rgba(0.04, 0.05, 0.08, alpha)
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
                    if (typeof cfg.theme.scrimOpacity === "number")
                        tokens.scrimOpacity = cfg.theme.scrimOpacity
                    if (typeof cfg.theme.scale === "number")
                        tokens.uiScale = cfg.theme.scale
                }
                if (cfg?.icons) {
                    if (typeof cfg.icons.colorMode === "string") {
                        // Migración explícita: el valor previo "native" equivale a "colored"
                        tokens.iconColorMode = cfg.icons.colorMode === "native"
                            ? "colored"
                            : cfg.icons.colorMode
                    }
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
