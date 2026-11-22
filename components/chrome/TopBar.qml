import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/surfaces"
import "../primitives/glyphs"

SlantedSurface {
    id: bar

    property var i18n: null
    property var iconsPadManager: null
    property var screens: []
    property int currentIndex: 0
    property string statusText: ""

    role: "chrome"
    implicitHeight: 52
    radius: Theme.cornerRadius

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingL
        spacing: Theme.spacingM

        InputGlyph {
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.L"
        }

        Repeater {
            model: bar.screens
            delegate: StyledRect {
                required property int index
                required property var modelData
                readonly property bool isCurrent: index === bar.currentIndex

                implicitWidth: tabLabel.implicitWidth + Theme.spacingL * 2
                implicitHeight: 32
                radius: Theme.cornerRadius
                color: isCurrent
                       ? (bar.styleTokens ? bar.styleTokens.accentColor : Theme.primary)
                       : "transparent"

                StyledText {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: bar.i18n
                          ? bar.i18n.t(modelData.labelKey ?? "", modelData.id ?? "")
                          : (modelData.id ?? "")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: isCurrent ? Font.Bold : Font.Medium
                    color: isCurrent
                           ? "#FFFFFF"
                           : (bar.styleTokens ? bar.styleTokens.onSurfaceColor("chrome") : (Theme.surfaceText ?? "#F2F4F8"))
                }
            }
        }

        InputGlyph {
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.R"
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.spacingL
        visible: bar.statusText !== ""
        text: bar.statusText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
        color: bar.styleTokens ? bar.styleTokens.onSurfaceColor("chrome") : (Theme.surfaceVariantText ?? "#9CA3AF")
    }
}
