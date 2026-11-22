import QtQuick
import qs.Common

Item {
    id: slantedImg

    property var styleTokens: null
    property url source: ""
    property real skewAngle: styleTokens ? styleTokens.skewAngle : -8
    property real radius: Theme.cornerRadius
    property int fillMode: Image.PreserveAspectCrop

    readonly property real _shearX: Math.tan(skewAngle * Math.PI / 180)

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: slantedImg.radius
        color: "transparent"
        clip: true
        antialiasing: true

        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(
                1, slantedImg._shearX, 0, 0,
                0, 1,                  0, 0,
                0, 0,                  1, 0,
                0, 0,                  0, 1
            )
        }

        Image {
            anchors.fill: parent
            source: slantedImg.source
            fillMode: slantedImg.fillMode
            smooth: true
        }
    }
}
