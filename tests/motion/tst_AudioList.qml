pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../components/widgets/audio"
import "../../core/interaction"

TestCase {
    id: test
    name: "AudioList"
    width: 700
    height: 700
    visible: true
    when: windowShown

    LayerManager { id: layers; navigationManager: nav }
    NavigationManager { id: nav; layerManager: layers; rootContainer: test }

    AudioTargetList {
        id: list
        width: 420
        height: 400
        zoneId: "test-audio-list"
        layerManager: layers
        navigationManager: nav
    }
    SignalSpy { id: activation; target: list; signalName: "activationRequested" }

    function entry(key, kind) {
        return { key: key, kind: kind, title: key, subtitle: "", appId: "", volume: 0.5, maxVolume: 1,
                 muted: false, pinned: false, active: false, hasOptions: true,
                 canSetVolume: true, canMute: true }
    }

    function test_externalKeySyncsIndex() {
        list.model = [entry("a", "output"), entry("b", "output"), entry("c", "output")]
        list.selectedKey = "c"
        compare(list.selectedTarget?.key ?? "", "c")
        compare(list.selectedIndex, 2)
        compare(list.focusZone.currentSubIndex, 2)
        compare(list.selectedItem?.title ?? "", "c")
    }

    function test_cyclingSelectsAndActivatesDevices() {
        list.model = [entry("a", "output"), entry("b", "output")]
        list.selectedKey = "a"
        list.focusZone.currentSubIndex = 0
        nav.ensureFocus("dashboard")
        list.focusZone.cycleSubItem(1)
        compare(list.selectedKey, "b")
        activation.clear()
        list.focusZone.activate()
        compare(activation.count, 1)
        compare(activation.signalArguments[0][0], "b")
    }

    function test_appsDoNotActivate() {
        list.model = [entry("app1", "app")]
        list.selectedKey = "app1"
        list.focusZone.currentSubIndex = 0
        nav.ensureFocus("dashboard")
        activation.clear()
        list.focusZone.activate()
        compare(activation.count, 0)
    }
}
