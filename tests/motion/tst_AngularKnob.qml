import QtQuick
import QtTest
import "../../core/interaction"

TestCase {
    name: "AngularKnob"
    AngularKnobController { id: controller; targetKey: "one" }
    SignalSpy { id: spy; target: controller; signalName: "fractionRequested" }
    function init() { controller.enabled = true; controller.targetKey = "one"; controller.reset(); spy.clear(); controller.handleStick(0, 0) }
    function test_absoluteAndRelease() {
        controller.handleStick(-0.7, 0.7)
        fuzzyCompare(spy.signalArguments[0][0], 0, 0.001)
        controller.handleStick(0, -1)
        compare(spy.signalArguments[1][0], 0.5)
        controller.handleStick(0.7, 0.7)
        fuzzyCompare(spy.signalArguments[2][0], 1, 0.001)
        controller.handleStick(0.05, 0.04)
        compare(spy.count, 3)
    }
    function test_gapAndTargetRequireNeutral() {
        controller.handleStick(0.7, 0.7)
        controller.handleStick(0, 1)
        controller.handleStick(-0.7, 0.7)
        compare(spy.count, 1)
        controller.handleStick(0, 0)
        controller.handleStick(0, -1)
        compare(spy.count, 2)
        controller.targetKey = "two"
        controller.handleStick(1, 0)
        compare(spy.count, 2)
    }
    function test_invalidAndDisabled() {
        controller.handleStick(NaN, 0)
        controller.enabled = false
        controller.handleStick(0, -1)
        compare(spy.count, 0)
    }
    function test_restOffsetAboveReleaseDoesNotOverwrite() {
        // Measured right-stick offset of the test pad is ~0.21 radial; with a
        // release radius below it, spring-back would emit an unintended angle.
        controller.engageRadius = 0.40
        controller.releaseRadius = 0.30
        controller.reset()
        controller.handleStick(0, 0)
        controller.handleStick(0, -1)
        compare(spy.count, 1)
        controller.handleStick(-0.207, 0.03)
        compare(spy.count, 1)
        controller.engageRadius = 0.30
        controller.releaseRadius = 0.20
    }
}
