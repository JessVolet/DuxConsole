import QtQuick

Item {
    id: service
    property var backend: null
    property var stateStore: null
    property bool live: true
    property var _heldBackend: null
    property string error: ""
    readonly property var nodes: backend?.allNodes ?? []
    readonly property var applications: buildApps()
    readonly property var outputs: preferences.sorted(buildDevices("output"), "output")
    readonly property var inputs: preferences.sorted(buildDevices("input"), "input")
    readonly property bool available: nodes.length > 0
    AudioDevicePreferences { id: preferences; store: service.stateStore }
    function syncReference() {
        if (_heldBackend && (_heldBackend !== backend || !live)) { _heldBackend.removeRef(); _heldBackend = null }
        if (live && backend && !_heldBackend) { backend.addRef(); _heldBackend = backend }
    }
    onBackendChanged: syncReference()
    onLiveChanged: syncReference()
    Component.onCompleted: syncReference()
    Component.onDestruction: { if (_heldBackend) _heldBackend.removeRef() }

    function nodeKey(node, kind) {
        if (kind !== "app") return kind + ":" + node.name
        const p = node.properties ?? ({})
        return "app:" + (p["application.id"] || p["application.process.binary"] || p["application.process.id"] || node.name || node.id)
    }
    function maximum(node) { return Math.max(0.01, (backend?.getMaxVolumePercent ? backend.getMaxVolumePercent(node) : 100) / 100) }
    function snapshot(group, kind) {
        const node = group[0], key = nodeKey(node, kind)
        const pins = kind === "app" ? [] : preferences.pins(kind)
        return { key: key, kind: kind, title: backend?.displayName ? backend.displayName(node) : String(node.description || node.name || ""),
            subtitle: kind === "app" ? String(node.properties?.["media.name"] ?? "") : String(node.name ?? ""),
            volume: Math.max(...group.map(n => Number(n.audio.volume) || 0)),
            maxVolume: Math.min(...group.map(n => maximum(n))), muted: group.every(n => Boolean(n.audio.muted)),
            canSetVolume: true, canMute: true, pinned: pins.includes(key),
            active: kind === "output" ? backend?.sink?.name === node.name : kind === "input" && backend?.source?.name === node.name,
            hasOptions: kind !== "app" }
    }
    function buildApps() {
        const groups = new Map()
        for (const node of nodes) {
            if (!node?.audio || !node.isStream || !node.isSink || backend?.isOwnStream?.(node)) continue
            const key = nodeKey(node, "app")
            if (!groups.has(key)) groups.set(key, [])
            groups.get(key).push(node)
        }
        return Array.from(groups.values()).map(group => snapshot(group, "app"))
    }
    function buildDevices(kind) {
        return nodes.filter(n => n?.audio && !n.isStream && Boolean(n.isSink) === (kind === "output") && n.name)
            .map(n => snapshot([n], kind))
    }
    function resolve(key) {
        if (typeof key !== "string") return []
        const kind = key.split(":")[0]
        if (!["app", "output", "input"].includes(kind)) return []
        return nodes.filter(n => n?.audio && (kind === "app" ? n.isStream && n.isSink && !backend?.isOwnStream?.(n)
            : !n.isStream && Boolean(n.isSink) === (kind === "output")) && nodeKey(n, kind) === key)
    }
    function setVolume(key, value) {
        if (!Number.isFinite(value)) return false
        const group = resolve(key)
        for (const node of group) {
            const next = Math.max(0, Math.min(maximum(node), value))
            if (Math.abs(node.audio.volume - next) > 0.0001) node.audio.volume = next
        }
        return group.length > 0
    }
    function setMuted(key, muted) {
        const group = resolve(key)
        for (const node of group) node.audio.muted = muted
        return group.length > 0
    }
    function activate(key) {
        const group = resolve(key)
        if (!group.length || key.startsWith("app:")) return false
        const ok = key.startsWith("output:") ? backend.setSink(group[0]) : backend.setSource(group[0])
        error = ok ? "" : "activation_failed"
        return ok
    }
    function togglePin(key) {
        const kind = key.split(":")[0]
        if (resolve(key).length) preferences.toggle(kind, key)
    }
    function choices(key) {
        const node = resolve(key)[0]
        return node && key.startsWith("output:") ? backend?.outputChoices?.[node.name] ?? [] : []
    }
    function refreshOptions(key) {
        if (!key.startsWith("output:") || !resolve(key).length) return
        backend?.refreshCards?.()
        backend?.refreshSinkPorts?.()
    }
    function applyChoice(key, choice) {
        if (!resolve(key).length || !choices(key).includes(choice)) return
        backend.activateOutputChoice(choice, (ok, message) => { error = ok ? "" : String(message ?? "") })
    }
}
