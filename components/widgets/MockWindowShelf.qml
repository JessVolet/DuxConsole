pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import "../../core/interaction"
import "../primitives/text"

FocusZone {
    id: shelf

    property var entries: []
    property var selectedId
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    readonly property var currentEntry: entries[currentSubIndex] ?? null

    signal selectionRequested(var id)
    signal activationRequested(var id)
    signal optionsRequested(var id)

    zoneId: "mock-window-shelf"
    showFocusRing: false
    expandable: entries.length > 0
    subItemCount: entries.length
    actionHints: {
        if (!entries.length)
            return []
        const result = [
            { action: "I.Accept", labelKey: "windows.hint_focus", fallback: "Focus window" },
            { action: "I.Options", labelKey: "windows.hint_options", fallback: "Window options" }
        ]
        if (subItemCount > 1) {
            result.push(
                { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle item" },
                { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle item" }
            )
        }
        if (expandable)
            result.push({ action: "I.Select", labelKey: "hints.expand", fallback: "Expand" })
        return result
    }

    function tr(key, fallback) {
        return i18n?.t(key, fallback) ?? fallback
    }

    function detailsFor(entry) {
        const parts = []
        if (entry?.workspaceIndex >= 0)
            parts.push(tr("windows.workspace_prefix", "Workspace") + " " + entry.workspaceIndex)
        if (entry?.output)
            parts.push(entry.output)
        return parts.join(" · ")
    }

    function syncSelection() {
        const index = entries.findIndex(entry => entry.id === selectedId)
        currentSubIndex = index < 0 ? Math.min(Math.max(0, currentSubIndex), Math.max(0, entries.length - 1)) : index
    }

    onSelectedIdChanged: syncSelection()
    onEntriesChanged: syncSelection()
    onSubItemCycled: (index, delta) => selectionRequested(entries[index].id)
    onActivated: {
        if (currentEntry)
            activationRequested(currentEntry.id)
    }
    onOptionsTriggered: {
        if (currentEntry)
            optionsRequested(currentEntry.id)
    }

    Row {
        id: heading
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: Theme.spacingS

        StyledText {
            id: sectionTitle
            text: shelf.tr("home.windows_section", "Active Windows")
            font.pixelSize: Theme.fontSizeXLarge
            font.weight: Font.Bold
            color: shelf.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        }

        StyledText {
            anchors.baseline: sectionTitle.baseline
            text: shelf.tr("mockup.home.window_count", "%1 in this session").replace("%1", shelf.entries.length)
            font.pixelSize: Theme.fontSizeMedium
            color: shelf.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        }
    }

    QueueCarousel {
        cardControlContains: (card, point) => card?.optionsContain(point) ?? false
        id: deck
        anchors.top: heading.bottom
        anchors.topMargin: Theme.spacingM
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: Math.min(Theme.spacingXL * 3, shelf.width * 0.06)
        anchors.right: parent.right
        visible: shelf.entries.length > 0
        entries: shelf.entries
        selectedId: shelf.currentEntry?.id
        focused: shelf.active
        interactive: !shelf.inert && shelf.enabled
        motionTokens: shelf.motionTokens
        skewAngle: shelf.styleTokens?.skewAngle ?? -8
        spacing: Theme.spacingXL * 2.35
        visibleBudget: width < 600 ? 3 : (width < 850 ? 4 : 5)

        onCardClicked: id => {
            if (!shelf.requestZoneFocus())
                return
            if (shelf.currentEntry?.id === id)
                shelf.activationRequested(id)
            else
                shelf.selectionRequested(id)
        }

        cardDelegate: MockWindowCard {
            styleTokens: shelf.styleTokens
            motionTokens: shelf.motionTokens
            details: shelf.detailsFor(itemData)
            optionsLabel: shelf.tr("mockup.home.options", "Options")
            interactive: !shelf.inert && shelf.enabled
            onOptionsRequested: {
                if (shelf.requestZoneFocus() && itemData)
                    shelf.optionsRequested(itemData.id)
            }
        }
    }

    StatusMessage {
        anchors.verticalCenter: deck.verticalCenter
        anchors.left: parent.left
        width: parent.width
        visible: !shelf.entries.length
        text: shelf.tr("windows.empty", "No open windows")
        styleTokens: shelf.styleTokens
    }
}
