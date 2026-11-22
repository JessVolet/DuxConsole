import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/glyphs"

Row {
    id: hintsBar

    property var iconsPadManager: null
    property var i18n: null
    // Lista de { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }
    property var hints: []

    spacing: Theme.spacingL

    Repeater {
        model: hintsBar.hints
        delegate: Row {
            required property var modelData
            spacing: Theme.spacingS

            InputGlyph {
                anchors.verticalCenter: parent.verticalCenter
                iconsPadManager: hintsBar.iconsPadManager
                action: modelData.action ?? ""
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: hintsBar.i18n
                      ? hintsBar.i18n.t(modelData.labelKey, modelData.fallback ?? "")
                      : (modelData.fallback ?? "")
                color: Theme.onSurfaceVariant
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
