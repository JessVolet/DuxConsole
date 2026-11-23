import QtQuick
import Quickshell.Services.Mpris

Item {
    id: service
    visible: false

    property string preferredIdentity: ""

    readonly property var players: Mpris.players.values ?? []
    readonly property int playerCount: players.length

    readonly property var activePlayer: {
        if (!players.length)
            return null
        if (preferredIdentity !== "") {
            const preferred = players.find(p => p && p.identity === preferredIdentity)
            if (preferred)
                return preferred
        }
        const playing = players.find(p => p && p.isPlaying)
        return playing ?? players[0] ?? null
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property string identity: activePlayer?.identity ?? ""
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool isPlaying: Boolean(activePlayer?.isPlaying)

    readonly property real length: Math.max(0, Number(activePlayer?.length ?? 0))
    property real position: Math.max(0, Number(activePlayer?.position ?? 0))
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    readonly property bool canGoNext: Boolean(activePlayer?.canGoNext)
    readonly property bool canGoPrevious: Boolean(activePlayer?.canGoPrevious)
    readonly property bool canTogglePlaying: Boolean(activePlayer?.canTogglePlaying)
    readonly property bool canSeek: Boolean(activePlayer?.canSeek && activePlayer?.positionSupported)

    readonly property bool shuffleSupported: Boolean(activePlayer?.shuffleSupported)
    readonly property bool shuffle: Boolean(activePlayer?.shuffle)
    readonly property bool loopSupported: Boolean(activePlayer?.loopSupported)
    readonly property int loopState: Number(activePlayer?.loopState ?? MprisLoopState.None)
    readonly property bool volumeSupported: Boolean(activePlayer?.volumeSupported)
    readonly property real volume: Math.max(0, Math.min(1, Number(activePlayer?.volume ?? 0)))

    function syncPosition() {
        position = Math.max(0, Number(activePlayer?.position ?? 0))
    }

    onActivePlayerChanged: syncPosition()

    Connections {
        target: service.activePlayer
        function onPositionChanged() {
            service.syncPosition()
        }
        function onTrackTitleChanged() {
            service.syncPosition()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: service.isPlaying && service.length > 0
        onTriggered: {
            if (service.activePlayer?.positionSupported)
                service.activePlayer.positionChanged()
            else
                service.position = Math.min(service.length, service.position + 1)
        }
    }

    function togglePlaying() {
        if (activePlayer && canTogglePlaying)
            activePlayer.togglePlaying()
    }

    function next() {
        if (activePlayer && canGoNext)
            activePlayer.next()
    }

    function previous() {
        if (activePlayer && canGoPrevious)
            activePlayer.previous()
    }

    function seekBy(deltaSeconds) {
        if (!activePlayer || !canSeek)
            return
        activePlayer.seek(deltaSeconds)
        position = Math.max(0, Math.min(length, position + deltaSeconds))
    }

    function seekToRatio(ratio) {
        if (!activePlayer || !canSeek || length <= 0)
            return
        const target = Math.max(0, Math.min(length, ratio * length))
        activePlayer.seek(target - position)
        position = target
    }

    function matchesTrack(lyricsTrack) {
        if (!hasPlayer || title === "")
            return false
        if (!lyricsTrack || !lyricsTrack.title)
            return true
        return String(lyricsTrack.title).trim().toLowerCase() === title.trim().toLowerCase()
    }

    function toggleShuffle() {
        if (activePlayer && shuffleSupported)
            activePlayer.shuffle = !activePlayer.shuffle
    }

    function cycleLoop() {
        if (!activePlayer || !loopSupported)
            return
        if (activePlayer.loopState === MprisLoopState.None)
            activePlayer.loopState = MprisLoopState.Playlist
        else if (activePlayer.loopState === MprisLoopState.Playlist)
            activePlayer.loopState = MprisLoopState.Track
        else
            activePlayer.loopState = MprisLoopState.None
    }

    function adjustVolume(delta) {
        if (!activePlayer || !volumeSupported)
            return
        activePlayer.volume = Math.max(0, Math.min(1, activePlayer.volume + delta))
    }

    function cyclePlayer() {
        if (players.length < 2)
            return
        const idx = players.indexOf(activePlayer)
        const nextPlayer = players[(idx + 1) % players.length]
        if (nextPlayer)
            preferredIdentity = nextPlayer.identity ?? ""
    }
}
