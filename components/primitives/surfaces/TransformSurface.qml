pragma ComponentBehavior: Bound
import QtQuick
import "../../../core/motion"

ContainerTransform {
    id: container
    property var styleTokens: null
    property string shape: config.shape ?? "slanted"
    property real sourceAngle: shape === "slanted" && styleTokens ? styleTokens.skewAngle : 0
    property real targetAngle: sourceAngle
    property real sourceRadius: config.radius ?? 18
    property real targetRadius: sourceRadius
    property real contentPadding: config.padding ?? 20
    property Component originContent: null
    property size originContentSize: Qt.size(sourceRect.width, sourceRect.height)
    default property alias content: surface.content

    property SlantedSurface surfaceItem: SlantedSurface {
        id: surface
        parent: container
        anchors.fill: parent
        contained: true
        contentPadding: container.contentPadding
        styleTokens: container.styleTokens
        motionTokens: container.motionTokens
        skewAngle: container.shape === "slanted"
            ? container.sourceAngle + (container.targetAngle - container.sourceAngle) * container.progress : 0
        radius: container.shape === "rectangle" ? 0
            : container.sourceRadius + (container.targetRadius - container.sourceRadius) * container.progress
    }

    property Loader originLoader: Loader {
        parent: container
        active: container.originContent !== null && (container.expanded || container.progress > 0)
        x: container.anchorOffset.x - width / 2
        y: container.anchorOffset.y - height / 2
        width: container.originContentSize.width
        height: container.originContentSize.height
        sourceComponent: container.originContent
    }
}
