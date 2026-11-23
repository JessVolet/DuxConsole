pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../primitives/buttons"

FocusZone {
    id: filters

    property var options: []
    property int selectedIndex: 0
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property string filterLabel: ""
    property bool expanded: false

    function toggle() {
        if (requestZoneFocus())
            expanded = !expanded
    }

    signal picked(int optionIndex)

    implicitHeight: filterButton.height
    implicitWidth: row.implicitWidth
    subItemCount: options.length
    currentSubIndex: selectedIndex
    enabled: options.length > 1
    showFocusRing: false
    actionHints: [
        { action: "I.Accept", labelKey: "mockCollection.filter", fallback: "Filters" },
        { action: "I.ActionOption.L", labelKey: "mockCollection.filter", fallback: "Filters" },
        { action: "I.ActionOption.R", labelKey: "mockCollection.filter", fallback: "Filters" }
    ]

    onSubItemCycled: newIndex => picked(newIndex)
    onActivated: toggle()

    Row {
        id: row
        spacing: Theme.spacingS

        ActionButton {
            id: filterButton
            width: Math.max(140, filterMetrics.width + Theme.spacingXL * 2)
            height: 42
            skewAngle: 0
            radius: height / 2
            label: filters.filterLabel
            styleTokens: filters.styleTokens
            motionTokens: filters.motionTokens
            iconsPadManager: filters.iconsPadManager
            focused: filters.active

            TextMetrics {
                id: filterMetrics
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                text: filterButton.label
            }

            Accessible.role: Accessible.Button
            Accessible.name: label
            Accessible.ignored: filters.inert
            Accessible.onPressAction: filters.toggle()

            TapHandler {
                enabled: !filters.inert
                onTapped: filters.toggle()
            }
        }

        Repeater {
            model: filters.expanded ? filters.options : []

            ActionButton {
                id: optionButton
                required property int index
                required property var modelData

                width: Math.max(96, optionMetrics.width + Theme.spacingXL)
                height: 42
                skewAngle: 0
                radius: height / 2
                label: modelData.label
                styleTokens: filters.styleTokens
                motionTokens: filters.motionTokens
                selected: index === filters.selectedIndex

                TextMetrics {
                    id: optionMetrics
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    text: optionButton.label
                }

                Accessible.role: Accessible.Button
                Accessible.name: label
                Accessible.ignored: filters.inert
                Accessible.onPressAction: {
                    if (filters.requestZoneFocus())
                        filters.picked(index)
                }

                TapHandler {
                    enabled: !filters.inert
                    onTapped: {
                        if (filters.requestZoneFocus())
                            filters.picked(optionButton.index)
                    }
                }
            }
        }
    }
}
