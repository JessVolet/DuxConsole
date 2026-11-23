pragma Singleton
import QtQuick

QtObject {
    readonly property color primary: "#ecd5ff"
    readonly property color secondary: "#c6b3e5"
    readonly property color tertiary: "#e2b4ca"
    readonly property color surface: "#100a1a"
    readonly property color surfaceContainerHigh: "#22192e"
    readonly property color surfaceContainerHighest: "#30243f"
    readonly property color surfaceText: "#fcf4ff"
    readonly property color surfaceVariantText: "#c6b7cf"
    readonly property color outlineVariant: "#655671"
    readonly property color error: "#ffb4ab"
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int spacingXL: 24
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeXLarge: 20
    readonly property int fontSizeXXLarge: 28
    readonly property int iconSize: 24
    readonly property int cornerRadius: 12

    function withAlpha(color, opacity) {
        return Qt.alpha(color, opacity)
    }
}
