pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets

Item {
    id: slantedImg

    property var styleTokens: null
    property var motionTokens: null
    property url source: ""
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property real radius: Theme.cornerRadius
    property int fillMode: Image.PreserveAspectCrop
    property bool focused: false
    property bool selected: false
    property bool disabled: !enabled
    property bool showGradientOverlay: true
    property string fallbackText: ""
    default property alias overlayContent: overlayContainer.data

    readonly property bool supportsLayerMask: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property bool hasImage: source.toString() !== "" && img.status === Image.Ready
    readonly property bool isLoading: source.toString() !== "" && img.status === Image.Loading
    readonly property real _skewPad: Math.min(width * 0.25, Math.abs(Math.tan(skewAngle * Math.PI / 180)) * height)
    readonly property real _innerX: skewAngle < 0 ? _skewPad : 0
    readonly property real _innerWidth: Math.max(1, width - _skewPad)

    // Fondo fallback cuando no hay imagen lista
    SlantedSurface {
        x: slantedImg._innerX
        y: 0
        width: slantedImg._innerWidth
        height: slantedImg.height
        styleTokens: slantedImg.styleTokens
        motionTokens: slantedImg.motionTokens
        role: "card"
        skewAngle: slantedImg.skewAngle
        radius: slantedImg.radius
        focused: slantedImg.focused
        selected: slantedImg.selected
        disabled: slantedImg.disabled
        visible: !slantedImg.hasImage
    }

    // Máscara estática dentro del bounding box completo para evitar recorte de esquinas inclinadas
    Item {
        id: maskWrapper
        anchors.fill: parent
        visible: false
        layer.enabled: slantedImg.supportsLayerMask

        SlantedSurface {
            id: maskShape
            x: slantedImg._innerX
            y: 0
            width: slantedImg._innerWidth
            height: slantedImg.height
            skewAngle: slantedImg.skewAngle
            radius: slantedImg.radius
        }
    }

    // Imagen recta (sin shear) recortada con MultiEffect contra la máscara inclinada y redondeada
    Item {
        id: maskedContent
        anchors.fill: parent
        visible: slantedImg.hasImage
        // Keep artwork visible when the software renderer cannot apply the shader mask.
        clip: !slantedImg.supportsLayerMask
        layer.enabled: slantedImg.hasImage && slantedImg.supportsLayerMask
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskWrapper
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.2
        }

        Image {
            id: img
            anchors.fill: parent
            source: slantedImg.source
            fillMode: slantedImg.fillMode
            asynchronous: true
            smooth: true
        }

        Rectangle {
            anchors.fill: parent
            visible: slantedImg.showGradientOverlay
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.18) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
            }
        }
    }

    // Borde superior de enfoque/selección sobre la imagen recortada
    SlantedSurface {
        x: slantedImg._innerX
        y: 0
        width: slantedImg._innerWidth
        height: slantedImg.height
        styleTokens: slantedImg.styleTokens
        motionTokens: slantedImg.motionTokens
        role: "card"
        skewAngle: slantedImg.skewAngle
        radius: slantedImg.radius
        borderOnly: true
        focused: slantedImg.focused
        selected: slantedImg.selected
        disabled: slantedImg.disabled
        visible: slantedImg.hasImage && (slantedImg.focused || slantedImg.selected)
    }

    // Fallback cuando no hay imagen o está cargando
    StyledText {
        anchors.centerIn: parent
        visible: !slantedImg.hasImage && slantedImg.fallbackText !== ""
        text: slantedImg.isLoading ? "..." : slantedImg.fallbackText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: slantedImg.styleTokens ? slantedImg.styleTokens.onSurfaceColor("card") : (Theme.surfaceVariantText ?? "#9CA3AF")
    }

    Item {
        id: overlayContainer
        anchors.fill: parent
    }
}
