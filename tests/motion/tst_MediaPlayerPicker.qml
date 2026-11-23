pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../components/widgets"
import "../../core/interaction"
import "../../services"

TestCase {
    id: test
    name: "MediaPlayerPicker"
    width: 1000
    height: 700
    visible: true
    when: windowShown
    QtObject {
        id: style
        property real skewAngle: -8
        property color errorColor: "#B00020"
        property color accentColor: "white"
        function surfaceColor(role, opacity) { return "black" }
        function onSurfaceColor(role) { return "white" }
        function borderColor(role) { return "gray" }
        function disabledSurfaceColor(role) { return "black" }
    }
    MediaPlayerSelection { id: selection }
    QtObject {
        id: service
        property var players: [{ dbusName: "one", identity: "Player", trackTitle: "Track", isPlaying: true }]
        readonly property var activePlayer: selection.activePlayer
        readonly property string pinnedPlayerKey: selection.pinnedKey
        readonly property string selectedPlayerKey: selection.selectedKey
        function playerKey(p) { return selection.key(p) }
        function selectPlayer(p) { selection.select(p) }
        function useAutomaticPlayer() { selection.automatic() }
        function togglePlayerPin(p) { selection.togglePin(p) }
    }
    LayerManager { id: layers; navigationManager: nav }
    NavigationManager { id: nav; layerManager: layers; rootContainer: test }
    Item { id: origin; x: 500; y: 400; width: 100; height: 40 }
    FocusZone { id: baseZone; zoneId: "base"; layerManager: layers; navigationManager: nav; width: 100; height: 100; defaultFocus: true }
    MediaPlayerPicker {
        id: picker
        sourceItem: origin
        mediaService: service
        layerManager: layers
        navigationManager: nav
        styleTokens: style
    }
    function test_openChooseAndRestore() {
        selection.players = service.players
        layers.focusZone(baseZone)
        layers.push(picker.layerName)
        tryVerify(() => picker.visible && layers.activeZone !== null)
        verify(baseZone.inert)
        compare(layers.activeZone.layerName, picker.layerName)
        picker.pin(1)
        compare(selection.pinnedKey, "one")
        picker.choose(1)
        tryCompare(layers, "activeZone", baseZone)
        compare(layers.topLayer, "dashboard")
    }
}
