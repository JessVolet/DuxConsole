pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
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

    readonly property bool hasPlayer: Boolean(mediaService?.hasPlayer)
    readonly property bool isPlaying: Boolean(mediaService?.isPlaying)
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

    role: "card"
    focused: mediaZone.active
    implicitWidth: 340
    implicitHeight: compact ? 84 : 96

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
                        ? Qt.alpha(mediaCard.styleTokens.onSurfaceColor("card"), 0.72)
                        : (Theme.surfaceVariantText ?? "#9CA3AF")
                    elide: Text.ElideRight
                }

                // Mini visualizador animado cuando hay reproducción activa
                Row {
                    spacing: 4
                    height: 14
                    visible: mediaCard.hasPlayer

                    Repeater {
                        model: [0.35, 0.75, 0.45, 0.95, 0.60, 0.30, 0.70]
                        delegate: Rectangle {
                            id: barRect
                            required property int index
                            required property real modelData

                            property real phase: modelData
                            anchors.bottom: parent.bottom
                            width: 5
                            radius: 2
                            height: mediaCard.isPlaying
                                ? Math.max(4, Math.round(14 * phase))
                                : 4
                            color: mediaCard.styleTokens?.accentColor ?? Theme.primary

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
            }
        }
    }
}
