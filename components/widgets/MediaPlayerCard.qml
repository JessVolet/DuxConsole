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
    clip: true
    focused: mediaZone.active
    implicitWidth: 360
    implicitHeight: compact ? 84 : 104

    // Fondo difuminado del art
    Image {
        anchors.fill: parent
        source: mediaCard.mediaService?.artUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready && mediaCard.hasPlayer
        opacity: 0.28
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.72
            blurMax: 32
        }
    }

    // Canva de espectro animado en el fondo de la tarjeta
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: parent.height * 0.72
        spacing: 4
        visible: mediaCard.hasPlayer

        Repeater {
            model: 16
            delegate: Item {
                id: canvaCol
                required property int index
                property real level: 0.18 + ((index * 37) % 60) / 100.0

                width: Math.max(4, (parent.width - 15 * 4) / 16)
                height: parent.height

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: mediaCard.isPlaying
                        ? Math.max(6, Math.round(parent.height * canvaCol.level))
                        : 6
                    radius: 2
                    color: Qt.alpha(mediaCard.accentColor, 0.22)

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        radius: 1
                        color: Qt.alpha(mediaCard.accentColor, 0.55)
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: mediaCard.motionTokens?.durationFast ?? 120
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Timer {
                    interval: 170 + (canvaCol.index % 5) * 45
                    repeat: true
                    running: mediaCard.isPlaying && (mediaCard.motionTokens?.animationsEnabled ?? true)
                    onTriggered: canvaCol.level = 0.15 + Math.random() * 0.80
                }
            }
        }
    }

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
        ringRadius: mediaCard.surfaceRadius
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

                // Fila inferior: barritas + letra en vivo (solo si hay letra activa)
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    height: 18
                    visible: mediaCard.hasPlayer

                    Row {
                        id: miniBars
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        height: 14

                        Repeater {
                            model: [0.35, 0.75, 0.45, 0.95, 0.60, 0.30, 0.70]
                            delegate: Rectangle {
                                id: barRect
                                required property int index
                                required property real modelData

                                property real phase: modelData
                                anchors.bottom: parent.bottom
                                width: 4
                                radius: 2
                                height: mediaCard.isPlaying
                                    ? Math.max(4, Math.round(14 * phase))
                                    : 4
                                color: mediaCard.accentColor

                                Timer {
                                    interval: 180 + barRect.index * 45
                                    repeat: true
                                    running: mediaCard.isPlaying && (mediaCard.motionTokens?.animationsEnabled ?? true)
                                    onTriggered: barRect.phase = 0.25 + Math.random() * 0.75
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: mediaCard.motionTokens?.durationFast ?? 120
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: lyricSlot
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, parent.width - miniBars.width - Theme.spacingS)
                        height: parent.height
                        clip: true
                        visible: mediaCard.currentLyricLine !== ""

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
}
