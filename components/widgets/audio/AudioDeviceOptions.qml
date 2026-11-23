pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import "../../primitives/buttons"
import "../../primitives/text"
import "../../primitives/surfaces"
import "../../../core/interaction"

Item {
    id: options
    property var audioService: null
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property var i18n: null
    property Item sourceItem: null
    property string targetKey: ""
    readonly property string layerName: "audio-device-options"
    readonly property bool isOpen: layerManager?.topLayer === layerName
    readonly property var target: (audioService?.outputs ?? []).concat(audioService?.inputs ?? []).find(t => t.key === targetKey) ?? null
    readonly property var choices: audioService ? audioService.choices(targetKey) : []
    anchors.fill: parent
    visible: isOpen || transform.progress > 0
    z: 100
    function tr(key, fallback) { return i18n ? i18n.t(key, fallback) : fallback }
    function open(key, source) { targetKey = key; sourceItem = source; audioService?.refreshOptions(key); layerManager?.push(layerName) }
    function execute(index) {
        if (!target) return
        if (index === 0) audioService.togglePin(targetKey)
        else audioService.applyChoice(targetKey, choices[index - 1])
    }
    MouseArea { anchors.fill: parent; enabled: options.isOpen; onClicked: options.layerManager.pop() }
    TransformSurface {
        id: transform
        sourceItem: options.sourceItem
        expanded: options.isOpen
        expandedSize: Qt.size(440, Math.min(options.height - 48, 140 + (options.choices.length + 1) * 56))
        styleTokens: options.styleTokens
        motionTokens: options.motionTokens
        FocusZone {
            id: zone
            anchors.fill: parent
            layerName: options.layerName
            zoneId: "audio-device-options-zone"
            layerManager: options.layerManager
            navigationManager: options.navigationManager
            defaultFocus: true
            enabled: transform.contentReady && options.target !== null
            subItemCount: options.choices.length + 1
            showFocusRing: false
            onActivated: options.execute(currentSubIndex)
            onDpadUnhandled: direction => {
                if (direction === "up") zone.cycleSubItem(-1)
                if (direction === "down") zone.cycleSubItem(1)
            }
            MouseArea { anchors.fill: parent }
            Column {
                anchors.fill: parent
                spacing: Theme.spacingS
                opacity: transform.contentOpacity
                SectionTitle { width: parent.width; title: options.target?.title ?? options.tr("audio.unavailable", "Unavailable"); styleTokens: options.styleTokens }
                ListView {
                    width: parent.width
                    height: Math.max(0, parent.height - 70)
                    clip: true
                    spacing: Theme.spacingS
                    model: options.choices.length + 1
                    currentIndex: zone.currentSubIndex
                    highlightRangeMode: ListView.ApplyRange
                    delegate: ActionPill {
                        required property int index
                        width: ListView.view.width
                        text: index === 0 ? options.tr(options.target?.pinned ? "audio.unpin" : "audio.pin", options.target?.pinned ? "Unpin" : "Pin") : String(options.choices[index - 1]?.title ?? "")
                        styleTokens: options.styleTokens
                        highlighted: zone.active && zone.currentSubIndex === index
                        onClicked: { zone.currentSubIndex = index; options.execute(index) }
                    }
                }
            }
        }
    }
    Connections {
        target: transform
        function onContentReadyChanged() {
            if (transform.contentReady) Qt.callLater(() => { if (options.isOpen) options.navigationManager?.ensureFocus(options.layerName) })
        }
    }
}
