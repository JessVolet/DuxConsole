pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/interaction"
import "../../components/chrome"
import "../../components/primitives/buttons"
import "../../components/widgets"

Item {
    id: modal

    property var command: null
    property var options: []
    property var telemetry: []
    property var layerManager: null
    property var navigationManager: null
    property var styleTokens: null
    property var motionTokens: null
    property string confirmLabel: ""
    property string cancelLabel: ""
    signal chosen(var value)
    signal cancelled()

    anchors.fill: parent
    visible: command !== null && layerManager?.topLayer === "modal"
    Accessible.role: Accessible.Dialog
    Accessible.name: command?.title ?? ""

    MouseArea {
        anchors.fill: parent
        enabled: modal.visible
        onWheel: wheel => wheel.accepted = true
    }

    ModalPanel {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacingXL * 2, 640)
        height: details.implicitHeight + Theme.spacingL * 2
        styleTokens: modal.styleTokens

        Column {
            id: details
            anchors.centerIn: parent
            width: parent.width - Theme.spacingL * 2
            spacing: Theme.spacingM

            CommandPreview {
                width: details.width
                height: implicitHeight
                command: modal.command
                telemetry: modal.telemetry
                styleTokens: modal.styleTokens
                motionTokens: modal.motionTokens
                borderWidth: 0
                surfaceOpacity: 0.75
            }

            Repeater {
                model: modal.options.length ? modal.options : [{ id: true, label: modal.confirmLabel }]

                FocusZone {
                    id: choice
                    required property int index
                    required property var modelData

                    width: details.width
                    height: 48
                    zoneId: "mock-wheel-choice-" + index
                    layerName: "modal"
                    layerManager: modal.layerManager
                    navigationManager: modal.navigationManager
                    defaultFocus: index === 0
                    showFocusRing: false
                    actionHints: [{ action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" }]
                    onActivated: modal.chosen(modelData.id)

                    ActionButton {
                        anchors.fill: parent
                        label: choice.modelData.label
                        focused: choice.active
                        styleTokens: modal.styleTokens
                        motionTokens: modal.motionTokens
                        Accessible.role: Accessible.Button
                        Accessible.name: label
                        Accessible.ignored: choice.inert
                        Accessible.onPressAction: {
                            if (choice.requestZoneFocus())
                                choice.activate()
                        }

                        TapHandler {
                            enabled: !choice.inert
                            onTapped: {
                                if (choice.requestZoneFocus())
                                    choice.activate()
                            }
                        }
                    }
                }
            }

            FocusZone {
                id: cancel
                width: details.width
                height: 48
                zoneId: "mock-wheel-cancel"
                layerName: "modal"
                layerManager: modal.layerManager
                navigationManager: modal.navigationManager
                showFocusRing: false
                onActivated: modal.cancelled()

                ActionButton {
                    anchors.fill: parent
                    label: modal.cancelLabel
                    focused: cancel.active
                    styleTokens: modal.styleTokens
                    motionTokens: modal.motionTokens
                    Accessible.role: Accessible.Button
                    Accessible.name: label
                    Accessible.ignored: cancel.inert
                    Accessible.onPressAction: {
                        if (cancel.requestZoneFocus())
                            cancel.activate()
                    }

                    TapHandler {
                        enabled: !cancel.inert
                        onTapped: {
                            if (cancel.requestZoneFocus())
                                cancel.activate()
                        }
                    }
                }
            }
        }
    }
}
