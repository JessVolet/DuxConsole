pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import "../../core/interaction"
import "../primitives/buttons"
import "../primitives/surfaces"
import "../primitives/text"

Item {
    id: picker
    property Item sourceItem: null
    property var mediaService: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var motionTokens: null
    property var styleTokens: null
    property var i18n: null
    property string layerName: "media-player-picker"
    readonly property bool isOpen: layerManager ? layerManager.isLayerActive(layerName) : false
    readonly property var players: mediaService?.players ?? []
    function tr(key, fallback) { return i18n ? i18n.t(key, fallback) : fallback }
    function choose(index) {
        if (index === 0) mediaService?.useAutomaticPlayer()
        else if (players[index - 1]) mediaService?.selectPlayer(players[index - 1])
        if (isOpen) layerManager.pop()
    }
    function pin(index) {
        if (index > 0 && players[index - 1]) mediaService?.togglePlayerPin(players[index - 1])
    }
    function ensurePickerFocus() {
        if (isOpen && transition.contentReady)
            navigationManager?.ensureFocus(layerName)
    }
    onVisibleChanged: {
        if (visible) Qt.callLater(picker.ensurePickerFocus)
    }
    Connections {
        target: transition
        function onContentReadyChanged() {
            if (transition.contentReady) Qt.callLater(picker.ensurePickerFocus)
        }
    }
    anchors.fill: parent
    visible: isOpen || transition.progress > 0
    z: 200
    onIsOpenChanged: {
        if (isOpen) {
            const index = players.indexOf(mediaService?.activePlayer)
            zone.currentSubIndex = index + 1
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: picker.isOpen
        onClicked: picker.layerManager.pop()
    }

    TransformSurface {
        id: transition
        sourceItem: picker.sourceItem
        expanded: picker.isOpen
        motionTokens: picker.motionTokens
        styleTokens: picker.styleTokens
        shape: "rounded"
        expandedSize: Qt.size(Math.min(picker.width - 32, 520), Math.min(picker.height - 32, 164 + (picker.players.length + 1) * 88))
        originContentSize: Qt.size(44, 44)
        originContent: Component {
            ActionPill {
                glyphAction: "I.Refuse"
                iconsPadManager: picker.iconsPadManager
                styleTokens: picker.styleTokens
                enabled: picker.isOpen
                onClicked: picker.layerManager.pop()
            }
        }

        FocusZone {
            id: zone
            anchors.fill: parent
            zoneId: "media-player-picker-list"
            layerName: picker.layerName
            layerManager: picker.layerManager
            navigationManager: picker.navigationManager
            defaultFocus: true
            showFocusRing: false
            enabled: transition.contentReady
            subItemCount: picker.players.length + 1
            actionHints: [
                { action: "I.Accept", labelKey: "media.choose_player", fallback: "Select player" },
                { action: "I.Action", labelKey: "media.toggle_pin", fallback: "Pin / unpin" },
                { action: "I.Refuse", labelKey: "hints.back", fallback: "Back" }
            ]
            onActivated: picker.choose(currentSubIndex)
            onSecondaryTriggered: picker.pin(currentSubIndex)
            onDpadUnhandled: direction => {
                if (direction === "up" || direction === "left") zone.cycleSubItem(-1)
                else if (direction === "down" || direction === "right") zone.cycleSubItem(1)
            }

            MouseArea { anchors.fill: parent }
            DisplayTitle {
                id: heading
                width: parent.width
                text: picker.tr("media.players", "Players")
                styleTokens: picker.styleTokens
                opacity: transition.contentOpacity
            }
            ListView {
                anchors.top: heading.bottom
                anchors.topMargin: Theme.spacingM
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 52
                clip: true
                spacing: Theme.spacingS
                opacity: transition.contentOpacity
                model: picker.players.length + 1
                currentIndex: zone.currentSubIndex
                highlightRangeMode: ListView.ApplyRange
                highlightMoveDuration: picker.motionTokens ? picker.motionTokens.durationFast : 0
                delegate: MediaPlayerChoice {
                    id: choice
                    required property int index
                    readonly property var player: index > 0 ? picker.players[index - 1] : null
                    width: ListView.view.width
                    automatic: index === 0
                    title: automatic ? picker.tr("media.automatic", "Automatic") : String(player?.identity ?? "")
                    subtitle: automatic
                        ? (picker.mediaService?.pinnedUnavailable ? picker.tr("media.pinned_unavailable", "Pinned player disconnected") : picker.tr("media.automatic_hint", "Prefer a playing player"))
                        : String(player?.trackTitle ?? "")
                    pinned: player !== null && picker.mediaService?.pinnedPlayerKey === picker.mediaService?.playerKey(player)
                    pinLabel: pinned ? picker.tr("media.unpin", "Unpin") : picker.tr("media.pin", "Pin")
                    focused: zone.active && zone.currentSubIndex === index
                    selected: automatic ? picker.mediaService?.selectedPlayerKey === "" && picker.mediaService?.pinnedPlayerKey === "" : player === picker.mediaService?.activePlayer
                    iconsPadManager: picker.iconsPadManager
                    styleTokens: picker.styleTokens
                    motionTokens: picker.motionTokens
                    onChosen: picker.choose(index)
                    onPinRequested: { zone.currentSubIndex = index; picker.pin(index) }
                }
            }
        }
    }
}
