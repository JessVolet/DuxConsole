pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../components/widgets/audio"
import "../../core/interaction"

TestCase {
    id: test
    name: "AudioCarousel"
    width: 700
    height: 700
    visible: true
    when: windowShown
    LayerManager { id: layers; navigationManager: nav }
    NavigationManager { id: nav; layerManager: layers; rootContainer: test }
    AudioTargetCarousel {
        id: widget
        width: 500
        height: 600
        orientation: Qt.Vertical
        layerManager: layers
        navigationManager: nav
        zoneId: "test-audio"
    }
    function entry(key) { return {key:key, kind:"app", title:key, subtitle:"", volume:0.4, maxVolume:1, muted:false, pinned:false, active:false, hasOptions:false, canSetVolume:true, canMute:true} }
    SignalSpy { id: activation; target: widget; signalName: "activationRequested" }
    function test_browseDoesNotActivate() {
        const a = entry("a"), b = entry("b")
        a.kind = "output"; b.kind = "output"
        widget.model = [a, b]
        widget.focusZone.cycleSubItem(1)
        compare(activation.count, 0)
        widget.focusZone.activate()
        compare(activation.count, 1)
        compare(activation.signalArguments[0][0], "b")
    }
    function test_counts() {
        const view = findChild(widget, "audio-target-carousel")
        for (const count of [0, 1, 2, 5, 6]) {
            widget.model = Array.from({length:count}, (_, index) => entry(String(index)))
            compare(view.count, count)
            compare(view.visibleItemCount, Math.min(5, count))
        }
    }
    function test_singleItemStaysCentered() {
        const view = findChild(widget, "audio-target-carousel")
        widget.model = [entry("solo")]
        tryVerify(() => view.selectedItem !== null)
        const item = view.selectedItem
        const center = item.mapToItem(view, item.width / 2, item.height / 2)
        fuzzyCompare(center.x, view.width / 2, 1)
        fuzzyCompare(center.y, view.height / 2, 1)
    }
    function test_cyclicWrapKeepsSelection() {
        const view = findChild(widget, "audio-target-carousel")
        widget.cyclic = true
        widget.model = [entry("a"), entry("b"), entry("c")]
        widget.focusZone.currentSubIndex = 0
        wait(20)
        compare(view.wrapIndex(view._viewIndex), 0)
        widget.focusZone.cycleSubItem(-1)
        wait(100)
        compare(widget.selectedKey, "c")
        compare(view.selectedIndex, 2)
        compare(view.wrapIndex(view._viewIndex), 2)
        compare(view.itemDataAt(view.selectedIndex).key, "c")
        widget.cyclic = false
        widget.model = []
        widget.focusZone.currentSubIndex = 0
    }
    function test_selectionAcrossModelChange() {
        widget.model = [entry("a"), entry("b"), entry("c")]
        nav.ensureFocus("dashboard")
        widget.focusZone.cycleSubItem(1)
        compare(widget.selectedKey, "b")
        widget.model = [entry("c"), entry("b")]
        compare(widget.selectedKey, "b")
        widget.model = [entry("c")]
        compare(widget.selectedKey, "c")
        widget.model = []
        compare(widget.selectedTarget, null)
    }
}
