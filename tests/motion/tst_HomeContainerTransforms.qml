pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../core/interaction"
import "../../components/widgets"
import "../../screens/modals"

TestCase {
    id: test
    name: "HomeContainerTransforms"
    width: 1200
    height: 760
    visible: true
    when: windowShown

    QtObject {
        id: motionTokens
        property int durationFast: 40
        property int durationNormal: 60
        property int easingSnappy: Easing.OutCubic
        property int easingSmooth: Easing.InOutCubic
        property int containerTransformDuration: 80
        property int containerTransformEasing: Easing.OutCubic
        property int marqueePauseStartDuration: 0
        property int marqueePauseEndDuration: 0
        property int marqueeReturnDuration: 0
        property int marqueeEasing: Easing.InOutSine
        property int visualizerBarDuration: 40
        property int visualizerEasing: Easing.OutQuad
        property bool animationsEnabled: true
        property var containerTransform: ({})
        function marqueeDurationFor(px) { return 0 }
    }

    QtObject {
        id: styleTokens
        property real skewAngle: -8
        property color errorColor: "#B00020"
        property color accentColor: "#A855F7"
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
        property string iconColorMode: "dms"
        property string iconStyle: "filled"
        property bool iconShowBackdrop: true
        function surfaceColor(role) { return role === "chrome" ? "#F2F4F8" : "#161822" }
        function disabledSurfaceColor(role) { return "#1D202B" }
        function onSurfaceColor(role) { return role === "chrome" ? "#14161D" : "#F2F4F8" }
        function disabledOnSurfaceColor(role) { return "#64748B" }
        function borderColor(role) { return "#303445" }
    }

    QtObject {
        id: iconsPad
        function resolve(action) {
            return { type: "key", label: action, source: "", isMonochrome: true, colorMode: "dms", style: "filled", showBackdrop: true }
        }
        function resolveMediaIcon(name) { return "" }
    }

    QtObject {
        id: fakeWindowManager
        property var windows: [
            { id: 10, title: "Code", appId: "code", appName: "Code", workspaceIndex: 1, output: "DP-1", isFocused: true, isFullscreen: false },
            { id: 20, title: "Terminal", appId: "foot", appName: "Foot", workspaceIndex: 1, output: "DP-1", isFocused: false, isFullscreen: false }
        ]
        property var outputs: [{ name: "DP-1" }]
        property var workspaces: [{ id: 1, idx: 1, name: "Main", output: "DP-1" }]
        function windowById(id) {
            return windows.find(w => w.id === id) ?? null
        }
    }

    QtObject {
        id: fakeMediaService
        property bool hasPlayer: true
        property bool isPlaying: true
        property string identity: "Spotifast"
        property string title: "Test Track"
        property string artist: "Artist"
        property string album: "Album"
        property string artUrl: ""
        property real position: 10
        property real length: 120
        property real progress: 10 / 120
        property bool canGoNext: true
        property bool canGoPrevious: true
        property bool canTogglePlaying: true
        property bool canSeek: true
        property bool shuffleSupported: true
        property bool shuffle: false
        property bool loopSupported: true
        property int loopState: 0
        property bool volumeSupported: true
        property real volume: 0.7
        property var players: []
        property var activePlayer: null
        function matchesTrack(t) { return true }
    }

    LayerManager {
        id: layers
        navigationManager: nav
    }
    NavigationManager {
        id: nav
        layerManager: layers
        rootContainer: stage
    }

    Item {
        id: stage
        anchors.fill: parent

        Item {
            id: cardProxy
            x: 160
            y: 480
            width: 180
            height: 150
        }

        CarouselActionAnchor {
            id: anchorBtn
            targetItem: cardProxy
            iconsPadManager: iconsPad
            styleTokens: styleTokens
            hidden: winModal.transformActive
        }

        MediaPlayerCard {
            id: miniMedia
            x: 820
            y: 620
            width: 340
            height: 100
            defaultFocus: true
            hiddenVisual: mediaModal.transformActive
            mediaService: fakeMediaService
            layerManager: layers
            navigationManager: nav
            styleTokens: styleTokens
            motionTokens: motionTokens
        }

        WindowOptionsModal {
            id: winModal
            sourceItem: anchorBtn.buttonItem
            windowManager: fakeWindowManager
            layerManager: layers
            navigationManager: nav
            styleTokens: styleTokens
            motionTokens: motionTokens
            iconsPadManager: iconsPad
            targetWindowId: 10
        }

        MediaPlayerModal {
            id: mediaModal
            sourceItem: miniMedia
            mediaService: fakeMediaService
            layerManager: layers
            navigationManager: nav
            iconsPadManager: iconsPad
            styleTokens: styleTokens
            motionTokens: motionTokens
        }
    }

    function init() {
        layers.reset()
        nav.ensureFocus("dashboard")
        wait(120)
    }

    function test_windowOptionsMorphLocksIdAndRestoresFocus() {
        compare(layers.activeZone, miniMedia.focusZone)
        layers.push("modal")
        verify(winModal.transformActive)
        // Changing targetWindowId during transition must not change lockedWindowId
        winModal.targetWindowId = 20
        wait(140)
        verify(layers.activeZone !== null)
        compare(layers.activeZone.layerName, "modal")
        // Disappearing window shows safe empty state without crashing
        fakeWindowManager.windows = []
        wait(20)
        // Closing with pop restores exact origin focus to MediaPlayerCard
        layers.pop()
        tryCompare(layers, "topLayer", "dashboard")
        tryCompare(layers, "activeZone", miniMedia.focusZone)
        tryVerify(() => !winModal.transformActive)
        fakeWindowManager.windows = [
            { id: 10, title: "Code", appId: "code", appName: "Code", workspaceIndex: 1, output: "DP-1", isFocused: true, isFullscreen: false },
            { id: 20, title: "Terminal", appId: "foot", appName: "Foot", workspaceIndex: 1, output: "DP-1", isFocused: false, isFullscreen: false }
        ]
        winModal.targetWindowId = 10
    }

    function test_windowOptionsScrollsLongWorkspaceList() {
        const many = []
        for (let i = 1; i <= 30; ++i)
            many.push({ id: i, idx: i, name: "WS" + i, output: "DP-1" })
        fakeWindowManager.workspaces = many
        layers.push("modal")
        verify(winModal.transformActive)
        wait(160)
        const panel = findChild(winModal, "window-actions-panel")
        verify(panel)
        panel._switchView("workspaces")
        wait(80)
        const viewport = findChild(panel, "window-actions-viewport")
        verify(viewport)
        verify(panel.availableHeight > 0)
        verify(panel.implicitHeight <= panel.availableHeight + 1)
        verify(viewport.contentHeight > viewport.height)
        const last = findChild(panel, "win-ws-29")
        verify(last)
        verify(last.requestZoneFocus())
        wait(40)
        const pos = last.mapToItem(viewport.contentItem, 0, 0)
        verify(pos.y >= viewport.contentY - 1)
        verify(pos.y + last.height <= viewport.contentY + viewport.height + 1)
        layers.pop()
        tryVerify(() => !winModal.transformActive)
        fakeWindowManager.workspaces = [{ id: 1, idx: 1, name: "Main", output: "DP-1" }]
    }

    function test_mediaCardMorphUpLeftKeepsMiniMountedAndRestoresFocus() {
        compare(layers.activeZone, miniMedia.focusZone)
        layers.push("media-player")
        verify(mediaModal.transformActive)
        // Mini card stays mounted (visible: true) while visually hidden (opacity: 0)
        verify(miniMedia.visible)
        compare(miniMedia.opacity, 0)
        wait(140)
        compare(layers.activeZone.layerName, "media-player")
        layers.pop()
        tryCompare(layers, "topLayer", "dashboard")
        tryCompare(layers, "activeZone", miniMedia.focusZone)
        tryVerify(() => !mediaModal.transformActive)
        compare(miniMedia.opacity, 1)
    }
}
