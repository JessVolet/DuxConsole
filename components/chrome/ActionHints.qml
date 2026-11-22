import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/glyphs"
import "../primitives/surfaces"

Row {
    id: hintsBar

    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    // Lista de { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }
    property var hints: []

    spacing: Theme.spacingS
    layoutDirection: Qt.RightToLeft
    visible: hints.length > 0

    Repeater {
        model: hintsBar.hints
        delegate: SlantedSurface {
            id: hintCard
            required property var modelData

            role: "card"
            styleTokens: hintsBar.styleTokens
            motionTokens: hintsBar.motionTokens
            radius: Theme.cornerRadius
            opacity: 1.0
            implicitWidth: hintRow.implicitWidth + Theme.spacingM * 2
            implicitHeight: 38

            Row {
                id: hintRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                InputGlyph {
                    iconsPadManager: hintsBar.iconsPadManager
                    styleTokens: hintsBar.styleTokens
                    action: hintCard.modelData.action ?? ""
                }

                StyledText {
                    text: hintsBar.i18n
                          ? hintsBar.i18n.t(hintCard.modelData.labelKey, hintCard.modelData.fallback ?? "")
                          : (hintCard.modelData.fallback ?? "")
                    color: hintsBar.styleTokens
                           ? hintsBar.styleTokens.onSurfaceColor("card")
                           : (Theme.surfaceText ?? "#F2F4F8")
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }
            }
        }
    }
}
