import QtQuick
import "AngularKnobMath.js" as KnobMath

QtObject {
    id: controller
    property string targetKey: ""
    property bool enabled: true
    property real engageRadius: 0.30
    property real releaseRadius: 0.20
    property real angularEpsilon: 1
    property bool armed: false
    property bool engaged: false
    property real lastFraction: -1
    signal fractionRequested(real fraction)

    function reset() { armed = false; engaged = false; lastFraction = -1 }
    onTargetKeyChanged: reset()
    onEnabledChanged: reset()

    function handleStick(x, y) {
        if (!enabled || targetKey === "" || !Number.isFinite(x) || !Number.isFinite(y)) return
        const radius = Math.hypot(x, y)
        const release = Math.max(0, Math.min(0.95, releaseRadius))
        const engage = Math.max(release + 0.01, Math.min(1, engageRadius))
        if (radius <= release) { armed = true; engaged = false; lastFraction = -1; return }
        if (!armed || (!engaged && radius < engage)) return
        const next = KnobMath.fraction(x, y)
        if (next < 0) { reset(); return }
        engaged = true
        if (lastFraction >= 0 && Math.abs(next - lastFraction) * 270 < angularEpsilon) return
        lastFraction = next
        fractionRequested(next)
    }
}
