import QtQuick
import qs.Common

Item {
    id: bg

    // "default" | "sound" (en Sonido se abre más a la derecha para ver el juego)
    property string mode: "default"

    anchors.fill: parent

    // Gradiente horizontal (izquierda densa -> derecha abierta)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.withAlpha(Theme.surface, 0.88) }
            GradientStop { position: 0.45; color: Theme.withAlpha(Theme.surface, bg.mode === "sound" ? 0.35 : 0.62) }
            GradientStop { position: 1.0; color: Theme.withAlpha(Theme.surface, bg.mode === "sound" ? 0.12 : 0.32) }
        }
    }

    // Gradiente vertical (arriba abierto -> abajo denso para hints y carruseles)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.65; color: Theme.withAlpha(Theme.surface, 0.25) }
            GradientStop { position: 1.0; color: Theme.withAlpha(Theme.surface, 0.85) }
        }
    }
}