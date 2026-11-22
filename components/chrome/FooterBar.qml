import QtQuick

Item {
    id: footer

    property var iconsPadManager: null
    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property var hints: []

    implicitWidth: hintsList.implicitWidth
    implicitHeight: hintsList.implicitHeight

    ActionHints {
        id: hintsList
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        iconsPadManager: footer.iconsPadManager
        styleTokens: footer.styleTokens
        motionTokens: footer.motionTokens
        i18n: footer.i18n
        hints: footer.hints
    }
}
