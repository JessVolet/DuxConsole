import QtQuick

QtObject {
    readonly property var screens: [
        { id: "test1", labelKey: "nav.home",  icon: "home",      source: "../../screens/slides/TestScreen.qml" },
        { id: "test2", labelKey: "nav.sound", icon: "volume_up", source: "../../screens/slides/TestScreen2.qml" }
    ]
}
