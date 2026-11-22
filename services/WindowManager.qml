import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: wm
    visible: false

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET") || ""
    property bool available: false
    property string status: socketPath !== "" ? "connecting" : "unavailable"
    property string lastError: ""

    // Estado normalizado público
    property var windows: []
    property var workspaces: []
    property var outputs: []

    // Estado interno crudo de Niri
    property var _rawWindows: []
    property var _rawWorkspaces: []
    property var _rawOutputs: ({})
    property var _pendingCmds: []
    property bool _cmdBusy: false
    property var _protectedComms: [
        "niri", "quickshell", "qs", "dms", "systemd", "dbus-daemon",
        "dbus-broker", "dconsole", "xwayland", "wayland", "pipewire", "wireplumber"
    ]

    function _formatAppName(appId, title) {
        if (appId && appId.length > 0) {
            const parts = appId.split(".")
            const base = parts[parts.length - 1]
            return base.charAt(0).toUpperCase() + base.slice(1)
        }
        return title || "Window"
    }

    function _rebuildState() {
        const wsMap = ({})
        const normWs = []
        for (let i = 0; i < _rawWorkspaces.length; i++) {
            const ws = _rawWorkspaces[i]
            if (!ws) continue
            const item = {
                id: ws.id,
                idx: typeof ws.idx === "number" ? ws.idx : -1,
                name: ws.name ?? "",
                output: ws.output ?? "",
                isActive: Boolean(ws.is_active),
                isFocused: Boolean(ws.is_focused)
            }
            wsMap[ws.id] = item
            normWs.push(item)
        }
        normWs.sort((a, b) => a.idx - b.idx)
        workspaces = normWs

        const normOut = []
        const outKeys = Object.keys(_rawOutputs || {})
        for (let i = 0; i < outKeys.length; i++) {
            const o = _rawOutputs[outKeys[i]]
            if (!o) continue
            normOut.push({
                name: o.name ?? outKeys[i],
                make: o.make ?? "",
                model: o.model ?? "",
                logicalWidth: o.logical?.width ?? 0,
                logicalHeight: o.logical?.height ?? 0
            })
        }
        outputs = normOut

        const normWin = []
        for (let i = 0; i < _rawWindows.length; i++) {
            const w = _rawWindows[i]
            if (!w) continue
            const ws = w.workspace_id !== undefined && w.workspace_id !== null ? wsMap[w.workspace_id] : null
            const isFs = typeof w.is_fullscreen === "boolean" ? w.is_fullscreen : false
            normWin.push({
                id: w.id,
                title: w.title ?? "",
                appId: w.app_id ?? "",
                appName: _formatAppName(w.app_id, w.title),
                workspaceId: w.workspace_id ?? null,
                workspaceIndex: ws ? ws.idx : -1,
                workspaceName: ws ? ws.name : "",
                output: ws ? ws.output : "",
                isFocused: Boolean(w.is_focused),
                isFloating: Boolean(w.is_floating),
                isFullscreen: isFs,
                pid: typeof w.pid === "number" ? w.pid : -1
            })
        }
        normWin.sort((a, b) => {
            if (a.workspaceIndex !== b.workspaceIndex)
                return a.workspaceIndex - b.workspaceIndex
            return a.id - b.id
        })
        windows = normWin
    }

    // Procesa eventos entrantes de EventStream o respuestas de snapshot
    function _handleEvent(ev) {
        if (!ev || typeof ev !== "object")
            return

        if (ev.WindowsChanged) {
            _rawWindows = ev.WindowsChanged.windows || []
            _rebuildState()
        } else if (ev.WindowOpenedOrChanged) {
            const win = ev.WindowOpenedOrChanged.window
            if (!win) return
            const next = _rawWindows.slice()
            const idx = next.findIndex(w => w && w.id === win.id)
            if (idx >= 0) next[idx] = win
            else next.push(win)
            _rawWindows = next
            _rebuildState()
        } else if (ev.WindowClosed) {
            const cid = ev.WindowClosed.id
            _rawWindows = _rawWindows.filter(w => w && w.id !== cid)
            _rebuildState()
        } else if (ev.WindowFocusChanged) {
            const fid = ev.WindowFocusChanged.id
            _rawWindows = _rawWindows.map(w => {
                if (!w) return w
                return Object.assign({}, w, { is_focused: w.id === fid })
            })
            _rebuildState()
        } else if (ev.WindowLayoutsChanged) {
            const changes = ev.WindowLayoutsChanged.changes || []
            if (changes.length > 0) {
                const map = ({})
                for (let i = 0; i < changes.length; i++)
                    map[changes[i][0]] = changes[i][1]
                _rawWindows = _rawWindows.map(w => {
                    if (!w || !map[w.id]) return w
                    return Object.assign({}, w, { layout: map[w.id] })
                })
                _rebuildState()
            }
        } else if (ev.WorkspacesChanged) {
            _rawWorkspaces = ev.WorkspacesChanged.workspaces || []
            _rebuildState()
        } else if (ev.WorkspaceActivated) {
            const aid = ev.WorkspaceActivated.id
            const afoc = Boolean(ev.WorkspaceActivated.focused)
            _rawWorkspaces = _rawWorkspaces.map(ws => {
                if (!ws) return ws
                if (ws.id === aid)
                    return Object.assign({}, ws, { is_active: true, is_focused: afoc })
                return Object.assign({}, ws, { is_focused: afoc ? false : ws.is_focused })
            })
            _rebuildState()
        }
    }

    function applyMockSnapshot(winList, wsList, outMap) {
        _rawWindows = winList || []
        _rawWorkspaces = wsList || []
        _rawOutputs = outMap || ({})
        available = true
        status = "ready"
        lastError = ""
        _rebuildState()
    }

    function windowById(winId) {
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].id === winId)
                return windows[i]
        }
        return null
    }

    function _sendIpc(payload, callback) {
        if (socketPath === "") {
            lastError = "NIRI_SOCKET no disponible"
            if (callback) callback(false, lastError)
            return
        }
        _pendingCmds.push({ payload: payload, callback: callback || null })
        _pumpNextCmd()
    }

    function _pumpNextCmd() {
        if (_cmdBusy || _pendingCmds.length === 0)
            return
        _cmdBusy = true
        if (cmdSocket.connected) {
            const entry = _pendingCmds[0]
            cmdSocket.write(JSON.stringify(entry.payload) + "\n")
        } else {
            cmdSocket.connected = true
        }
    }

    function _finishCmd(ok, data) {
        const entry = _pendingCmds.shift()
        _cmdBusy = false
        cmdSocket.connected = false
        if (!ok && typeof data === "string")
            lastError = data
        if (entry && entry.callback)
            entry.callback(ok, data)
        if (_pendingCmds.length > 0)
            Qt.callLater(_pumpNextCmd)
    }

    function refreshOutputs() {
        _sendIpc("Outputs", (ok, data) => {
            if (ok && data && data.Outputs) {
                _rawOutputs = data.Outputs
                _rebuildState()
            }
        })
    }

    function focusWindow(winId, callback) {
        if (!windowById(winId)) {
            if (callback) callback(false, "Ventana inexistente")
            return
        }
        _sendIpc({ Action: { FocusWindow: { id: winId } } }, callback)
    }

    function moveWindowToMonitor(winId, outputName, callback) {
        if (!windowById(winId)) {
            if (callback) callback(false, "Ventana inexistente")
            return
        }
        if (!outputs.some(o => o.name === outputName)) {
            if (callback) callback(false, "Monitor no disponible")
            return
        }
        _sendIpc({ Action: { MoveWindowToMonitor: { id: winId, output: outputName } } }, callback)
    }

    function moveWindowToWorkspace(winId, workspaceId, callback) {
        if (!windowById(winId)) {
            if (callback) callback(false, "Ventana inexistente")
            return
        }
        const ws = workspaces.find(w => w.id === workspaceId)
        if (!ws) {
            if (callback) callback(false, "Workspace no disponible")
            return
        }
        const refObj = ws.name !== "" ? ({ Name: ws.name }) : ({ Index: ws.idx })
        _sendIpc({ Action: { MoveWindowToWorkspace: { window_id: winId, reference: refObj, focus: false } } }, callback)
    }

    function toggleFullscreen(winId, callback) {
        if (!windowById(winId)) {
            if (callback) callback(false, "Ventana inexistente")
            return
        }
        _sendIpc({ Action: { FullscreenWindow: { id: winId } } }, callback)
    }

    function closeWindow(winId, callback) {
        if (!windowById(winId)) {
            if (callback) callback(false, "Ventana inexistente")
            return
        }
        _sendIpc({ Action: { CloseWindow: { id: winId } } }, callback)
    }

    // Capacidad separada para terminación forzada: requiere PID verificado y no protegido
    function canForceKill(winId) {
        const w = windowById(winId)
        if (!w || w.pid <= 1)
            return false
        const appLower = (w.appId || "").toLowerCase()
        for (let i = 0; i < _protectedComms.length; i++) {
            if (appLower === _protectedComms[i])
                return false
        }
        return true
    }

    function forceKillReason(winId) {
        const w = windowById(winId)
        if (!w) return "Ventana inexistente"
        if (w.pid <= 1) return "PID no expuesto por Niri IPC"
        if (!canForceKill(winId)) return "Proceso protegido del sistema"
        return ""
    }

    function forceKillWindow(winId, callback) {
        const w = windowById(winId)
        if (!w || !canForceKill(winId)) {
            if (callback) callback(false, forceKillReason(winId))
            return
        }
        const pid = w.pid
        killVerifyProc.targetPid = pid
        killVerifyProc.pendingCallback = callback || null
        killVerifyProc.command = [
            "sh", "-c",
            "comm=$(cat /proc/" + pid + "/comm 2>/dev/null || true); " +
            "uid=$(awk '/^Uid:/{print $2}' /proc/" + pid + "/status 2>/dev/null || true); " +
            "echo \"$uid|$comm\""
        ]
        killVerifyProc.running = true
    }

    Process {
        id: killVerifyProc
        property int targetPid: -1
        property var pendingCallback: null
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split("|")
                const procUid = parts[0] || ""
                const comm = (parts[1] || "").toLowerCase()
                const myUid = Quickshell.env("UID") || ""
                const cb = killVerifyProc.pendingCallback
                killVerifyProc.pendingCallback = null

                if (!comm || (myUid !== "" && procUid !== myUid)) {
                    if (cb) cb(false, "No se pudo verificar propiedad del proceso")
                    return
                }
                if (wm._protectedComms.indexOf(comm) !== -1) {
                    if (cb) cb(false, "Proceso protegido: " + comm)
                    return
                }
                killExecProc.command = ["kill", "-TERM", String(killVerifyProc.targetPid)]
                killExecProc.pendingCallback = cb
                killExecProc.running = true
            }
        }
    }

    Process {
        id: killExecProc
        property var pendingCallback: null
        onExited: (code, _) => {
            const cb = killExecProc.pendingCallback
            killExecProc.pendingCallback = null
            if (cb) cb(code === 0, code === 0 ? "SIGTERM enviado" : "Error al enviar SIGTERM")
        }
    }

    Socket {
        id: eventSocket
        path: wm.socketPath
        connected: wm.socketPath !== ""

        onConnectedChanged: {
            if (connected) {
                wm.available = true
                wm.status = "ready"
                wm.lastError = ""
                write("\"EventStream\"\n")
                wm.refreshOutputs()
            } else {
                wm.available = false
                wm.status = wm.socketPath !== "" ? "connecting" : "unavailable"
            }
        }

        parser: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (!line) return
                let msg
                try { msg = JSON.parse(line) } catch (_) { return }
                if (msg && msg.Ok !== undefined) return
                wm._handleEvent(msg)
            }
        }
    }

    Socket {
        id: cmdSocket
        path: wm.socketPath
        connected: false

        onConnectedChanged: {
            if (connected && wm._cmdBusy && wm._pendingCmds.length > 0) {
                write(JSON.stringify(wm._pendingCmds[0].payload) + "\n")
            } else if (!connected && wm._cmdBusy) {
                wm._finishCmd(false, "Socket de comandos desconectado")
            }
        }

        parser: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (!line) return
                let resp
                try {
                    resp = JSON.parse(line)
                } catch (_) {
                    wm._finishCmd(false, "Respuesta IPC inválida")
                    return
                }
                if (resp && resp.Ok !== undefined)
                    wm._finishCmd(true, resp.Ok)
                else if (resp && resp.Err !== undefined)
                    wm._finishCmd(false, String(resp.Err))
                else
                    wm._finishCmd(false, "Respuesta desconocida")
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: true
        running: wm.socketPath !== "" && !eventSocket.connected
        onTriggered: eventSocket.connected = true
    }
}
