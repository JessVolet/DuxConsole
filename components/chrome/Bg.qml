import QtQuick

Item {
    id: bg

    // "default" | "sound" (en Sonido se abre más a la derecha para ver el juego)
    property string mode: "default"
    property var styleTokens: null

    anchors.fill: parent

    function _scrim(mult) {
        if (styleTokens)
            return styleTokens.scrimColor(mult)
        return Qt.rgba(0.04, 0.05, 0.08, 0.58 * mult)
    }

    // Scrim global único en gradiente horizontal (sin superponer múltiples scrims)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: bg._scrim(1.15) }
            GradientStop { position: 0.45; color: bg._scrim(bg.mode === "sound" ? 0.45 : 0.78) }
            GradientStop { position: 1.0; color: bg._scrim(bg.mode === "sound" ? 0.18 : 0.35) }
        }
    }
}
