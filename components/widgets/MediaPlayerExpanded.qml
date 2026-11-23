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
import "../primitives/glyphs"
import "../primitives/meters"
import "../primitives/surfaces"
import "../primitives/surfaces/SlantedGeometry.js" as SlantedGeometry
import "../primitives/text"

SlantedSurface {
    id: playerRoot

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var i18n: null
    property string layerName: "media-player"
    property var cavaBars: []
    property bool pickerVisible: false
    signal playersRequested(Item source)

    property bool showLyrics: true
    property int focusedOptionIndex: 0

    readonly property bool compactLayout: width < 720 || height < 440
    readonly property real baseSkew: styleTokens ? styleTokens.skewAngle * 0.625 : -5
    readonly property var lyricsCtrl: LyricsService.controller
    readonly property bool hasPlayer: Boolean(mediaService?.hasPlayer)
    readonly property bool isPlaying: Boolean(mediaService?.isPlaying)
    readonly property bool canSeek: Boolean(mediaService?.canSeek)
    readonly property bool hasValidLyrics: {
        if (!hasPlayer || !mediaService?.title)
            return false
        if (!lyricsCtrl || !lyricsCtrl.available || lyricsCtrl.pending)
            return false
        if (lyricsCtrl.state !== "ready")
            return false
        if (!mediaService.matchesTrack(lyricsCtrl.track))
            return false
        const hasSynced = Boolean(lyricsCtrl.synced && lyricsCtrl.lines && lyricsCtrl.lines.length > 0)
        const hasPlain = Boolean(!lyricsCtrl.synced && lyricsCtrl.plainLines && lyricsCtrl.plainLines.length > 0)
        return hasSynced || hasPlain
    }

    readonly property color accentColor: styleTokens ? styleTokens.accentColor : Theme.primary
    readonly property color fgColor: styleTokens ? styleTokens.onSurfaceColor("card") : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color mutedFg: Qt.alpha(fgColor, 0.72)

    readonly property var inlineOptions: {
        const opts = []
        if (hasValidLyrics)
            opts.push("lyrics")
        if (mediaService?.loopSupported)
            opts.push("repeat")
        if (mediaService?.shuffleSupported)
            opts.push("shuffle")
        return opts
    }

    onInlineOptionsChanged: {
        if (focusedOptionIndex >= inlineOptions.length)
            focusedOptionIndex = Math.max(0, inlineOptions.length - 1)
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    function mediaIcon(name) {
        return iconsPadManager ? iconsPadManager.resolveMediaIcon(name) : ""
    }

    function optionSource(option) {
        return optionRepeater.itemAt(inlineOptions.indexOf(option))
    }

    function optionIcon(optId) {
        if (optId === "repeat") {
            return (mediaService?.loopState ?? MprisLoopState.None) === MprisLoopState.Track
                ? mediaIcon("repeat_one")
                : mediaIcon("repeat")
        }
        return mediaIcon(optId)
    }

    function triggerOption(optId) {
        if (optId === "lyrics")
            showLyrics = !showLyrics
        else if (optId === "shuffle")
            mediaService?.toggleShuffle()
        else if (optId === "repeat")
            mediaService?.cycleLoop()
    }

    role: "card"
    skewAngle: SlantedGeometry.effectiveSkewAngle(baseSkew, width, height)
    radius: compactLayout ? 16 : 24
    focused: modalZone.active

    backdrop: [
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
        },
        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: playerRoot.safeHorizontalInset + Theme.spacingM
            anchors.rightMargin: playerRoot.safeHorizontalInset + Theme.spacingM
            height: parent.height * 0.34
            spacing: 6
            visible: playerRoot.cavaBars.length > 0

            Repeater {
                model: playerRoot.cavaBars.length
                delegate: Item {
                    id: cavaCol
                    required property int index
                    readonly property real level: playerRoot.cavaBars[index] ?? 0
                    readonly property int count: Math.max(1, playerRoot.cavaBars.length)

                    width: Math.max(6, (parent.width - (count - 1) * 6) / count)
                    height: parent.height

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.max(4, Math.round(parent.height * cavaCol.level))
                        radius: 3
                        color: Qt.alpha(playerRoot.accentColor, 0.24)

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 2
                            radius: 1
                            color: Qt.alpha(playerRoot.accentColor, 0.65)
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: playerRoot.motionTokens ? playerRoot.motionTokens.visualizerBarDuration : 0
                                easing.type: playerRoot.motionTokens ? playerRoot.motionTokens.visualizerEasing : Easing.OutQuad
                            }
                        }
                    }
                }
            }
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
        expandable: playerRoot.hasValidLyrics
        showFocusRing: false
        subItemCount: playerRoot.canSeek ? 3 : 0
        currentSubIndex: 1
        wrapSubItems: true
        actionHints: {
            const list = [
                { action: "I.Options", labelKey: "media.players", fallback: "Players" },
                { action: "I.ActionSlide.L", labelKey: "media.prev", fallback: "Previous" },
                { action: "I.ActionSlide.R", labelKey: "media.next", fallback: "Next" },
                { action: "I.Action", labelKey: playerRoot.isPlaying ? "media.pause" : "media.play", fallback: playerRoot.isPlaying ? "Pause" : "Play" }
            ]
            if (playerRoot.canSeek) {
                list.push({ action: "I.ActionOption.L", labelKey: "media.seek_back", fallback: "-10s" })
                list.push({ action: "I.ActionOption.R", labelKey: "media.seek_forward", fallback: "+10s" })
            }
            if (playerRoot.hasValidLyrics) {
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
        onOptionsTriggered: playerRoot.playersRequested(playerButton)
        onExpandRequested: {
            if (playerRoot.hasValidLyrics)
                playerRoot.showLyrics = !playerRoot.showLyrics
        }
        onSubItemCycled: (newIndex, delta) => {
            if (!playerRoot.canSeek)
                return
            playerRoot.mediaService?.seekBy(delta * 10)
            modalZone.currentSubIndex = 1
        }
        onActivated: {
            if (playerRoot.inlineOptions.length > 0) {
                const opt = playerRoot.inlineOptions[playerRoot.focusedOptionIndex]
                if (opt)
                    playerRoot.triggerOption(opt)
            } else {
                playerRoot.mediaService?.togglePlaying()
            }
        }
        onDpadUnhandled: direction => {
            if (playerRoot.inlineOptions.length === 0)
                return
            if (direction === "left")
                playerRoot.focusedOptionIndex = (playerRoot.focusedOptionIndex - 1 + playerRoot.inlineOptions.length) % playerRoot.inlineOptions.length
            else if (direction === "right")
                playerRoot.focusedOptionIndex = (playerRoot.focusedOptionIndex + 1) % playerRoot.inlineOptions.length
        }

        GridLayout {
            anchors.fill: parent
            anchors.topMargin: playerRoot.compactLayout ? Theme.spacingM : Theme.spacingXL
            anchors.bottomMargin: (playerRoot.compactLayout ? Theme.spacingM : Theme.spacingXL) + (volumeButton.visible ? volumeButton.height : 0)
            anchors.leftMargin: playerRoot.safeHorizontalInset + Theme.spacingL
            anchors.rightMargin: playerRoot.safeHorizontalInset + Theme.spacingL
            columns: playerRoot.compactLayout ? 1 : 2
            rowSpacing: Theme.spacingM
            columnSpacing: Theme.spacingXL

            // Columna izquierda: panel de letras inclinado o carátula ampliada (por defecto si no hay letras válidas)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: !playerRoot.compactLayout
                Layout.preferredHeight: playerRoot.compactLayout ? 150 : -1
                Layout.preferredWidth: playerRoot.compactLayout ? -1 : 1

                MediaLyricsPanel {
                    anchors.fill: parent
                    visible: playerRoot.hasValidLyrics && playerRoot.showLyrics
                    lyricsActive: visible
                    styleTokens: playerRoot.styleTokens
                    motionTokens: playerRoot.motionTokens
                }

                SlantedImage {
                    anchors.centerIn: parent
                    visible: !playerRoot.hasValidLyrics || !playerRoot.showLyrics
                    width: Math.min(parent.width * 0.85, parent.height * 0.85, 320)
                    height: width
                    skewAngle: playerRoot.skewAngle
                    styleTokens: playerRoot.styleTokens
                    motionTokens: playerRoot.motionTokens
                    source: playerRoot.mediaService?.artUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    showGradientOverlay: false
                    fallbackText: "♪"
                    focused: false
                }
            }

            // Columna derecha: fuente, metadatos, barra inclinada con LT/RT, transporte y opciones
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: playerRoot.compactLayout ? -1 : 1.15
                spacing: playerRoot.compactLayout ? Theme.spacingS : Theme.spacingM

                Item { Layout.fillHeight: true }

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingS

                    StyledText {
                        visible: playerRoot.hasPlayer
                        anchors.verticalCenter: parent.verticalCenter
                        text: playerRoot.tr("media.listening_from", "Listening from")
                        font.pixelSize: Theme.fontSizeSmall
                        color: playerRoot.mutedFg
                    }

                    ActionPill {
                        id: playerButton
                        anchors.verticalCenter: parent.verticalCenter
                        text: playerRoot.mediaService?.identity || playerRoot.tr("media.switch_player", "Player")
                        glyphAction: "I.Options"
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        opacity: playerRoot.pickerVisible ? 0 : 1
                        onClicked: playerRoot.playersRequested(playerButton)
                    }
                }

                DisplayTitle {
                    Layout.fillWidth: true
                    styleTokens: playerRoot.styleTokens
                    horizontalAlignment: Text.AlignHCenter
                    text: playerRoot.mediaService?.title || playerRoot.tr("media.idle_body", "No active media player")
                    font.pixelSize: playerRoot.compactLayout ? Theme.fontSizeXLarge : Theme.fontSizeXXLarge
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

                // Barra de progreso inclinada con controles visibles LT / RT
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS
                    visible: playerRoot.hasPlayer

                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: ltGlyph.implicitWidth
                        implicitHeight: ltGlyph.implicitHeight
                        opacity: playerRoot.canSeek ? 1.0 : 0.38

                        InputGlyph {
                            id: ltGlyph
                            iconsPadManager: playerRoot.iconsPadManager
                            styleTokens: playerRoot.styleTokens
                            action: "I.ActionOption.L"
                        }

                        TapHandler {
                            enabled: playerRoot.canSeek
                            onTapped: playerRoot.mediaService?.seekBy(-10)
                        }
                    }

                    MediaProgressBar {
                        Layout.fillWidth: true
                        position: playerRoot.mediaService?.position ?? 0
                        length: playerRoot.mediaService?.length ?? 0
                        progress: playerRoot.mediaService?.progress ?? 0
                        canSeek: playerRoot.canSeek
                        hasPlayer: playerRoot.hasPlayer
                        skewAngle: playerRoot.skewAngle
                        styleTokens: playerRoot.styleTokens
                        motionTokens: playerRoot.motionTokens
                        onSeekRequested: ratio => playerRoot.mediaService?.seekToRatio(ratio)
                    }

                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: rtGlyph.implicitWidth
                        implicitHeight: rtGlyph.implicitHeight
                        opacity: playerRoot.canSeek ? 1.0 : 0.38

                        InputGlyph {
                            id: rtGlyph
                            iconsPadManager: playerRoot.iconsPadManager
                            styleTokens: playerRoot.styleTokens
                            action: "I.ActionOption.R"
                        }

                        TapHandler {
                            enabled: playerRoot.canSeek
                            onTapped: playerRoot.mediaService?.seekBy(10)
                        }
                    }
                }

                // Transporte principal: icono centralizado + texto + glifo de mando
                Row {
                    id: transportRow
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingM

                    ActionPill {
                        text: playerRoot.tr("media.prev", "Previous")
                        width: (transportRow.parent.width - transportRow.spacing * 2) / 3
                        implicitHeight: 48
                        glyphAction: "I.ActionSlide.L"
                        iconSource: playerRoot.mediaIcon("prev")
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
                        implicitHeight: 48
                        width: (transportRow.parent.width - transportRow.spacing * 2) / 3
                        primary: true
                        glyphAction: "I.Action"
                        iconSource: playerRoot.isPlaying ? playerRoot.mediaIcon("pause") : playerRoot.mediaIcon("play")
                        iconSize: 22
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        enabled: Boolean(playerRoot.mediaService?.canTogglePlaying)
                        onClicked: playerRoot.mediaService?.togglePlaying()
                    }

                    ActionPill {
                        text: playerRoot.tr("media.next", "Next")
                        width: (transportRow.parent.width - transportRow.spacing * 2) / 3
                        implicitHeight: 48
                        glyphAction: "I.ActionSlide.R"
                        iconSource: playerRoot.mediaIcon("next")
                        iconSize: 20
                        iconsPadManager: playerRoot.iconsPadManager
                        styleTokens: playerRoot.styleTokens
                        enabled: Boolean(playerRoot.mediaService?.canGoNext)
                        onClicked: playerRoot.mediaService?.next()
                    }
                }

                // Opciones siempre visibles, navegables con D-Pad + A
                Row {
                    id: optionRow
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingS
                    visible: playerRoot.inlineOptions.length > 0

                    Repeater {
                        id: optionRepeater
                        model: playerRoot.inlineOptions
                        delegate: ActionPill {
                            id: optPill
                            required property int index
                            required property string modelData

                            width: (optionRow.parent.width - optionRow.spacing * 2) / 3
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

        // Reserva visual para futura perilla de volumen controlada con stick R
        ActionPill {
            id: volumeButton
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: playerRoot.safeHorizontalInset + Theme.spacingL
            anchors.bottomMargin: Theme.spacingL
            visible: Boolean(playerRoot.mediaService?.volumeSupported)
            width: implicitHeight
            iconSource: playerRoot.mediaIcon("volume")
            styleTokens: playerRoot.styleTokens
            Accessible.name: playerRoot.tr("media.volume", "Volume") + " " + Math.round((playerRoot.mediaService?.volume ?? 0) * 100) + "%"
        }
    }
}
