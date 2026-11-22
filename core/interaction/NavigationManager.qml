import QtQuick

QtObject {
    id: nav

    property var layerManager: null
    property Item rootContainer: null
    property var zones: []

    readonly property var activeHints: {
        const lm = layerManager
        const zone = lm ? lm.activeZone : null
        const zoneHints = (zone && Array.isArray(zone.actionHints)) ? zone.actionHints : []

        const result = []
        const seen = ({})

        for (let i = 0; i < zoneHints.length; i++) {
            const h = zoneHints[i]
            if (h && h.action && !seen[h.action]) {
                seen[h.action] = true
                result.push(h)
            }
        }

        if (!seen["I.Refuse"]) {
            result.push({
                action: "I.Refuse",
                labelKey: "hints.back",
                fallback: "Back / Close"
            })
        }

        return result
    }

    property Connections _layerConnections: Connections {
        target: nav.layerManager ?? null
        function onTopLayerChanged() {
            if (nav.layerManager)
                nav.ensureFocus(nav.layerManager.topLayer)
        }
    }

    function registerZone(zone) {
        if (!zone || zones.indexOf(zone) !== -1)
            return

        zones = zones.concat([zone])
        if (layerManager)
            ensureFocus(layerManager.topLayer)
    }

    function unregisterZone(zone) {
        const idx = zones.indexOf(zone)
        if (idx === -1)
            return

        const next = zones.slice()
        next.splice(idx, 1)
        zones = next

        if (layerManager && layerManager.activeZone === zone) {
            layerManager.setActiveZone(null)
            ensureFocus(layerManager.topLayer)
        }
    }

    function ensureFocus(layerName) {
        if (!layerManager)
            return false

        const targetLayer = layerName || layerManager.topLayer
        if (!layerManager.isLayerActive(targetLayer))
            return false

        // 1. Restaurar foco recordado válido de la capa antes que defaultFocus
        const rememberedRef = layerManager.rememberedZoneRef(targetLayer)
        if (rememberedRef) {
            const rememberedZone = typeof rememberedRef === "string"
                ? _findZoneById(rememberedRef, targetLayer)
                : rememberedRef
            if (rememberedZone && rememberedZone.layerName === targetLayer && _isFocusable(rememberedZone)) {
                if (layerManager.activeZone === rememberedZone)
                    return true
                return layerManager.setActiveZone(rememberedZone)
            }
        }

        // 2. Buscar defaultFocus o fallback arriba-izquierda entre zonas de la capa
        let defaultCandidate = null
        let topLeftCandidate = null
        let bestTopLeftScore = Infinity

        for (let i = 0; i < zones.length; i++) {
            const z = zones[i]
            if (!z || z.layerName !== targetLayer || !_isFocusable(z))
                continue

            if (z.defaultFocus && !defaultCandidate)
                defaultCandidate = z

            const r = _zoneRect(z)
            const score = r.y * 2 + r.x
            if (score < bestTopLeftScore) {
                bestTopLeftScore = score
                topLeftCandidate = z
            }
        }

        const chosen = defaultCandidate ?? topLeftCandidate
        if (!chosen) {
            layerManager.setActiveZone(null)
            return false
        }

        if (layerManager.activeZone === chosen)
            return true
        return layerManager.setActiveZone(chosen)
    }

    function move(direction) {
        if (!layerManager)
            return false

        const current = layerManager.activeZone
        if (!current || !_isFocusable(current))
            return ensureFocus(layerManager.topLayer)

        const overrideTarget = current.targetForDirection(direction)
        if (overrideTarget) {
            const resolved = typeof overrideTarget === "string"
                ? _findZoneById(overrideTarget, layerManager.topLayer)
                : overrideTarget
            if (resolved && _isFocusable(resolved) && resolved.layerName === layerManager.topLayer)
                return layerManager.focusZone(resolved)
        }

        const srcRect = _zoneRect(current)
        const cx = srcRect.x + srcRect.width / 2
        const cy = srcRect.y + srcRect.height / 2

        let bestZone = null
        let bestScore = Infinity

        for (let i = 0; i < zones.length; i++) {
            const candidate = zones[i]
            if (!candidate || candidate === current)
                continue
            if (candidate.layerName !== layerManager.topLayer || !_isFocusable(candidate))
                continue

            const dstRect = _zoneRect(candidate)
            const nx = dstRect.x + dstRect.width / 2
            const ny = dstRect.y + dstRect.height / 2
            const dx = nx - cx
            const dy = ny - cy

            let primary = 0
            let secondary = 0

            switch (direction) {
            case "up":
                if (dy >= -4 || Math.abs(dx) > Math.abs(dy) * 2.0)
                    continue
                primary = -dy
                secondary = Math.abs(dx)
                break
            case "down":
                if (dy <= 4 || Math.abs(dx) > Math.abs(dy) * 2.0)
                    continue
                primary = dy
                secondary = Math.abs(dx)
                break
            case "left":
                if (dx >= -4 || Math.abs(dy) > Math.abs(dx) * 2.0)
                    continue
                primary = -dx
                secondary = Math.abs(dy)
                break
            case "right":
                if (dx <= 4 || Math.abs(dy) > Math.abs(dx) * 2.0)
                    continue
                primary = dx
                secondary = Math.abs(dy)
                break
            default:
                continue
            }

            const score = primary + secondary * 2.5
            if (score < bestScore) {
                bestScore = score
                bestZone = candidate
            }
        }

        if (bestZone)
            return layerManager.focusZone(bestZone)

        current.dpadUnhandled(direction)
        return false
    }

    function handleAction(action, payload) {
        if (!layerManager)
            return false

        const zone = layerManager.activeZone
        if (!zone || !layerManager.isLayerActive(zone.layerName) || !_isFocusable(zone)) {
            ensureFocus(layerManager.topLayer)
            return false
        }

        switch (action) {
        case "I.Dpad.Up":
            return move("up")
        case "I.Dpad.Down":
            return move("down")
        case "I.Dpad.Left":
            return move("left")
        case "I.Dpad.Right":
            return move("right")
        case "I.ActionOption.L":
            return zone.subItemCount > 0 ? zone.cycleSubItem(-1) : false
        case "I.ActionOption.R":
            return zone.subItemCount > 0 ? zone.cycleSubItem(1) : false
        case "I.Accept":
            return zone.activate()
        case "I.Action":
            return zone.triggerSecondary()
        case "I.Select":
            return zone.expandable ? zone.requestExpand() : false
        default:
            return false
        }
    }

    function _zoneRect(zone) {
        if (!rootContainer)
            return Qt.rect(zone.x, zone.y, zone.width, zone.height)
        return zone.mapToItem(rootContainer, 0, 0, zone.width, zone.height)
    }

    function _findZoneById(zoneId, layerName) {
        if (!zoneId)
            return null
        for (let i = 0; i < zones.length; i++) {
            const z = zones[i]
            if (z && z.zoneId === zoneId && (!layerName || z.layerName === layerName))
                return z
        }
        return null
    }

    function _isFocusable(zone) {
        return Boolean(zone && zone.enabled && zone.visible)
    }
}
