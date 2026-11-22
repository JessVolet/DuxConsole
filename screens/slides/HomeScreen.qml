pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root
    screenId: "home"
    title: root.tr("nav.home", "Home")

    property int modalTargetWindowId: -1
    property string ipcErrorNotice: ""
    readonly property bool compactLayout: width < 900 || height < 520
    readonly property var selectedWindow: windowCarousel.selectedWindow

    function errorText(code) {
        return root.tr("windows.errors." + code, root.tr("windows.errors.unknown", "The window action could not be completed."))
    }

    function selectedWindowDescription(win) {
        if (!win)
            return root.tr("windows.empty", "No open windows")

        const details = []
        if (win.workspaceIndex >= 0)
            details.push(root.tr("windows.workspace_prefix", "Workspace") + " " + win.workspaceIndex)
        if (win.output)
            details.push(root.tr("windows.output_prefix", "Display") + " " + win.output)
        return details.length > 0 ? details.join(" · ") : root.tr("home.no_active_app", "No active application")
    }

    function focusAndClose(winId) {
        if (winId < 0 || !root.windowManager)
            return
        root.ipcErrorNotice = ""
        root.windowManager.focusWindow(winId, (ok, err) => {
            if (ok)
                root.closeOverlayRequested()
            else
                root.ipcErrorNotice = root.errorText(String(err))
        })
    }

    Column {
        id: pageLayout
        anchors.fill: parent
        spacing: Theme.spacingL

        Item {
            id: selectedWindowArea
            width: pageLayout.width
            height: pageLayout.height * (root.compactLayout ? 0.60 : 0.52)

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(parent.width * (root.compactLayout ? 0.9 : 0.48), 760)
                spacing: Theme.spacingM

                WindowInfoCards {
                    id: windowInfoCards
                    width: parent.width
                    height: Math.min(implicitHeight, selectedWindowArea.height)
                    windowData: root.selectedWindow
                    i18n: root.i18n
                    compact: root.compactLayout
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                }

                StatusMessage {
                    visible: root.ipcErrorNotice !== ""
                    width: parent.width
                    text: root.ipcErrorNotice
                    styleTokens: root.styleTokens
                }
            }
        }

        Flow {
            id: bottomRegion
            width: pageLayout.width
            height: Math.max(0, pageLayout.height - selectedWindowArea.height - pageLayout.spacing)
            spacing: Theme.spacingM
            property bool stacked: root.compactLayout

            Item {
                id: carouselSlot
                width: bottomRegion.stacked
                       ? bottomRegion.width
                       : Math.max(0, bottomRegion.width - mediaSlot.width - bottomRegion.spacing)
                height: bottomRegion.stacked
                        ? Math.min(windowCarousel.implicitHeight, bottomRegion.height * 0.56)
                        : bottomRegion.height

                WindowCarousel {
                    id: windowCarousel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.min(implicitHeight, parent.height)
                    iconOnly: true
                    defaultFocus: true
                    windowManager: root.windowManager
                    windowIconProvider: root.windowIconProvider
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    i18n: root.i18n

                    onActivateWindowRequested: winId => root.focusAndClose(winId)
                    onWindowOptionsRequested: winId => {
                        root.ipcErrorNotice = ""
                        root.modalTargetWindowId = winId
                        root.layerManager?.push("modal")
                    }
                }
            }

            Item {
                id: mediaSlot
                width: bottomRegion.stacked
                       ? bottomRegion.width
                       : Math.min(340, bottomRegion.width * 0.30)
                height: bottomRegion.stacked
                        ? Math.max(0, bottomRegion.height - carouselSlot.height - bottomRegion.spacing)
                        : bottomRegion.height

                MediaPlayerCard {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: bottomRegion.stacked ? parent.height : Math.min(240, parent.height)
                    compact: bottomRegion.stacked
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    i18n: root.i18n
                }
            }
        }
    }

    WindowActionsModal {
        windowManager: root.windowManager
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        iconsPadManager: root.iconsPadManager
        i18n: root.i18n
        targetWindowId: root.modalTargetWindowId
    }
}
