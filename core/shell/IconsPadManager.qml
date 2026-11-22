import QtQuick
import Quickshell.Io

Item {
    id: padIcons
    visible: false

    property var inputManager: null
    property var styleTokens: null
    property var iconsConfig: ({})

    FileView {
        id: iconsFile
        path: Qt.resolvedUrl("../../iconsconfig.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                padIcons.iconsConfig = JSON.parse(text())
            } catch (e) {
                console.warn("DuxConsole [IconsPadManager]: Error en iconsconfig.json ->", e)
            }
        }
    }

    function _findRawCode(sectionMap, action) {
        if (!sectionMap || !action)
            return ""
        const keys = Object.keys(sectionMap)
        for (let i = 0; i < keys.length; i++) {
            if (sectionMap[keys[i]] === action)
                return keys[i]
        }
        return ""
    }

    function _pickVariant(variantObj, style) {
        if (!variantObj)
            return ""
        if (typeof variantObj === "string")
            return variantObj
        return variantObj[style] ?? variantObj.filled ?? variantObj.outline ?? ""
    }

    function resolve(action) {
        const device = inputManager?.activeDevice ?? "keyboard"
        const inputCfg = inputManager?.config ?? ({})
        const inputSection = device === "keyboard" ? inputCfg.keyboard : inputCfg.gamepad
        const rawCode = _findRawCode(inputSection, action)

        const colorMode = styleTokens?.iconColorMode ?? "dms"
        const style = styleTokens?.iconStyle ?? "filled"
        const showBackdrop = styleTokens ? styleTokens.iconShowBackdrop : true

        const deviceIcons = iconsConfig?.[device] ?? ({})
        const entry = rawCode ? deviceIcons[rawCode] : null

        let relPath = ""
        let isMonochrome = true

        if (entry) {
            if (colorMode === "colored" && entry.colored) {
                relPath = _pickVariant(entry.colored, style)
                isMonochrome = false
            }
            if (!relPath && entry.mono) {
                relPath = _pickVariant(entry.mono, style)
                isMonochrome = true
            }
            if (!relPath && entry.source) {
                relPath = entry.source
                isMonochrome = true
            }
        }

        const resolvedSource = relPath
            ? Qt.resolvedUrl("../../" + relPath).toString()
            : ""

        return {
            type: resolvedSource !== "" ? "svg" : "key",
            label: entry?.label ?? (rawCode || action),
            source: resolvedSource,
            isMonochrome: isMonochrome,
            colorMode: colorMode,
            style: style,
            showBackdrop: showBackdrop
        }
    }
}
