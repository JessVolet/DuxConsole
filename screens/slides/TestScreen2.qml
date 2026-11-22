import QtQuick
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/text"

ScreenBase {
    screenId: "test2"
    title: "Prueba2"

    TestText {
        anchors.centerIn: parent
        label: "Texto2:D"
    }
}