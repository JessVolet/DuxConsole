import QtQuick
import Quickshell.Io

Item {
    id: padIcons
    visible: false

    property var inputManager: null
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

    function resolve(action) {
        const device = inputManager?.activeDevice ?? "keyboard"
        const inputCfg = inputManager?.config ?? ({})
        const inputSection = device === "keyboard" ? inputCfg.keyboard : inputCfg.gamepad
        const rawCode = _findRawCode(inputSection, action)

        const deviceIcons = iconsConfig?.[device] ?? ({})
        const entry = rawCode ? deviceIcons[rawCode] : null

        const resolvedSource = (entry && entry.source)
            ? Qt.resolvedUrl("../../" + entry.source).toString()
            : ""

        return {
            type: entry?.type ?? "key",
            label: entry?.label ?? (rawCode || action),
            source: resolvedSource
        }
    }
}
