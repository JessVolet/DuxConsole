import QtQuick
import qs.Common

Item {
    id: footer

    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property var hints: []

    implicitWidth: Math.min(hintsList.implicitWidth, parent ? parent.width - Theme.spacingXL * 2 : hintsList.implicitWidth)
    implicitHeight: hintsList.implicitHeight

    ActionHints {
        id: hintsList
        width: footer.width
        iconsPadManager: footer.iconsPadManager
        styleTokens: footer.styleTokens
        motionTokens: footer.motionTokens
        i18n: footer.i18n
        hints: footer.hints
    }
}
