import QtQuick

QtObject {
    property bool fixtureMode: false
    readonly property url wheelSource: fixtureMode ? Qt.resolvedUrl("../../screens/overlays/OrbitalMenu.qml") : ""
    readonly property var screens: fixtureMode ? [
        { id: "home", labelKey: "nav.home", source: "../../screens/slides/MockHomeScreen.qml" },
        { id: "audio", labelKey: "nav.sound", source: "../../screens/slides/AudioScreen.qml" },
        { id: "capture", labelKey: "nav.capture", source: "../../screens/slides/CaptureScreen.qml" },
        { id: "launcher", labelKey: "nav.launcher", source: "../../screens/slides/LauncherScreen.qml" },
        { id: "achievements", labelKey: "nav.achievements", source: "../../screens/slides/AchievementsScreen.qml" }
    ] : [
        { id: "home",  labelKey: "nav.home",  icon: "home",            source: "../../screens/slides/HomeScreen.qml" },
        { id: "test1", labelKey: "nav.lab",   icon: "science",         source: "../../screens/slides/TestScreen.qml" },
        { id: "test2", labelKey: "nav.sound", icon: "volume_up",       source: "../../screens/slides/TestScreen2.qml" }
    ]
}
