import QtQuick

Item {
    id: zone

    property string zoneId: ""
    property string layerName: "dashboard"
    property var layerManager: null
    property var navigationManager: null
    property bool defaultFocus: false
    property bool expandable: false
    property var actionHints: []

    // Regla inert: bloqueada cuando su capa no está activa en la pila
    readonly property bool inert: layerManager ? !layerManager.isLayerActive(layerName) : false
    readonly property bool active: layerManager ? (layerManager.activeZone === zone && !inert) : false

    // Navegación D-Pad hacia otras FocusZone (referencia directa o zoneId)
    property var navUp: null
    property var navDown: null
    property var navLeft: null
    property var navRight: null

    // Ciclo rápido LT / RT para sub-ítems internos
    property int subItemCount: 0
    property int currentSubIndex: 0
    property bool wrapSubItems: true

    // Geometría visual para el FocusRing global
    property real ringRadius: 12
    property real ringPadding: 0

    signal activated(int subIndex)
    signal secondaryTriggered(int subIndex)
    signal optionsTriggered(int subIndex)
    signal expandRequested(int subIndex)
    signal subItemCycled(int newIndex, int delta)
    signal dpadUnhandled(string direction)

    function requestZoneFocus() {
        if (inert || !enabled || !visible || !layerManager)
            return false
        return layerManager.focusZone(zone)
    }

    function cycleSubItem(delta) {
        if (inert || subItemCount <= 0)
            return false

        let next = currentSubIndex + delta
        if (wrapSubItems) {
            next = ((next % subItemCount) + subItemCount) % subItemCount
        } else {
            next = Math.max(0, Math.min(subItemCount - 1, next))
        }

        if (next === currentSubIndex)
            return false

        currentSubIndex = next
        subItemCycled(next, delta)
        return true
    }

    function activate() {
        if (inert)
            return false
        activated(currentSubIndex)
        return true
    }

    function triggerSecondary() {
        if (inert)
            return false
        secondaryTriggered(currentSubIndex)
        return true
    }

    function triggerOptions() {
        if (inert)
            return false
        optionsTriggered(currentSubIndex)
        return true
    }

    function requestExpand() {
        if (inert)
            return false
        expandRequested(currentSubIndex)
        return true
    }

    function targetForDirection(direction) {
        switch (direction) {
        case "up":
            return navUp
        case "down":
            return navDown
        case "left":
            return navLeft
        case "right":
            return navRight
        default:
            return null
        }
    }

    function _syncRegistration() {
        const nav = navigationManager ?? layerManager?.navigationManager
        if (nav)
            nav.registerZone(zone)
    }

    onLayerManagerChanged: _syncRegistration()
    onNavigationManagerChanged: _syncRegistration()

    onVisibleChanged: {
        if (visible) {
            const nav = navigationManager ?? layerManager?.navigationManager
            if (nav)
                nav.ensureFocus(layerName)
        }
    }

    onSubItemCountChanged: {
        if (subItemCount <= 0)
            currentSubIndex = 0
        else if (currentSubIndex < 0 || currentSubIndex >= subItemCount)
            currentSubIndex = ((currentSubIndex % subItemCount) + subItemCount) % subItemCount
    }

    Component.onCompleted: _syncRegistration()

    Component.onDestruction: {
        const nav = navigationManager ?? layerManager?.navigationManager
        if (nav)
            nav.unregisterZone(zone)
    }
}
