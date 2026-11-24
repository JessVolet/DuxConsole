pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.Common
import qs.Widgets
import "../../../core/interaction"
import "../../primitives/surfaces"

// Sound-specific now-playing card, intentionally separate from Home's
// MediaPlayerCard. Material 3 tonal container; the whole card opens the modal.
Rectangle {
    id: card

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var i18n: null
    property string zoneId: "sound-media"
    property string layerName: "dashboard"
    property bool defaultFocus: false
    property bool hiddenVisual: false
    property var styleTokens: null
    property var motionTokens: null

    signal expandRequested()

    readonly property alias focusZone: zone
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
        return parts.length > 0
            ? parts.join(" · ")
            : (mediaService.identity || tr("media.idle_subtitle", "MPRIS"))
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    radius: 28
    color: styleTokens
           ? styleTokens.m3Alpha(styleTokens.m3SurfaceHigh, 0.92)
           : Qt.alpha(Theme.surfaceContainerHigh, 0.92)
    implicitHeight: 242
    opacity: hiddenVisual ? 0 : 1

    FocusZone {
        id: zone
        anchors.fill: parent
        zoneId: card.zoneId
        layerName: card.layerName
        layerManager: card.layerManager
        navigationManager: card.navigationManager
        defaultFocus: card.defaultFocus
        showFocusRing: false
        ringRadius: card.radius
        actionHints: [
            { action: "I.Action", labelKey: "media.expand", fallback: "Open player" }
        ]

        onSecondaryTriggered: card.expandRequested()

        TapHandler {
            enabled: !zone.inert
            onTapped: {
                zone.requestZoneFocus()
                card.expandRequested()
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Rectangle {
            id: artFrame
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.height, 96)
            height: width
            radius: 16
            color: card.styleTokens ? card.styleTokens.m3SurfaceHighest : Theme.surfaceContainerHighest
            clip: true

            SlantedImage {
                anchors.fill: parent
                visible: (card.mediaService?.artUrl ?? "") !== ""
                source: card.mediaService?.artUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                showGradientOverlay: false
                fallbackText: ""
                styleTokens: card.styleTokens
                motionTokens: card.motionTokens
            }

            Text {
                anchors.centerIn: parent
                visible: (card.mediaService?.artUrl ?? "") === ""
                text: "♪"
                color: card.styleTokens ? card.styleTokens.m3OnSurfaceVariant : Theme.onSurfaceVariant
                font.pixelSize: 34
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - artFrame.width - state.width - Theme.spacingL)
            spacing: 4

            StyledText {
                width: parent.width
                text: card.trackTitle
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                elide: Text.ElideRight
                color: card.styleTokens ? card.styleTokens.m3OnSurface : Theme.onSurface
            }

            StyledText {
                width: parent.width
                text: card.trackSubtitle
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: card.styleTokens ? card.styleTokens.m3OnSurfaceVariant : Theme.onSurfaceVariant
            }

            StyledText {
                text: card.tr("media.expand", "Open player")
                font.pixelSize: Theme.fontSizeXSmall
                color: card.styleTokens ? card.styleTokens.m3OnSurfaceVariant : Theme.onSurfaceVariant
            }
        }

        Rectangle {
            id: state
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 48
            radius: 24
            color: card.styleTokens ? card.styleTokens.m3Primary : Theme.primary
            opacity: card.hasPlayer ? 1 : 0.4

            Shape {
                anchors.centerIn: parent
                width: 18
                height: 18
                visible: !card.isPlaying
                ShapePath {
                    fillColor: card.styleTokens ? card.styleTokens.m3OnPrimary : Theme.onPrimary
                    strokeColor: "transparent"
                    startX: 5; startY: 2
                    PathLine { x: 16; y: 9 }
                    PathLine { x: 5; y: 16 }
                    PathLine { x: 5; y: 2 }
                }
            }

            Row {
                anchors.centerIn: parent
                visible: card.isPlaying
                spacing: 4
                Rectangle { width: 5; height: 16; radius: 2; color: card.styleTokens ? card.styleTokens.m3OnPrimary : Theme.onPrimary }
                Rectangle { width: 5; height: 16; radius: 2; color: card.styleTokens ? card.styleTokens.m3OnPrimary : Theme.onPrimary }
            }
        }
    }
}
