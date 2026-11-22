import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets

StyledRect {
    id: glyphRoot

    property var iconsPadManager: null
    property var styleTokens: null
    property string action: ""
    property bool badge: false
    property bool onLightSurface: false

    readonly property var resolved: {
        // Dependencia reactiva explícita de dispositivo, configs y estilo de iconos
        const _dev = iconsPadManager?.inputManager?.activeDevice ?? ""
        const _inCfg = iconsPadManager?.inputManager?.config ?? null
        const _icCfg = iconsPadManager?.iconsConfig ?? null
        const _cm = styleTokens?.iconColorMode ?? ""
        const _st = styleTokens?.iconStyle ?? ""
        const _bd = styleTokens?.iconShowBackdrop ?? true
        void(_dev)
        void(_inCfg)
        void(_icCfg)
        void(_cm)
        void(_st)
        void(_bd)
        return (iconsPadManager && action)
            ? iconsPadManager.resolve(action)
            : ({
                type: "key",
                label: action,
                source: "",
                isMonochrome: true,
                colorMode: "dms",
                showBackdrop: true
            })
    }

    readonly property bool useSvg: resolved.type === "svg"
        && resolved.source !== ""
        && svgIcon.status !== Image.Error

    readonly property bool showBadge: badge || Boolean(resolved.showBackdrop)
    readonly property bool tintActive: useSvg && Boolean(resolved.isMonochrome)

    readonly property color tintColor: {
        if (resolved.colorMode === "custom")
            return styleTokens?.iconCustomColor ?? "#FFFFFF"
        if (resolved.colorMode === "dms")
            return styleTokens ? styleTokens.accentColor : Theme.primary
        if (showBadge)
            return "#F2F4F8"
        return onLightSurface ? "#14161D" : "#F2F4F8"
    }

    implicitWidth: useSvg
        ? (showBadge ? 28 : 22)
        : Math.max(26, keyLabel.implicitWidth + Theme.spacingS * 2)
    implicitHeight: useSvg ? (showBadge ? 28 : 22) : 24
    radius: useSvg ? (showBadge ? height / 2 : 0) : 6
    color: useSvg
        ? (showBadge ? Qt.rgba(0.06, 0.07, 0.10, 0.76) : "transparent")
        : Theme.surfaceContainerHighest
    border.width: useSvg ? (showBadge ? 1 : 0) : 1
    border.color: useSvg ? Qt.rgba(1, 1, 1, 0.16) : Theme.outlineVariant

    Image {
        id: svgIcon
        anchors.centerIn: parent
        width: 20
        height: 20
        sourceSize.width: 20
        sourceSize.height: 20
        visible: glyphRoot.useSvg && !glyphRoot.tintActive
        source: glyphRoot.resolved.type === "svg" ? glyphRoot.resolved.source : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    MultiEffect {
        anchors.fill: svgIcon
        source: svgIcon
        visible: glyphRoot.tintActive
        colorization: 1.0
        colorizationColor: glyphRoot.tintColor
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
