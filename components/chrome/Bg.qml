import QtQuick
import QtQuick.Shapes

Item {
    id: bg

    // "default" | "sound" (sound keeps a softer vignette for the game side)
    property string mode: "default"
    property var styleTokens: null

    anchors.fill: parent

    function _scrim(mult) {
        if (styleTokens)
            return styleTokens.scrimColor(mult)
        return Qt.rgba(0.04, 0.05, 0.08, 0.58 * mult)
    }

    // Vignette: the center stays clear and the edges darken, so text over an
    // arbitrary window keeps contrast without hiding the whole background.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillGradient: RadialGradient {
                centerX: bg.width / 2
                centerY: bg.height / 2
                centerRadius: Math.min(bg.width, bg.height) * 0.20
                focalX: bg.width / 2
                focalY: bg.height / 2
                focalRadius: 0
                GradientStop { position: 0.0; color: bg._scrim(0.0) }
                GradientStop { position: 0.55; color: bg._scrim(bg.mode === "sound" ? 0.22 : 0.32) }
                GradientStop { position: 1.0; color: bg._scrim(bg.mode === "sound" ? 0.75 : 1.05) }
            }
            startX: 0
            startY: 0
            PathLine { x: bg.width; y: 0 }
            PathLine { x: bg.width; y: bg.height }
            PathLine { x: 0; y: bg.height }
            PathLine { x: 0; y: 0 }
        }
    }
}
