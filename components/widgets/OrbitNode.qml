import QtQuick
import qs.Common
import qs.DCommon.Widgets as DCommon

Rectangle {
    id: node

    property string iconName: ""
    property string label: ""
    property var styleTokens: null
    property var motionTokens: null
    property bool selected: false
    property bool focused: false
    property bool interactive: true
    signal triggered()

    radius: width / 2
    color: selected ? (styleTokens?.surfaceColor("card") ?? Theme.surfaceContainerHighest) : "transparent"
    border.width: focused ? 3 : (selected ? 1 : 0)
    border.color: styleTokens?.accentColor ?? Theme.primary

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.ignored: !interactive
    Accessible.onPressAction: {
        if (interactive)
            triggered()
    }

    DCommon.DIcon {
        anchors.centerIn: parent
        name: node.iconName
        size: Math.round(node.width * 0.46)
        color: node.styleTokens?.onSurfaceColor(node.selected ? "card" : "chrome") ?? Theme.surfaceText
    }

    TapHandler {
        enabled: node.interactive
        onTapped: node.triggered()
    }

    Behavior on color {
        ColorAnimation {
            duration: node.motionTokens?.durationFast ?? 0
            easing.type: node.motionTokens?.easingSnappy ?? Easing.OutCubic
        }
    }
}
