pragma Singleton
import QtQuick

QtObject {
    readonly property real cornerRadius: 18
    readonly property color outlineVariant: "gray"
    readonly property color primary: "white"
    property color onPrimary
    readonly property color surface: "#130c0c"
    readonly property color surfaceContainer: "#201717"
    readonly property color surfaceContainerLow: "#191111"
    readonly property color surfaceContainerHigh: "#271d1d"
    readonly property color surfaceContainerHighest: "#2e2323"
    property color onSurface
    property color onSurfaceVariant
    readonly property color secondaryContainer: "#6b3836"
    property color onSecondaryContainer
    readonly property color outline: "#7f7372"
    readonly property color error: "#B00020"
    readonly property color surfaceText: "white"
    readonly property color surfaceVariantText: "gray"
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int spacingXL: 24
    readonly property int fontSizeXSmall: 10
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeXLarge: 22
    readonly property int fontSizeXXLarge: 28
    readonly property int fontSizeDisplay: 36
    readonly property int fontSizeDisplayLarge: 57

    Component.onCompleted: {
        onPrimary = "#1a1c1e"
        onSurface = "#f7e7e6"
        onSurfaceVariant = "#b6a8a7"
        onSecondaryContainer = "#ffc1bd"
    }
}
