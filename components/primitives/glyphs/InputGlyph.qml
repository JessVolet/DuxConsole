import QtQuick
import qs.Common
import qs.Widgets

StyledRect {
    id: glyphRoot

    property var iconsManager: null
    property string action: ""

    readonly property var resolved: {
        // Dependencia reactiva explícita de dispositivo y config para actualización en vivo
        const _dev = iconsManager?.inputManager?.activeDevice ?? ""
        const _cfg = iconsManager?.inputManager?.config ?? null
        void(_dev)
        void(_cfg)
        return (iconsManager && action)
            ? iconsManager.resolve(action)
            : ({ type: "key", label: action, source: "" })
    }

    readonly property bool useSvg: resolved.type === "svg"
        && resolved.source !== ""
        && svgIcon.status !== Image.Error

    implicitWidth: useSvg ? 24 : Math.max(26, keyLabel.implicitWidth + Theme.spacingS * 2)
    implicitHeight: 24
    radius: useSvg ? 0 : 6
    color: useSvg ? "transparent" : Theme.surfaceContainerHighest
    border.width: useSvg ? 0 : 1
    border.color: Theme.outlineVariant

    Image {
        id: svgIcon
        anchors.centerIn: parent
        width: 20
        height: 20
        visible: glyphRoot.useSvg
        source: glyphRoot.resolved.type === "svg" ? glyphRoot.resolved.source : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    StyledText {
        id: keyLabel
        anchors.centerIn: parent
        visible: !glyphRoot.useSvg
        text: glyphRoot.resolved.label
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.onSurface
    }
}
