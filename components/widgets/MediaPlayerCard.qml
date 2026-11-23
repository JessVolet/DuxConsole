pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import qs.Services
import "../../core/interaction"
import "../primitives/surfaces"

SlantedSurface {
    id: mediaCard

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var i18n: null
    property var navLeft: null
    property var navUp: null
    property string layerName: "dashboard"
    property string zoneId: "home-media"
    property bool compact: false
    readonly property alias focusZone: mediaZone

    signal expandRequested()

    readonly property var lyricsCtrl: LyricsService.controller
    readonly property string currentLyricLine: {
        if (!hasPlayer || !lyricsCtrl?.available)
            return ""
        const idx = lyricsCtrl.activeIndex ?? -1
        if (idx < 0 || !lyricsCtrl.lines || idx >= lyricsCtrl.lines.length)
            return ""
        return String(lyricsCtrl.lines[idx]?.x ?? "").trim()
    }

    readonly property bool hasPlayer: Boolean(mediaService?.hasPlayer)
    readonly property bool isPlaying: Boolean(mediaService?.isPlaying)
    readonly property color accentColor: styleTokens?.accentColor ?? Theme.primary
    readonly property string trackTitle: mediaService?.title || tr("media.idle_body", "No active media player")
    readonly property string trackSubtitle: {
        if (!hasPlayer)
            return tr("media.idle_subtitle", "MPRIS")
        const parts = []
        if (mediaService.artist)
            parts.push(mediaService.artist)
        if (mediaService.album)
            parts.push(mediaService.album)
        if (parts.length > 0)
            return parts.join(" · ")
        return mediaService.identity || tr("media.idle_subtitle", "MPRIS")
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    LyricsSubscription {
        active: mediaCard.visible && mediaCard.hasPlayer
    }

    role: "card"
    focused: mediaZone.active
    implicitWidth: 360
    implicitHeight: compact ? 84 : 104

    backdrop: [
        // Fondo difuminado del art recortado al paralelogramo inclinado
        Image {
            anchors.fill: parent
            source: mediaCard.mediaService?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready && mediaCard.hasPlayer
            opacity: 0.30
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.72
                blurMax: 32
            }
        }
    ]

    FocusZone {
        id: mediaZone
        anchors.fill: parent
        zoneId: mediaCard.zoneId
        layerName: mediaCard.layerName
        layerManager: mediaCard.layerManager
        navigationManager: mediaCard.navigationManager
        navLeft: mediaCard.navLeft
        navUp: mediaCard.navUp
        showFocusRing: false
        ringRadius: mediaCard.radius
        actionHints: mediaCard.hasPlayer
            ? [
                { action: "I.Accept", labelKey: "media.expand", fallback: "Open player" },
                { action: "I.Action", labelKey: mediaCard.isPlaying ? "media.pause" : "media.play", fallback: mediaCard.isPlaying ? "Pause" : "Play" }
            ]
            : [{ action: "I.Accept", labelKey: "media.expand", fallback: "Open player" }]

        onActivated: mediaCard.expandRequested()
        onSecondaryTriggered: mediaCard.mediaService?.togglePlaying()

        TapHandler {
            enabled: !mediaZone.inert
            onTapped: {
                mediaZone.requestZoneFocus()
                mediaCard.expandRequested()
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: mediaCard.compact ? Theme.spacingS : Theme.spacingM
            spacing: Theme.spacingM

            SlantedImage {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(48, parent.height)
                height: width
                styleTokens: mediaCard.styleTokens
                motionTokens: mediaCard.motionTokens
                source: mediaCard.mediaService?.artUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                showGradientOverlay: false
                fallbackText: "♪"
                focused: false
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - Math.max(48, parent.height) - Theme.spacingM)
                spacing: 4

                StyledText {
                    width: parent.width
                    text: mediaCard.trackTitle
                    font.pixelSize: mediaCard.compact ? Theme.fontSizeMedium : Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: mediaCard.styleTokens?.onSurfaceColor("card") ?? (Theme.surfaceText ?? "#F2F4F8")
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: mediaCard.trackSubtitle
                    font.pixelSize: Theme.fontSizeSmall
                    color: mediaCard.styleTokens
                        ? Qt.alpha(mediaCard.styleTokens.onSurfaceColor("card"), 0.78)
                        : (Theme.surfaceVariantText ?? "#9CA3AF")
                    elide: Text.ElideRight
                }

                // Letra en vivo (solo visible si hay letra activa)
                Item {
                    id: lyricSlot
                    width: parent.width
                    height: 18
                    clip: true
                    visible: mediaCard.hasPlayer && mediaCard.currentLyricLine !== ""

                    StyledText {
                        id: lyricText
                        anchors.verticalCenter: parent.verticalCenter
                        text: mediaCard.currentLyricLine
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: mediaCard.styleTokens?.onSurfaceColor("card") ?? (Theme.surfaceText ?? "#F2F4F8")

                        readonly property real overflow: Math.max(0, implicitWidth - lyricSlot.width)

                        onTextChanged: x = 0

                        SequentialAnimation on x {
                            running: lyricSlot.visible && lyricText.overflow > 4 && (mediaCard.motionTokens?.animationsEnabled ?? true)
                            loops: Animation.Infinite
                            PauseAnimation { duration: 700 }
                            NumberAnimation {
                                to: -lyricText.overflow
                                duration: Math.max(1200, Math.round(lyricText.overflow * 28))
                                easing.type: Easing.InOutSine
                            }
                            PauseAnimation { duration: 900 }
                            NumberAnimation {
                                to: 0
                                duration: 600
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }
    }
}
