import QtQuick

QtObject {
    id: manager

    property string baseLayer: "dashboard"
    property var stack: [baseLayer]
    readonly property string activeLayer: stack.length > 0 ? stack[stack.length - 1] : baseLayer
    readonly property string topLayer: activeLayer

    // Memoria de foco por capa: { [layerName]: zoneId | FocusZone }
    property var focusMemory: ({})
    property var registeredZones: []
    property var activeZone: null
    property var navigationManager: null

    signal layerPushed(string layer)
    signal layerPopped(string layer)

    function isLayerActive(layerName) {
        return layerName === activeLayer
    }

    function push(layerName) {
        if (!layerName || layerName === activeLayer)
            return

        if (activeZone) {
            const mem = Object.assign({}, focusMemory)
            mem[activeLayer] = activeZone.zoneId !== "" ? activeZone.zoneId : activeZone
            focusMemory = mem
        }

        stack = stack.concat([layerName])
        _restoreFocusForLayer(layerName)
        layerPushed(layerName)
    }

    function pop() {
        if (stack.length <= 1)
            return false

        const removed = stack[stack.length - 1]
        stack = stack.slice(0, -1)
        _restoreFocusForLayer(activeLayer)
        layerPopped(removed)
        return true
    }

    function reset() {
        stack = [baseLayer]
        focusMemory = ({})
        _restoreFocusForLayer(baseLayer)
    }

    function registerZone(zone) {
        if (!zone || registeredZones.indexOf(zone) !== -1)
            return

        registeredZones = registeredZones.concat([zone])

        if (zone.layerName === activeLayer && !activeZone && _isZoneFocusable(zone)) {
            focusZone(zone)
        }
    }

    function unregisterZone(zone) {
        const idx = registeredZones.indexOf(zone)
        if (idx === -1)
            return

        const next = registeredZones.slice()
        next.splice(idx, 1)
        registeredZones = next

        if (activeZone === zone) {
            activeZone = null
            _restoreFocusForLayer(activeLayer)
        }
    }

    function focusZone(zone) {
        if (!_isZoneFocusable(zone) || !isLayerActive(zone.layerName))
            return false

        activeZone = zone
        const mem = Object.assign({}, focusMemory)
        mem[activeLayer] = zone.zoneId !== "" ? zone.zoneId : zone
        focusMemory = mem
        return true
    }

    function focusZoneById(zoneId, layerName) {
        const targetLayer = layerName ?? activeLayer
        const zone = _findZoneById(zoneId, targetLayer)
        return zone ? focusZone(zone) : false
    }

    function handleAction(action, payload) {
        if (!activeZone || !isLayerActive(activeZone.layerName) || !activeZone.enabled || !activeZone.visible)
            return false

        switch (action) {
        case "I.Dpad.Up":
            return _navigate("up")
        case "I.Dpad.Down":
            return _navigate("down")
        case "I.Dpad.Left":
            return _navigate("left")
        case "I.Dpad.Right":
            return _navigate("right")
        case "I.ActionOption.L":
            return activeZone.cycleSubItem(-1)
        case "I.ActionOption.R":
            return activeZone.cycleSubItem(1)
        case "I.Accept":
            return activeZone.activate()
        case "I.Action":
            return activeZone.triggerSecondary()
        case "I.Select":
            return activeZone.requestExpand()
        default:
            return false
        }
    }

    function _navigate(direction) {
        if (!activeZone)
            return false

        const target = activeZone.targetForDirection(direction)
        if (target) {
            const resolved = typeof target === "string" ? _findZoneById(target, activeLayer) : target
            if (resolved && focusZone(resolved))
                return true
        }

        activeZone.dpadUnhandled(direction)
        return false
    }

    function _restoreFocusForLayer(layerName) {
        const remembered = focusMemory[layerName]
        if (remembered) {
            const zone = typeof remembered === "string" ? _findZoneById(remembered, layerName) : remembered
            if (_isZoneFocusable(zone) && zone.layerName === layerName) {
                activeZone = zone
                return
            }
        }

        for (let i = 0; i < registeredZones.length; i++) {
            const candidate = registeredZones[i]
            if (candidate && candidate.layerName === layerName && _isZoneFocusable(candidate)) {
                activeZone = candidate
                return
            }
        }

        activeZone = null
    }

    function _findZoneById(zoneId, layerName) {
        if (!zoneId)
            return null

        for (let i = 0; i < registeredZones.length; i++) {
            const zone = registeredZones[i]
            if (zone && zone.zoneId === zoneId && (!layerName || zone.layerName === layerName))
                return zone
        }
        return null
    }

    function _isZoneFocusable(zone) {
        return Boolean(zone && zone.enabled && zone.visible)
    }
}
