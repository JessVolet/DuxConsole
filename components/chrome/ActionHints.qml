import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/glyphs"
import "../primitives/surfaces"

SlantedSurface {
    id: hintsBar

    property var iconsPadManager: null
    property var i18n: null
    // Lista de { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }
    property var hints: []

    role: "card"
    implicitWidth: hintsRow.implicitWidth + Theme.spacingL * 2
    implicitHeight: Math.max(44, hintsRow.implicitHeight + Theme.spacingS * 2)
    radius: Theme.cornerRadius
    visible: hints.length > 0

    Row {
        id: hintsRow
        anchors.centerIn: parent
        spacing: Theme.spacingL

        Repeater {
            model: hintsBar.hints
            delegate: Row {
                required property var modelData
                spacing: Theme.spacingS

                InputGlyph {
                    iconsPadManager: hintsBar.iconsPadManager
                    styleTokens: hintsBar.styleTokens
                    action: modelData.action ?? ""
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: hintsBar.i18n
                          ? hintsBar.i18n.t(modelData.labelKey, modelData.fallback ?? "")
                          : (modelData.fallback ?? "")
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
