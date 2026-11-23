import QtQuick
import qs.Common
import "../../core/interaction"
import "../../components/chrome"
import "../../components/widgets"

FocusZone {
    id: modal

    property var selectedEntry: null
    property var styleTokens: null
    property var motionTokens: null
    property string missingLabel: ""
    property string missingDescription: ""
    property var entries: []
    property int selectedIndex: 0

    signal picked(int itemIndex)

    anchors.fill: parent
    visible: selectedEntry !== null && layerManager?.topLayer === layerName
    enabled: visible
    layerName: "modal"
    defaultFocus: entries.length <= 1
    showFocusRing: false
    Accessible.role: Accessible.Dialog
    Accessible.ignored: !visible
    Accessible.name: selectedEntry?.title ?? ""

    MouseArea {
        anchors.fill: parent
        enabled: modal.visible
        onWheel: wheel => wheel.accepted = true
    }

    ModalPanel {
        anchors.fill: parent
        anchors.margins: Theme.spacingL
        styleTokens: modal.styleTokens

        AchievementDetail {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingL
            previewHeight: parent.height * 0.67
            entry: modal.selectedEntry
            missingLabel: modal.missingLabel
            missingDescription: modal.missingDescription
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
        }

        CollectionShelf {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingL
            height: parent.height * 0.17
            zoneId: modal.zoneId + "-strip"
            layerName: modal.layerName
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            visible: modal.entries.length > 1
            items: modal.entries
            detailsEnabled: false
            defaultFocus: true
            expandedNavigation: true
            selectedIndex: modal.selectedIndex
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
            onPicked: itemIndex => modal.picked(itemIndex)
            onOpenItem: itemIndex => modal.picked(itemIndex)
        }
    }
}
