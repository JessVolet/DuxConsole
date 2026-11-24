pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Common
import "../../../core/interaction"
import "../../primitives/text"

// Material 3 replacement for the audio carousels: one list of rows per zone.
// LT/RT cycle the selection, A activates devices, Y opens supported options.
Item {
    id: widget

    property var model: []
    property string title: ""
    property string selectedKey: ""
    property string zoneId: ""
    property string layerName: "dashboard"
    property string iconKind: "app"
    property bool defaultFocus: false
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property var iconsPadManager: null

    readonly property var selectedTarget: model.find(target => target.key === selectedKey) ?? null
    readonly property alias focusZone: zone
    readonly property int selectedIndex: model.findIndex(target => target.key === selectedKey)
    readonly property Item selectedItem: selectedIndex >= 0 ? rows.itemAt(selectedIndex) : null

    signal volumeRequested(string key, real value)
    signal muteRequested(string key, bool muted)
    signal activationRequested(string key)
    signal optionsRequested(string key, Item source)

    implicitWidth: 400
    implicitHeight: 240

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    function sync() {
        if (!model.some(target => target.key === selectedKey))
            selectedKey = (model.find(target => target.active) ?? model[0])?.key ?? ""
        const same = stable.count === model.length && model.every((target, index) => stable.get(index).key === target.key)
        if (!same)
            stable.clear()
        for (let index = 0; index < model.length; index++) {
            if (same)
                stable.set(index, model[index])
            else
                stable.append(model[index])
        }
        const selected = model.findIndex(target => target.key === selectedKey)
        if (selected >= 0 && zone.currentSubIndex !== selected)
            zone.currentSubIndex = selected
        Qt.callLater(() => widget.reveal(selected))
    }

    function reveal(index) {
        if (index < 0 || viewport.height <= 0)
            return
        const row = rows.itemAt(index)
        if (!row)
            return
        if (row.y < viewport.contentY)
            viewport.contentY = Math.max(0, row.y)
        else if (row.y + row.height > viewport.contentY + viewport.height)
            viewport.contentY = Math.min(Math.max(0, content.implicitHeight - viewport.height),
                row.y + row.height - viewport.height)
    }

    function iconFor(data) {
        if (!data)
            return ""
        if (widget.iconKind === "app")
            return data.appId ? Quickshell.iconPath(data.appId, true) : ""
        if (widget.iconKind === "output")
            return Quickshell.iconPath("audio-speakers-symbolic", true)
        return Quickshell.iconPath("audio-input-microphone-symbolic", true)
    }

    function trailingFor(data) {
        if (!data)
            return ""
        const parts = [data.muted ? tr("audio.muted", "Muted") : Math.round(data.volume * 100) + "%"]
        if (data.active)
            parts.push(tr("audio.active", "Active"))
        if (data.pinned)
            parts.push(tr("audio.pinned", "Pinned"))
        return parts.join(" · ")
    }

    onModelChanged: sync()
    onSelectedKeyChanged: {
        const selected = model.findIndex(target => target.key === selectedKey)
        if (selected >= 0 && zone.currentSubIndex !== selected)
            zone.currentSubIndex = selected
        reveal(selected)
    }
    Component.onCompleted: sync()

    ListModel { id: stable }

    SectionTitle {
        id: heading
        width: parent.width
        title: widget.title
        subtitle: widget.selectedTarget?.title ?? widget.tr("audio.empty", "No audio targets")
        titleSize: Theme.fontSizeLarge
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
            { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.PressStick.R", labelKey: "audio.mute", fallback: "Mute" }
        ].concat(widget.selectedTarget.kind === "app" ? [] : [
            { action: "I.Accept", labelKey: "audio.activate", fallback: "Activate" },
            { action: "I.Options", labelKey: "audio.options", fallback: "Device options" }
        ]) : []
        onSubItemCycled: index => { widget.selectedKey = widget.model[index]?.key ?? "" }
        onActivated: { if (widget.selectedTarget?.kind !== "app" && widget.selectedTarget) widget.activationRequested(widget.selectedKey) }
        onOptionsTriggered: { if (widget.selectedTarget?.hasOptions) widget.optionsRequested(widget.selectedKey, widget.selectedItem) }

        Flickable {
            id: viewport
            anchors.fill: parent
            contentWidth: width
            contentHeight: content.implicitHeight
            clip: true
            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            onHeightChanged: widget.reveal(widget.selectedIndex)

            Column {
                id: content
                width: viewport.width
                spacing: 6

                Repeater {
                    id: rows
                    model: stable

                    delegate: AudioListItem {
                        required property int index

                        readonly property var itemData: stable.get(index)

                        width: content.width
                        title: itemData?.title ?? widget.tr("audio.unavailable", "Unavailable")
                        subtitle: itemData?.kind === "app" ? (itemData?.subtitle ?? "") : ""
                        trailing: widget.trailingFor(itemData)
                        iconSource: widget.iconFor(itemData)
                        iconTinted: widget.iconKind !== "app"
                        fallbackText: (itemData?.title ?? "?").charAt(0).toUpperCase()
                        selected: widget.selectedKey === (itemData?.key ?? "")
                        focused: zone.active
                        onChosen: {
                            if (!zone.requestZoneFocus())
                                return
                            widget.selectedKey = itemData?.key ?? ""
                            zone.currentSubIndex = index
                        }
                    }
                }
            }
        }
    }
}
