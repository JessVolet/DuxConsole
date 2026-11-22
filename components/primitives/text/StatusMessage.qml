import QtQuick
import qs.Common
import qs.Widgets

StyledText {
    id: message

    property var styleTokens: null

    wrapMode: Text.Wrap
    font.pixelSize: Theme.fontSizeSmall
    color: styleTokens ? styleTokens.errorColor : (Theme.error ?? "#B00020")
}
