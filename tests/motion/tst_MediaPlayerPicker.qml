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
        property color m3Surface: "#130c0c"
        property color m3SurfaceLow: "#191111"
        property color m3SurfaceContainer: "#201717"
        property color m3SurfaceHigh: "#271d1d"
        property color m3SurfaceHighest: "#2e2323"
        property color m3OnSurface: "#f7e7e6"
        property color m3OnSurfaceVariant: "#b6a8a7"
        property color m3OutlineVariant: "#504645"
        property color m3Primary: "#fd9c97"
        property color m3OnPrimary: "#5f1f1e"
        property color m3SecondaryContainer: "#6b3836"
        property color m3OnSecondaryContainer: "#ffc1bd"
        function m3Alpha(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha) }
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
