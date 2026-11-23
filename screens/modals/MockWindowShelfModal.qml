pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../components/primitives/text"
import "../../components/widgets"

FixtureModalFrame {
    id: modal

    property var entries: []
    property var selectedId
    property var layerManager: null
    property var navigationManager: null
    property var motionTokens: null
    property string header: ""
    property string optionsLabel: ""

    signal activationRequested(var id)
    signal optionsRequested(var id)

    preferredWidth: width
    preferredHeight: height
    accessibleLabel: header
    visible: layerManager?.stack.includes("mock-windows") ?? false

    DisplayTitle {
        id: modalTitle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Theme.spacingXL
        width: parent.width - Theme.spacingXL * 2
        styleTokens: modal.styleTokens
        text: modal.header
        elide: Text.ElideRight
    }

    Flickable {
        id: windowList
        anchors.top: modalTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXL
        clip: true
        contentWidth: width
        contentHeight: grid.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        interactive: modal.layerManager?.topLayer === "mock-windows"

        MockWindowGrid {
            id: grid
            width: parent.width
            entries: modal.visible ? modal.entries : []
            selectedId: modal.selectedId
            layerManager: modal.layerManager
            navigationManager: modal.navigationManager
            styleTokens: modal.styleTokens
            motionTokens: modal.motionTokens
            optionsLabel: modal.optionsLabel
            onActivationRequested: id => modal.activationRequested(id)
            onOptionsRequested: id => modal.optionsRequested(id)
            onActiveRowChanged: (top, rowHeight) => {
                if (top < windowList.contentY)
                    windowList.contentY = top
                else if (top + rowHeight > windowList.contentY + windowList.height)
                    windowList.contentY = top + rowHeight - windowList.height
            }
        }
    }
}
