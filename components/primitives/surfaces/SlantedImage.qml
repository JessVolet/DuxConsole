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

    readonly property bool hasImage: source.toString() !== "" && img.status === Image.Ready
    readonly property bool isLoading: source.toString() !== "" && img.status === Image.Loading

    // Fondo fallback cuando no hay imagen lista
    SlantedSurface {
        anchors.fill: parent
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

    // Máscara estática siempre oculta para MultiEffect (evita toggles dinámicos de layer)
    SlantedSurface {
        id: maskShape
        anchors.fill: parent
        skewAngle: slantedImg.skewAngle
        radius: slantedImg.radius
        visible: false
        layer.enabled: true
    }

    // Imagen recta (sin shear) recortada con MultiEffect contra la máscara inclinada y redondeada
    Item {
        id: maskedContent
        anchors.fill: parent
        visible: slantedImg.hasImage
        layer.enabled: slantedImg.hasImage
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskShape
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
        anchors.fill: parent
        styleTokens: slantedImg.styleTokens
        motionTokens: slantedImg.motionTokens
        role: "card"
        skewAngle: slantedImg.skewAngle
        radius: slantedImg.radius
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
