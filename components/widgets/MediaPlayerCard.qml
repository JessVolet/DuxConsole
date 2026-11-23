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
    property bool defaultFocus: false
    property bool compact: false
    readonly property alias focusZone: mediaZone

    signal expandRequested()

    readonly property var lyricsCtrl: LyricsService.controller
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
    readonly property string currentLyricLine: {
        if (!hasValidLyrics)
            return ""
        if (lyricsCtrl.synced) {
            const idx = lyricsCtrl.activeIndex ?? -1
            if (idx < 0 || !lyricsCtrl.lines || idx >= lyricsCtrl.lines.length)
                return ""
            return String(lyricsCtrl.lines[idx]?.x ?? "").trim()
        }
        return String(lyricsCtrl.plainLines?.[0] ?? "").trim()
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
        defaultFocus: mediaCard.defaultFocus
        navLeft: mediaCard.navLeft
        navUp: mediaCard.navUp
        showFocusRing: false
        ringRadius: mediaCard.radius
        actionHints: [
            { action: "I.Action", labelKey: "media.expand", fallback: "Open player" }
        ]

        onSecondaryTriggered: mediaCard.expandRequested()

        TapHandler {
            enabled: !mediaZone.inert
            onTapped: {
                mediaZone.requestZoneFocus()
                mediaCard.expandRequested()
            }
        }

        Row {
            anchors.fill: parent
            anchors.topMargin: mediaCard.compact ? Theme.spacingS : Theme.spacingM
            anchors.bottomMargin: mediaCard.compact ? Theme.spacingS : Theme.spacingM
            anchors.leftMargin: mediaCard.safeHorizontalInset + (mediaCard.compact ? Theme.spacingS : Theme.spacingM)
            anchors.rightMargin: mediaCard.safeHorizontalInset + (mediaCard.compact ? Theme.spacingS : Theme.spacingM)
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
                            PauseAnimation { duration: mediaCard.motionTokens?.marqueePauseStartDuration ?? 0 }
                            NumberAnimation {
                                to: -lyricText.overflow
                                duration: mediaCard.motionTokens ? mediaCard.motionTokens.marqueeDurationFor(lyricText.overflow) : 0
                                easing.type: mediaCard.motionTokens?.marqueeEasing ?? Easing.InOutSine
                            }
                            PauseAnimation { duration: mediaCard.motionTokens?.marqueePauseEndDuration ?? 0 }
                            NumberAnimation {
                                to: 0
                                duration: mediaCard.motionTokens?.marqueeReturnDuration ?? 0
                                easing.type: mediaCard.motionTokens?.marqueeEasing ?? Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }
    }
}
