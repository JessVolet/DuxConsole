import QtQuick
import Quickshell.Io

Item {
    id: input
    visible: false

    // Señal única que consume toda la UI
    signal triggered(string action, var payload)

    // Para glifos adaptativos: "keyboard" | "xbox" | "playstation"
    property string activeDevice: "keyboard"
    property string lastAction: ""
    property var config: ({})

    // Estado interno de gestos y repetición
    property bool _guideHeld: false
    property bool _chordConsumed: false
    property string _heldRepeatable: ""

    FileView {
        id: configFile
        path: Qt.resolvedUrl("../../inputconfig.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                input.config = JSON.parse(text())
            } catch (e) {
                console.warn("DuxConsole [InputManager]: Error en inputconfig.json ->", e)
            }
        }
    }

    // Hold de Guide (0.3s)
    Timer {
        id: guideHoldTimer
        interval: input.config?.gestures?.holds?.["I.Guide"]?.ms ?? 300
        repeat: false
        onTriggered: {
            if (input._guideHeld && !input._chordConsumed) {
                input._chordConsumed = true
                const emitAction = input.config?.gestures?.holds?.["I.Guide"]?.emit ?? "I.SystemWheel"
                input._emit(emitAction, null)
            }
        }
    }

    // Repeater (retardo inicial -> tick constante)
    Timer {
        id: repeatDelayTimer
        interval: input.config?.gestures?.repeatInitialMs ?? 330
        repeat: false
        onTriggered: {
            if (input._heldRepeatable !== "") {
                input._emit(input._heldRepeatable, { repeat: true })
                repeatTickTimer.start()
            }
        }
    }

    Timer {
        id: repeatTickTimer
        interval: input.config?.gestures?.repeatIntervalMs ?? 110
        repeat: true
        onTriggered: {
            if (input._heldRepeatable !== "")
                input._emit(input._heldRepeatable, { repeat: true })
            else
                stop()
        }
    }

    function _emit(action, payload) {
        lastAction = action
        triggered(action, payload)
    }

    function _stopRepeat() {
        _heldRepeatable = ""
        repeatDelayTimer.stop()
        repeatTickTimer.stop()
    }

    function _isRepeatable(action) {
        const list = config?.gestures?.repeatable ?? []
        return list.indexOf(action) !== -1
    }

    // --- Puerta de entrada unificada (Teclado hoy / dconsole mañana) ---

    function handleRawPress(source, code, deviceLabel) {
        activeDevice = deviceLabel ?? (source === "keyboard" ? "keyboard" : "xbox")

        const semantic = config?.[source]?.[code]
        if (!semantic) return

        if (semantic === "I.Guide") {
            _guideHeld = true
            _chordConsumed = false
            guideHoldTimer.restart()
            return
        }

        // Acorde Guide + acción (ej. Guide + RB)
        if (_guideHeld) {
            const chordAction = config?.gestures?.chords?.["I.Guide+" + semantic]
            if (chordAction) {
                _chordConsumed = true
                guideHoldTimer.stop()
                _emit(chordAction, null)
                return
            }
        }

        _emit(semantic, { repeat: false })

        if (_isRepeatable(semantic)) {
            _heldRepeatable = semantic
            repeatTickTimer.stop()
            repeatDelayTimer.restart()
        }
    }

    function handleRawRelease(source, code) {
        const semantic = config?.[source]?.[code]
        if (!semantic) return

        if (semantic === "I.Guide") {
            guideHoldTimer.stop()
            if (_guideHeld && !_chordConsumed)
                _emit("I.Guide", null)
            _guideHeld = false
            _chordConsumed = false
            return
        }

        if (semantic === _heldRepeatable)
            _stopRepeat()
    }

    // Para ejes analógicos (Stick R) cuando conectemos dconsole
    function handleAnalog(axisAction, x, y, deviceLabel) {
        activeDevice = deviceLabel ?? "xbox"
        _emit(axisAction, { x: x, y: y })
    }

    function resetState() {
        _guideHeld = false
        _chordConsumed = false
        guideHoldTimer.stop()
        _stopRepeat()
    }

    // --- Adaptador de teclado Qt ---

    function processKeyEvent(event, isPress) {
        if (event.isAutoRepeat) {
            event.accepted = true
            return
        }
        const keyName = _qtKeyToName(event.key)
        if (!keyName) return

        if (isPress) handleRawPress("keyboard", keyName, "keyboard")
        else handleRawRelease("keyboard", keyName)
        event.accepted = true
    }

    function _qtKeyToName(key) {
        const map = {
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return",
            [Qt.Key_Escape]: "Escape", [Qt.Key_Tab]: "Tab", [Qt.Key_Space]: "Space",
            [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down", [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right",
            [Qt.Key_E]: "E", [Qt.Key_Q]: "Q", [Qt.Key_1]: "1", [Qt.Key_3]: "3",
            [Qt.Key_P]: "P", [Qt.Key_O]: "O", [Qt.Key_G]: "G", [Qt.Key_R]: "R", [Qt.Key_L]: "L"
        }
        return map[key] ?? ""
    }
}