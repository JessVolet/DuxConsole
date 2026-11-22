import QtQuick

QtObject {
    id: manager

    property string baseLayer: "dashboard"
    property var stack: [baseLayer]
    readonly property string activeLayer: stack.length > 0 ? stack[stack.length - 1] : baseLayer
    readonly property string topLayer: activeLayer

    // Memoria de foco por capa: { [layerName]: zoneId | FocusZone }
    property var focusMemory: ({})
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

        if (activeZone && activeZone.layerName === activeLayer) {
            const mem = Object.assign({}, focusMemory)
            mem[activeLayer] = activeZone.zoneId !== "" ? activeZone.zoneId : activeZone
            focusMemory = mem
        }

        activeZone = null
        stack = stack.concat([layerName])
        layerPushed(layerName)
    }

    function pop() {
        if (stack.length <= 1)
            return false

        const removed = stack[stack.length - 1]
        activeZone = null
        stack = stack.slice(0, -1)
        layerPopped(removed)
        return true
    }

    function reset() {
        activeZone = null
        stack = [baseLayer]
        focusMemory = ({})
    }

    function setActiveZone(zone) {
        if (!zone) {
            activeZone = null
            return false
        }
        if (!zone.enabled || !zone.visible || !isLayerActive(zone.layerName))
            return false
        activeZone = zone
        return true
    }

    function focusZone(zone) {
        if (!setActiveZone(zone))
            return false

        const mem = Object.assign({}, focusMemory)
        mem[activeLayer] = zone.zoneId !== "" ? zone.zoneId : zone
        focusMemory = mem
        return true
    }

    function rememberedZoneRef(layerName) {
        return focusMemory[layerName] ?? null
    }
}
