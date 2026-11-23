pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import "../../../core/interaction"
import "../../primitives/surfaces"

// Stretched now-playing card for the Sound tab. It is intentionally separate
// from Home's MediaPlayerCard so each screen can evolve without sharing limits.
SlantedSurface {
    id: card

    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var i18n: null
    property string zoneId: "sound-media"
    property string layerName: "dashboard"
    property bool defaultFocus: false
    property bool hiddenVisual: false
    opacity: hiddenVisual ? 0 : 1

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
        return parts.length > 0
            ? parts.join(" · ")
            : (mediaService.identity || tr("media.idle_subtitle", "MPRIS"))
    }

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    contained: true
    contentPadding: Theme.spacingM
    focused: zone.active
    implicitHeight: 132

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
        spacing: Theme.spacingM

        SlantedImage {
            id: art
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.height, 96)
            height: width
            source: card.mediaService?.artUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            showGradientOverlay: false
            fallbackText: "♪"
            styleTokens: card.styleTokens
            motionTokens: card.motionTokens
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - art.width - playIcon.width - Theme.spacingM * 2)
            spacing: 4

            StyledText {
                width: parent.width
                text: card.trackTitle
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                elide: Text.ElideRight
                color: card.styleTokens ? card.styleTokens.onSurfaceColor("card") : Theme.surfaceText
            }

            StyledText {
                width: parent.width
                text: card.trackSubtitle
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: card.styleTokens
                       ? Qt.alpha(card.styleTokens.onSurfaceColor("card"), 0.78)
                       : Theme.surfaceVariantText
            }
        }

        Image {
            id: playIcon
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            opacity: card.hasPlayer ? 0.85 : 0.35
            source: Qt.resolvedUrl("../../../assets/icons/media/" + (card.isPlaying ? "pause.svg" : "play_arrow.svg"))
            sourceSize: Qt.size(44, 44)
            fillMode: Image.PreserveAspectFit
        }
    }
}
