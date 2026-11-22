pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/buttons"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root
    screenId: "home"
    title: root.tr("nav.home", "Home")

    property int modalTargetWindowId: -1
    property string ipcErrorNotice: ""

    readonly property var activeTargetWindow: {
        if (windowCarousel.selectedWindow)
            return windowCarousel.selectedWindow
        const wins = root.windowManager ? root.windowManager.windows : []
        return wins.find(w => w.isFocused) ?? (wins.length > 0 ? wins[0] : null)
    }

    function errorText(code) {
        return root.tr("windows.errors." + code, root.tr("windows.errors.unknown", "The window action could not be completed."))
    }

    function _focusAndClose(winId) {
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

    Flow {
        id: mainGrid
        anchors.fill: parent
        spacing: Theme.spacingXL
        property bool stacked: width < 880

        // Columna izquierda: Superior (Inicio + Continuar) + Inferior (Carrusel de ventanas)
        Column {
            width: mainGrid.stacked
                   ? mainGrid.width
                   : Math.max(0, mainGrid.width - mediaSlot.width - mainGrid.spacing)
            spacing: Theme.spacingL

            // Superior izquierda: Título grande + app/juego activo + botón Continuar
            Column {
                width: parent.width
                spacing: Theme.spacingM

                DisplayTitle {
                    styleTokens: root.styleTokens
                    text: root.tr("nav.home", "Home")
                }

                SectionTitle {
                    styleTokens: root.styleTokens
                    title: root.activeTargetWindow
                           ? root.activeTargetWindow.appName
                           : root.tr("home.no_active_app", "No active application")
                    subtitle: root.ipcErrorNotice !== ""
                              ? root.ipcErrorNotice
                              : (root.activeTargetWindow ? root.activeTargetWindow.title : "")
                }

                FocusZone {
                    id: zoneContinue
                    zoneId: "home-continue"
                    layerName: "dashboard"
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    defaultFocus: true
                    enabled: root.activeTargetWindow !== null
                    actionHints: root.activeTargetWindow
                        ? [{ action: "I.Accept", labelKey: "home.continue", fallback: "Continue" }]
                        : []
                    width: btnContinue.width
                    height: btnContinue.height
                    ringRadius: Theme.cornerRadius

                    onActivated: {
                        if (root.activeTargetWindow)
                            root._focusAndClose(root.activeTargetWindow.id)
                    }

                    ActionButton {
                        id: btnContinue
                        enabled: zoneContinue.enabled
                        focused: zoneContinue.active
                        styleTokens: root.styleTokens
                        motionTokens: root.motionTokens
                        iconsPadManager: root.iconsPadManager
                        action: "I.Accept"
                        label: root.tr("home.continue", "Continue")
                    }
                }
            }

            // Zona central e inferior izquierda: Carrusel de ventanas reales
            Column {
                width: parent.width
                spacing: Theme.spacingS

                SectionTitle {
                    styleTokens: root.styleTokens
                    title: root.tr("home.windows_section", "Active Windows")
                }

                WindowCarousel {
                    id: windowCarousel
                    width: parent.width
                    windowManager: root.windowManager
                    windowIconProvider: root.windowIconProvider
                    layerManager: root.layerManager
                    navigationManager: root.navigationManager
                    styleTokens: root.styleTokens
                    motionTokens: root.motionTokens
                    i18n: root.i18n

                    onActivateWindowRequested: winId => root._focusAndClose(winId)
                    onWindowOptionsRequested: winId => {
                        root.ipcErrorNotice = ""
                        root.modalTargetWindowId = winId
                        root.layerManager?.push("modal")
                    }
                }
            }
        }

        // Derecha: Espacio reservado para MediaPlayerCard
        Item {
            id: mediaSlot
            width: mainGrid.stacked ? mainGrid.width : Math.min(340, mainGrid.width * 0.28)
            height: 240

            MediaPlayerCard {
                anchors.top: parent.top
                anchors.right: parent.right
                width: parent.width
                height: parent.height
                styleTokens: root.styleTokens
                motionTokens: root.motionTokens
                i18n: root.i18n
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
