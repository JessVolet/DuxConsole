import QtQuick
import qs.Common

Item {
    id: screen

    property string screenId: ""
    property string title: ""
    property var inputManager: null
    property var layerManager: null
    property var iconsManager: null
    property var i18n: null
    default property alias content: body.data

    anchors.fill: parent

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: Theme.spacingXL
    }
}