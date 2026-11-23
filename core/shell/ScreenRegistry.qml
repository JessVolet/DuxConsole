import QtQuick

QtObject {
    readonly property var screens: [
        { id: "home",  labelKey: "nav.home",  icon: "home",            source: "../../screens/slides/HomeScreen.qml" },
        { id: "test1", labelKey: "nav.lab",   icon: "science",         source: "../../screens/slides/TestScreen.qml" },
        { id: "test2", labelKey: "nav.sound", icon: "volume_up",       source: "../../screens/slides/AudioScreen.qml" }
    ]
}
