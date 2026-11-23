pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../primitives/buttons"

Flow {
    id: strip

    property var entries: []
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property bool vertical: false
    property bool interactive: true
    property int focusedIndex: -1
    property bool prominent: false
    signal invoked(int index)

    spacing: Theme.spacingS

    Repeater {
        model: strip.entries

        delegate: ActionButton {
            id: control

            required property int index
            required property var modelData

            width: strip.vertical ? strip.width : implicitWidth
            height: strip.prominent ? 78 : 44
            implicitWidth: Math.max(100, label.length * Theme.fontSizeMedium * 0.62 + Theme.spacingXL * 2)
            role: "card"
            radius: strip.prominent ? Theme.cornerRadius : height / 2
            skewAngle: strip.prominent ? (strip.styleTokens?.skewAngle ?? -8) : 0
            surfaceOpacity: 0.82
            styleTokens: strip.styleTokens
            motionTokens: strip.motionTokens
            iconsPadManager: strip.iconsPadManager
            action: control.modelData.glyph ?? ""
            label: control.modelData.label
            selected: control.modelData.selected ?? false
            focused: strip.focusedIndex === control.index
            disabled: control.modelData.disabled ?? false

            Accessible.role: Accessible.Button
            Accessible.name: label
            Accessible.ignored: !visible || !strip.interactive || control.disabled
            Accessible.focused: control.focused && !Accessible.ignored
            Accessible.onPressAction: {
                if (!control.Accessible.ignored)
                    strip.invoked(control.index)
            }

            TapHandler {
                enabled: strip.interactive && !control.disabled
                onTapped: strip.invoked(control.index)
            }
        }
    }
}
