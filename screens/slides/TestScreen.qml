import QtQuick
import qs.Common
import qs.Widgets
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/glyphs"
import "../../components/primitives/text"

ScreenBase {
    id: root
    screenId: "test1"
    title: root.i18n ? root.i18n.t("nav.home", "Home") : "Home"

    property int buttonClicks: 0
    property string lastModalSelection: ""
    readonly property bool modalOpen: root.layerManager?.topLayer === "modal"

    function tr(key, fallback) {
        return root.i18n ? root.i18n.t(key, fallback) : fallback
    }

    Column {
        id: mainColumn
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: root.top
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingL

        Row {
            spacing: Theme.spacingM

            TestText {
                label: root.tr("demo.title", "DuxConsole — ControlFriendly Demo")
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.inputManager?.lastAction
                      ? root.tr("demo.subtitle", "Last action") + ": " + root.inputManager.lastAction + " (" + root.inputManager.activeDevice + ")"
                      : ""
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.onSurfaceVariant
            }
        }

        // Zona 1: Botón simple (I.Accept)
        FocusZone {
            id: zoneButton
            zoneId: "zone-button"
            layerName: "dashboard"
            layerManager: root.layerManager
            navDown: zoneCarousel
            width: 340
            height: 64
            ringRadius: Theme.cornerRadius

            onActivated: root.buttonClicks += 1

            StyledRect {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: zoneButton.active ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    InputGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        iconsManager: root.iconsManager
                        action: "I.Accept"
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.buttonClicks > 0
                              ? root.tr("demo.button_clicked", "Button activated") + " (" + root.buttonClicks + ")"
                              : root.tr("demo.button_label", "Primary Action")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        color: Theme.onSurface
                    }
                }
            }
        }

        // Zona 2: Carrusel de 4 ítems (LT/RT) + expansión a modal (I.Select)
        Column {
            spacing: Theme.spacingS

            Row {
                spacing: Theme.spacingM

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tr("demo.carousel_title", "Quick Carousel (LT / RT)")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.onSurface
                }

                InputGlyph {
                    iconsManager: root.iconsManager
                    action: "I.ActionOption.L"
                }

                InputGlyph {
                    iconsManager: root.iconsManager
                    action: "I.ActionOption.R"
                }

                InputGlyph {
                    iconsManager: root.iconsManager
                    action: "I.Select"
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tr("hints.expand", "Expand")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.onSurfaceVariant
                }
            }

            FocusZone {
                id: zoneCarousel
                zoneId: "zone-carousel"
                layerName: "dashboard"
                layerManager: root.layerManager
                navUp: zoneButton
                subItemCount: 4
                width: carouselRow.implicitWidth + Theme.spacingM * 2
                height: 112
                ringRadius: Theme.cornerRadius

                onExpandRequested: root.layerManager?.push("modal")

                Row {
                    id: carouselRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    Repeater {
                        model: 4
                        delegate: StyledRect {
                            required property int index
                            readonly property bool selected: zoneCarousel.currentSubIndex === index

                            width: 140
                            height: 88
                            radius: Theme.cornerRadius
                            color: selected ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            border.width: selected ? 2 : 0
                            border.color: Theme.primary

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.tr("demo.item_prefix", "Item") + " #" + (index + 1)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: selected ? Theme.onPrimaryContainer : Theme.onSurface
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: selected && root.lastModalSelection !== ""
                                    text: root.lastModalSelection
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Barra inferior de hints
    Row {
        anchors.left: root.left
        anchors.bottom: root.bottom
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingL

        Row {
            spacing: Theme.spacingS
            InputGlyph { iconsManager: root.iconsManager; action: "I.Dpad.Up" }
            StyledText { anchors.verticalCenter: parent.verticalCenter; text: root.tr("hints.navigate", "Navigate"); color: Theme.onSurfaceVariant; font.pixelSize: Theme.fontSizeSmall }
        }

        Row {
            spacing: Theme.spacingS
            InputGlyph { iconsManager: root.iconsManager; action: "I.Accept" }
            StyledText { anchors.verticalCenter: parent.verticalCenter; text: root.tr("hints.accept", "Accept"); color: Theme.onSurfaceVariant; font.pixelSize: Theme.fontSizeSmall }
        }

        Row {
            spacing: Theme.spacingS
            InputGlyph { iconsManager: root.iconsManager; action: "I.Refuse" }
            StyledText { anchors.verticalCenter: parent.verticalCenter; text: root.tr("hints.back", "Back / Close"); color: Theme.onSurfaceVariant; font.pixelSize: Theme.fontSizeSmall }
        }
    }

    // Modal en capa "modal"
    Rectangle {
        id: modalBackdrop
        anchors.fill: parent
        visible: root.modalOpen
        color: Theme.withAlpha(Theme.surface, 0.72)

        StyledRect {
            id: modalCard
            anchors.centerIn: parent
            width: 360
            height: modalCol.implicitHeight + Theme.spacingXL * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHighest

            Column {
                id: modalCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingXL
                spacing: Theme.spacingM

                StyledText {
                    text: root.tr("demo.modal_title", "Item Options") + " (#" + (zoneCarousel.currentSubIndex + 1) + ")"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.onSurface
                }

                FocusZone {
                    id: modalOpt0
                    zoneId: "modal-opt-0"
                    layerName: "modal"
                    layerManager: root.layerManager
                    visible: root.modalOpen
                    navDown: modalOpt1
                    width: modalCol.width
                    height: 44
                    ringRadius: Theme.cornerRadius
                    onActivated: {
                        root.lastModalSelection = root.tr("demo.modal_option_1", "Launch")
                        root.layerManager?.pop()
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: modalOpt0.active ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: root.tr("demo.modal_option_1", "Launch")
                            color: Theme.onSurface
                        }
                    }
                }

                FocusZone {
                    id: modalOpt1
                    zoneId: "modal-opt-1"
                    layerName: "modal"
                    layerManager: root.layerManager
                    visible: root.modalOpen
                    navUp: modalOpt0
                    navDown: modalOpt2
                    width: modalCol.width
                    height: 44
                    ringRadius: Theme.cornerRadius
                    onActivated: {
                        root.lastModalSelection = root.tr("demo.modal_option_2", "Pin")
                        root.layerManager?.pop()
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: modalOpt1.active ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: root.tr("demo.modal_option_2", "Pin")
                            color: Theme.onSurface
                        }
                    }
                }

                FocusZone {
                    id: modalOpt2
                    zoneId: "modal-opt-2"
                    layerName: "modal"
                    layerManager: root.layerManager
                    visible: root.modalOpen
                    navUp: modalOpt1
                    width: modalCol.width
                    height: 44
                    ringRadius: Theme.cornerRadius
                    onActivated: {
                        root.lastModalSelection = root.tr("demo.modal_option_3", "Details")
                        root.layerManager?.pop()
                    }

                    StyledRect {
                        anchors.fill: parent
                        radius: Theme.cornerRadius
                        color: modalOpt2.active ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: root.tr("demo.modal_option_3", "Details")
                            color: Theme.onSurface
                        }
                    }
                }
            }
        }
    }
}
