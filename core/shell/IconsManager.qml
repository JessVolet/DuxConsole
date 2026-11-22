import QtQuick

QtObject {
    id: icons

    property var inputManager: null

    readonly property var _keyLabels: ({
        "Return": "Enter",
        "Escape": "Esc",
        "Space": "Space",
        "Tab": "Tab",
        "Up": "↑",
        "Down": "↓",
        "Left": "←",
        "Right": "→"
    })

    readonly property var _gamepadSlugs: ({
        "BTN_SOUTH": "south",
        "BTN_EAST": "east",
        "BTN_NORTH": "north",
        "BTN_WEST": "west",
        "BTN_TL": "lb",
        "BTN_TR": "rb",
        "ABS_Z": "lt",
        "ABS_RZ": "rt",
        "BTN_SELECT": "select",
        "BTN_START": "start",
        "BTN_MODE": "guide",
        "BTN_THUMBL": "l3",
        "BTN_THUMBR": "r3",
        "BTN_DPAD_UP": "dpad_up",
        "BTN_DPAD_DOWN": "dpad_down",
        "BTN_DPAD_LEFT": "dpad_left",
        "BTN_DPAD_RIGHT": "dpad_right"
    })

    readonly property var _xboxLabels: ({
        "BTN_SOUTH": "A",
        "BTN_EAST": "B",
        "BTN_NORTH": "Y",
        "BTN_WEST": "X",
        "BTN_TL": "LB",
        "BTN_TR": "RB",
        "ABS_Z": "LT",
        "ABS_RZ": "RT",
        "BTN_SELECT": "View",
        "BTN_START": "Menu",
        "BTN_MODE": "Guide",
        "BTN_THUMBL": "LS",
        "BTN_THUMBR": "RS",
        "BTN_DPAD_UP": "D↑",
        "BTN_DPAD_DOWN": "D↓",
        "BTN_DPAD_LEFT": "D←",
        "BTN_DPAD_RIGHT": "D→"
    })

    readonly property var _psLabels: ({
        "BTN_SOUTH": "✕",
        "BTN_EAST": "○",
        "BTN_NORTH": "△",
        "BTN_WEST": "□",
        "BTN_TL": "L1",
        "BTN_TR": "R1",
        "ABS_Z": "L2",
        "ABS_RZ": "R2",
        "BTN_SELECT": "Create",
        "BTN_START": "Options",
        "BTN_MODE": "PS",
        "BTN_THUMBL": "L3",
        "BTN_THUMBR": "R3",
        "BTN_DPAD_UP": "D↑",
        "BTN_DPAD_DOWN": "D↓",
        "BTN_DPAD_LEFT": "D←",
        "BTN_DPAD_RIGHT": "D→"
    })

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
        const cfg = inputManager?.config ?? ({})

        if (device === "keyboard") {
            const rawKey = _findRawCode(cfg.keyboard, action)
            const label = rawKey ? (_keyLabels[rawKey] ?? rawKey) : action
            return { type: "key", label: label, source: "" }
        }

        const rawBtn = _findRawCode(cfg.gamepad, action)
        const slug = rawBtn ? (_gamepadSlugs[rawBtn] ?? rawBtn.toLowerCase()) : ""
        const labelMap = device === "playstation" ? _psLabels : _xboxLabels
        const fallbackLabel = rawBtn ? (labelMap[rawBtn] ?? rawBtn) : action
        const svgSource = slug
            ? Qt.resolvedUrl("../../assets/glyphs/" + device + "/" + slug + ".svg").toString()
            : ""

        return { type: "svg", label: fallbackLabel, source: svgSource }
    }
}
