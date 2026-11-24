import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/text"

Column {
    id: hero

    property var styleTokens: null
    property var session: null
    property string fallbackTitle: ""
    property real scaleFactor: 1
    readonly property int titleSize: Math.round(Theme.fontSizeXXLarge * 4.0 * scaleFactor)
    default property alias actions: actionRow.data

    spacing: Theme.spacingS * scaleFactor

    DisplayTitle {
        width: hero.width
        styleTokens: hero.styleTokens
        text: hero.session?.titleLines?.length
            ? hero.session.titleLines.join("\n")
            : (hero.session?.title || hero.fallbackTitle)
        textFormat: Text.PlainText
        lineHeight: 0.94
        font.pixelSize: hero.titleSize
        font.weight: Font.Black
        font.letterSpacing: -0.045 * hero.titleSize
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
    }

    StyledText {
        width: hero.width
        visible: text.length > 0
        text: hero.session?.metadata?.join(" · ") ?? ""
        textFormat: Text.PlainText
        font.pixelSize: Math.round(Theme.fontSizeLarge * hero.scaleFactor)
        color: hero.styleTokens?.m3OnSurfaceVariant ?? Theme.onSurfaceVariant ?? Theme.surfaceText
        elide: Text.ElideRight
    }

    Row {
        id: actionRow
        spacing: Theme.spacingS
    }
}
