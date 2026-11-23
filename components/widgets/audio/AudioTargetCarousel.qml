pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import ".."
import "../../../core/interaction"
import "../../primitives/text"

Item {
    id: widget
    property var model: []
    property string title: ""
    property string selectedKey: ""
    property string zoneId: ""
    property string layerName: "dashboard"
    property int orientation: Qt.Horizontal
    property bool cyclic: false
    property bool defaultFocus: false
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property var iconsPadManager: null
    readonly property var selectedTarget: model.find(target => target.key === selectedKey) ?? null
    readonly property alias focusZone: zone
    signal volumeRequested(string key, real value)
    signal muteRequested(string key, bool muted)
    signal activationRequested(string key)
    signal optionsRequested(string key, Item source)
    implicitWidth: 400
    implicitHeight: orientation === Qt.Vertical ? 520 : 210
    function tr(key, fallback) { return i18n ? i18n.t(key, fallback) : fallback }
    function sync() {
        if (!model.some(target => target.key === selectedKey)) selectedKey = (model.find(target => target.active) ?? model[0])?.key ?? ""
        const same = stableModel.count === model.length && model.every((target, index) => stableModel.get(index).key === target.key)
        if (!same) stableModel.clear()
        for (let index = 0; index < model.length; index++) {
            if (same) stableModel.set(index, model[index])
            else stableModel.append(model[index])
        }
        zone.currentSubIndex = Math.max(0, model.findIndex(target => target.key === selectedKey))
    }
    onModelChanged: sync()
    Component.onCompleted: sync()
    ListModel { id: stableModel }
    SectionTitle {
        id: heading
        width: parent.width
        title: widget.title
        subtitle: widget.selectedTarget?.title ?? widget.tr("audio.empty", "No audio targets")
        styleTokens: widget.styleTokens
    }
    FocusZone {
        id: zone
        anchors.top: heading.bottom
        anchors.topMargin: Theme.spacingS
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        zoneId: widget.zoneId
        layerName: widget.layerName
        layerManager: widget.layerManager
        navigationManager: widget.navigationManager
        defaultFocus: widget.defaultFocus
        subItemCount: widget.model.length
        showFocusRing: false
        actionHints: widget.selectedTarget ? [
            {action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle"},
            {action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle"},
            {action: "I.PressStick.R", labelKey: "audio.mute", fallback: "Mute"}
        ].concat(widget.selectedTarget.kind === "app" ? [] : [
            {action: "I.Accept", labelKey: "audio.activate", fallback: "Activate"},
            {action: "I.Options", labelKey: "audio.options", fallback: "Device options"}
        ]) : []
        onSubItemCycled: index => { widget.selectedKey = widget.model[index]?.key ?? "" }
        onActivated: { if (widget.selectedTarget?.kind !== "app" && widget.selectedTarget) widget.activationRequested(widget.selectedKey) }
        onOptionsTriggered: { if (widget.selectedTarget?.hasOptions) widget.optionsRequested(widget.selectedKey, carousel.selectedItem) }
        CarouselView {
            id: carousel
            objectName: "audio-target-carousel"
            anchors.fill: parent
            orientation: widget.orientation
            cyclic: widget.cyclic
            model: stableModel
            currentIndex: zone.currentSubIndex
            maxVisibleItems: widget.orientation === Qt.Vertical ? 5 : 3
            cardWidth: widget.orientation === Qt.Vertical ? Math.max(250, widget.width * 0.66) : 140
            selectedWidth: widget.orientation === Qt.Vertical ? Math.max(290, widget.width * 0.80) : 210
            cardHeight: widget.orientation === Qt.Vertical ? 66 : 104
            selectedHeight: widget.orientation === Qt.Vertical ? 90 : 130
            spacing: Theme.spacingS
            motionTokens: widget.motionTokens
            focused: zone.active
            delegate: AudioTargetCard {
                property int index: 0
                density: carousel.layoutScale
                i18n: widget.i18n
                styleTokens: widget.styleTokens
                motionTokens: widget.motionTokens
                onChosen: {
                    if (!zone.requestZoneFocus()) return
                    widget.selectedKey = itemData.key
                    zone.currentSubIndex = index
                }
            }
        }
    }
}
