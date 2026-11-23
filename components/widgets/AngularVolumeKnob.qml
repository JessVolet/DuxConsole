import QtQuick
import "../../core/interaction"
import "../primitives/controls"

VolumeKnob {
    id: knob
    property var inputConfig: null
    function handleStick(x, y) { controller.handleStick(x, y) }
    function resetInput() { controller.reset() }
    AngularKnobController {
        id: controller
        enabled: knob.enabled
        targetKey: knob.targetKey
        engageRadius: knob.inputConfig?.engageRadius ?? 0.30
        releaseRadius: knob.inputConfig?.releaseRadius ?? 0.20
        angularEpsilon: knob.inputConfig?.angularEpsilon ?? 1
        onFractionRequested: fraction => knob.valueRequested(knob.minimum + fraction * (knob.maximum - knob.minimum))
    }
}
