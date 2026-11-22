import QtQuick

QtObject {
    readonly property var screens: [
        { id: "test1", label: "Inicio", icon: "home",      source: "../../screens/slides/TestScreen.qml" },
        { id: "test2", label: "Sonido", icon: "volume_up", source: "../../screens/slides/TestScreen2.qml" }
    ]
}