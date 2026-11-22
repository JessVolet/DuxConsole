// En screens/slides/TestScreen.qml:
import QtQuick
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/text"

ScreenBase {
    id: root
    screenId: "test1"
    title: "Prueba"

    TestText {
        anchors.centerIn: parent
        label: root.inputManager?.lastAction
               ? root.inputManager.lastAction + " (" + root.inputManager.activeDevice + ")"
               : "Pulsa algo (G hold, G+E, flechas...)"
    }
}