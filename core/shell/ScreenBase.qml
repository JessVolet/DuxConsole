import QtQuick
import qs.Common

Item {
    id: screen

    property string screenId: ""
    property string title: ""
    property var inputManager: null
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
    property var registry: null
    property int currentSlideIndex: 0
    default property alias content: body.data

    anchors.fill: parent

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : (fallback ?? key)
    }

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
    }
}