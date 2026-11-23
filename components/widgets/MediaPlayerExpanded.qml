pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Common
import qs.Widgets
import qs.Services
import "../../core/interaction"
import "../primitives/buttons"
import "../primitives/meters"
import "../primitives/surfaces"
import "../primitives/text"

SlantedSurface {
    id: playerRoot

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var i18n: null
    property string layerName: "media-player"

    property bool showLyrics: true
    property int focusedOptionIndex: 0

    readonly property var lyricsCtrl: LyricsService.controller
    readonly property bool lyricsAvailable: Boolean(lyricsCtrl?.available)
    readonly property bool hasPlayer: Boolean(mediaService?.hasPlayer)
    readonly property bool isPlaying: Boolean(mediaService?.isPlaying)
    readonly property color accentColor: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property color fgColor: styleTokens ? styleTokens.onSurfaceColor("card") : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color mutedFg: Qt.alpha(fgColor, 0.72)

    readonly property var availableOptions: {
        const opts = []
        if (lyricsAvailable)
            opts.push("lyrics")
        if (mediaService?.shuffleSupported)
            opts.push("shuffle")
        if (mediaService?.loopSupported)
            opts.push("repeat")
        if ((mediaService?.playerCount ?? 0) > 1)
            opts.push("player")
        if (mediaService?.volumeSupported)
            opts.push("volume")
        return opts
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds || 0))
        const mins = Math.floor(total / 60)
        const secs = total % 60
        return mins + ":" + (secs < 10 ? "0" + secs : String(secs))
    }

    function optionIcon(optId) {
        if (optId === "lyrics") return Qt.resolvedUrl("../../assets/icons/media/lyrics.svg")
        if (optId === "shuffle") return Qt.resolvedUrl("../../assets/icons/media/shuffle.svg")
        if (optId === "repeat") {
            return (mediaService?.loopState ?? MprisLoopState.None) === MprisLoopState.Track
                ? Qt.resolvedUrl("../../assets/icons/media/repeat_one.svg")
                : Qt.resolvedUrl("../../assets/icons/media/repeat.svg")
        }
        if (optId === "player") return Qt.resolvedUrl("../../assets/icons/media/speaker_group.svg")
        if (optId === "volume") return Qt.resolvedUrl("../../assets/icons/media/volume_up.svg")
        return ""
    }

    function triggerOption(optId) {
        if (optId === "lyrics")
            showLyrics = !showLyrics
        else if (optId === "shuffle")
            mediaService?.toggleShuffle()
        else if (optId === "repeat")
            mediaService?.cycleLoop()
        else if (optId === "player")
            mediaService?.cyclePlayer()
        else if (optId === "volume")
            mediaService?.adjustVolume(0.1)
    }

    role: "card"
    skewAngle: -5
    radius: 24
    focused: modalZone.active

    backdrop: [
        // Fondo difuminado basado en la carátula, recortado al paralelogramo inclinado
        Image {
            id: backdropArt
            anchors.fill: parent
            source: playerRoot.mediaService?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            opacity: 0.45
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.85
                blurMax: 48
            }
        },
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.05, 0.06, 0.09, 0.68)
        }
    ]

    FocusZone {
        id: modalZone
        anchors.fill: parent
        zoneId: "media-player-expanded"
        layerName: playerRoot.layerName
        layerManager: playerRoot.layerManager
        navigationManager: playerRoot.navigationManager
        defaultFocus: true
        expandable: true
        showFocusRing: false
        subItemCount: 3
        currentSubIndex: 1
        wrapSubItems: false
        actionHints: {
            const list = [
                { action: "I.ActionSlide.L", labelKey: "media.prev", fallback: "Previous" },
                { action: "I.ActionSlide.R", labelKey: "media.next", fallback: "Next" },
                { action: "I.Action", labelKey: playerRoot.isPlaying ? "media.pause" : "media.play", fallback: playerRoot.isPlaying ? "Pause" : "Play" },
                { action: "I.ActionOption.L", labelKey: "media.seek_back", fallback: "-10s" },
                { action: "I.ActionOption.R", labelKey: "media.seek_forward", fallback: "+10s" }
            ]
            if (playerRoot.lyricsAvailable) {
                list.push({
                    action: "I.Select",
                    labelKey: playerRoot.showLyrics ? "media.show_art" : "media.show_lyrics",
                    fallback: playerRoot.showLyrics ? "Show cover" : "Show lyrics"
                })
            }
            return list
        }

        onSlideLeftRequested: playerRoot.mediaService?.previous()
        onSlideRightRequested: playerRoot.mediaService?.next()
        onSecondaryTriggered: playerRoot.mediaService?.togglePlaying()
        onExpandRequested: {
            if (playerRoot.lyricsAvailable)
                playerRoot.showLyrics = !playerRoot.showLyrics
        }
        onSubItemCycled: (newIndex, delta) => {
            playerRoot.mediaService?.seekBy(delta * 10)
            modalZone.currentSubIndex = 1
        }
        onActivated: {
            if (playerRoot.availableOptions.length > 0) {
                const opt = playerRoot.availableOptions[playerRoot.focusedOptionIndex]
                if (opt)
                    playerRoot.triggerOption(opt)
            } else {
                playerRoot.mediaService?.togglePlaying()
            }
        }
        onDpadUnhandled: direction => {
            if (playerRoot.availableOptions.length === 0)
                return
            if (direction === "left")
                playerRoot.focusedOptionIndex = (playerRoot.focusedOptionIndex - 1 + playerRoot.availableOptions.length) % playerRoot.availableOptions.length
            else if (direction === "right")
                playerRoot.focusedOptionIndex = (playerRoot.focusedOptionIndex + 1) % playerRoot.availableOptions.length
            else if (playerRoot.availableOptions[playerRoot.focusedOptionIndex] === "volume") {
                if (direction === "up")
                    playerRoot.mediaService?.adjustVolume(0.05)
                else if (direction === "down")
                    playerRoot.mediaService?.adjustVolume(-0.05)
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingXL
            spacing: Theme.spacingXL

            // Columna izquierda: letras sincronizadas o carátula ampliada (alternable con Select)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1

                ListView {
                    id: lyricsList
                    anchors.fill: parent
                    clip: true
                    interactive: false
                    spacing: Theme.spacingM
                    visible: playerRoot.showLyrics && playerRoot.lyricsAvailable && playerRoot.hasPlayer
                    model: playerRoot.lyricsCtrl?.lines ?? []
                    currentIndex: playerRoot.lyricsCtrl?.activeIndex ?? -1
                    preferredHighlightBegin: height * 0.38
                    preferredHighlightEnd: height * 0.56
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    highlightMoveDuration: playerRoot.motionTokens?.durationNormal ?? 220

                    delegate: StyledText {
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: index === lyricsList.currentIndex

                        width: lyricsList.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: String(modelData?.x ?? "")
                        font.pixelSize: isCurrent ? Theme.fontSizeXLarge : Theme.fontSizeLarge
                        font.weight: isCurrent ? Font.Bold : Font.Medium
                        color: isCurrent ? playerRoot.fgColor : Qt.alpha(playerRoot.fgColor, 0.38)

                        Behavior on color {
                            ColorAnimation { duration: playerRoot.motionTokens?.durationFast ?? 120 }
                        }
                    }
                }

                SlantedImage {
                    anchors.centerIn: parent
                    visible: !playerRoot.showLyrics || !playerRoot.lyricsAvailable || !playerRoot.hasPlayer
                    width: Math.min(parent.width * 0.85, parent.height * 0.85, 320)
                    height: width
                    styleTokens: playerRoot.styleTokens
                    motionTokens: playerRoot.motionTokens
                    source: playerRoot.mediaService?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    showGradientOverlay: false
                    fallbackText: "♪"
                    focused: false
                }
            }

            // Columna derecha: fuente, metadatos, progreso, transporte y opciones fijas
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.15
                spacing: Theme.spacingM

                Item { Layout.fillHeight: true }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingS
                    visible: playerRoot.hasPlayer

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: playerRoot.tr("media.listening_from", "Listening from")
                        font.pixelSize: Theme.fontSizeSmall
                        color: playerRoot.mutedFg
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: sourceLabel.implicitWidth + Theme.spacingM * 2
                        height: 26
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.14)

                        StyledText {
                            id: sourceLabel
                            anchors.centerIn: parent
                            text: playerRoot.mediaService?.identity || "MPRIS"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            color: playerRoot.fgColor
                        }
                    }
                }

                DisplayTitle {
                    Layout.fillWidth: true
                    styleTokens: playerRoot.styleTokens
                    horizontalAlignment: Text.AlignHCenter
                    text: playerRoot.mediaService?.title || playerRoot.tr("media.idle_body", "No active media player")
                    font.pixelSize: Theme.fontSizeXXLarge
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (!playerRoot.hasPlayer)
                            return playerRoot.tr("media.idle_subtitle", "MPRIS")
                        const parts = []
                        if (playerRoot.mediaService?.artist)
                            parts.push(playerRoot.mediaService.artist)
                        if (playerRoot.mediaService?.album)
                            parts.push(playerRoot.mediaService.album)
                        return parts.join(" · ")
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: playerRoot.mutedFg
                    elide: Text.ElideRight
                }

                // Barra de progreso y tiempos
                Column {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: playerRoot.hasPlayer

                    ValueMeter {
                        width: parent.width
                        height: 8
                        value: (playerRoot.mediaService?.progress ?? 0) * 100
                        maximum: 100
                        styleTokens: playerRoot.styleTokens
                        motionTokens: playerRoot.motionTokens
                    }

                    Item {
                        width: parent.width
                        height: 18

                        StyledText {
                            anchors.left: parent.left
                            text: playerRoot.formatTime(playerRoot.mediaService?.position ?? 0)
                            font.pixelSize: Theme.fontSizeSmall
                            color: playerRoot.mutedFg
                        }

                        StyledText {
                            anchors.right: parent.right
                            text: playerRoot.formatTime(playerRoot.mediaService?.length ?? 0)
                            font.pixelSize: Theme.fontSizeSmall
                            color: playerRoot.mutedFg
                        }
                    }
                }

                // Transporte principal: icono + texto + glifo de mando
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingM

                    ActionPill {
                        text: playerRoot.tr("media.prev", "Previous")
                        implicitHeight: 50
                        glyphAction: "I.ActionSlide.L"
                        iconSource: Qt.resolvedUrl("../../assets/icons/media/skip_previous.svg")
                        iconSize: 20
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        enabled: Boolean(playerRoot.mediaService?.canGoPrevious)
                        onClicked: playerRoot.mediaService?.previous()
                    }

                    ActionPill {
                        text: playerRoot.isPlaying
                            ? playerRoot.tr("media.pause", "Pause")
                            : playerRoot.tr("media.play", "Play")
                        implicitHeight: 54
                        primary: true
                        glyphAction: "I.Action"
                        iconSource: playerRoot.isPlaying
                            ? Qt.resolvedUrl("../../assets/icons/media/pause.svg")
                            : Qt.resolvedUrl("../../assets/icons/media/play_arrow.svg")
                        iconSize: 22
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        enabled: Boolean(playerRoot.mediaService?.canTogglePlaying)
                        onClicked: playerRoot.mediaService?.togglePlaying()
                    }

                    ActionPill {
                        text: playerRoot.tr("media.next", "Next")
                        implicitHeight: 50
                        glyphAction: "I.ActionSlide.R"
                        iconSource: Qt.resolvedUrl("../../assets/icons/media/skip_next.svg")
                        iconSize: 20
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        enabled: Boolean(playerRoot.mediaService?.canGoNext)
                        onClicked: playerRoot.mediaService?.next()
                    }
                }

                // Opciones siempre visibles, navegables con D-Pad + A
                Flow {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingS
                    visible: playerRoot.availableOptions.length > 0

                    Repeater {
                        model: playerRoot.availableOptions
                        delegate: ActionPill {
                            id: optPill
                            required property int index
                            required property string modelData

                            highlighted: playerRoot.focusedOptionIndex === index
                            iconSource: playerRoot.optionIcon(modelData)
                            iconSize: 18
                            styleTokens: playerRoot.styleTokens
                            primary: {
                                if (modelData === "lyrics") return playerRoot.showLyrics
                                if (modelData === "shuffle") return Boolean(playerRoot.mediaService?.shuffle)
                                if (modelData === "repeat") return (playerRoot.mediaService?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                                return false
                            }
                            text: {
                                if (modelData === "lyrics") return playerRoot.tr("media.lyrics", "Lyrics")
                                if (modelData === "shuffle") return playerRoot.tr("media.shuffle", "Shuffle")
                                if (modelData === "repeat") {
                                    const ls = playerRoot.mediaService?.loopState ?? MprisLoopState.None
                                    return playerRoot.tr("media.repeat", "Repeat") + (ls === MprisLoopState.Track ? " (1)" : (ls === MprisLoopState.Playlist ? " (∞)" : ""))
                                }
                                if (modelData === "player") return playerRoot.mediaService?.identity || playerRoot.tr("media.switch_player", "Player")
                                if (modelData === "volume") return playerRoot.tr("media.volume", "Volume") + " " + Math.round((playerRoot.mediaService?.volume ?? 0) * 100) + "%"
                                return modelData
                            }
                            onClicked: {
                                playerRoot.focusedOptionIndex = index
                                playerRoot.triggerOption(modelData)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
