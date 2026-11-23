pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon
import "../primitives/meters"
import "../primitives/surfaces"
import "../primitives/text"

SlantedSurface {
    id: preview

    property var command: null
    property var telemetry: []
    property string positionLabel: ""
    property string currentValue: ""
    property var choices: []
    property int chosenIndex: -1
    property var companionRows: []
    property real level: -1
    property bool meterOnLeft: false

    readonly property bool showMeter: level >= 0 && width >= 460
    readonly property real meterSize: 140

    skewAngle: 0
    implicitHeight: Math.max(contents.implicitHeight, showMeter ? meterSize : 0) + Theme.spacingL * 2
    surfaceOpacity: 1.08

    Column {
        id: contents
        width: parent.width - Theme.spacingL * 2 - (preview.showMeter ? preview.meterSize + Theme.spacingM : 0)
        x: Theme.spacingL + (preview.showMeter && preview.meterOnLeft ? preview.meterSize + Theme.spacingM : 0)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        Flow {
            width: contents.width
            spacing: Theme.spacingS
            visible: preview.telemetry.length > 0

            Repeater {
                model: preview.telemetry

                SlantedSurface {
                    id: chip
                    required property string modelData
                    width: chipLabel.implicitWidth + Theme.spacingM * 2
                    height: 28
                    radius: height / 2
                    skewAngle: 0
                    role: "card"
                    styleTokens: preview.styleTokens

                    StyledText {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: chip.modelData
                        font.pixelSize: Theme.fontSizeSmall
                        color: preview.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
                    }
                }
            }
        }

        Row {
            width: contents.width
            spacing: Theme.spacingL

            SlantedSurface {
                id: iconSurface
                anchors.verticalCenter: parent.verticalCenter
                width: 68
                height: width
                role: "selectedCard"
                skewAngle: 0
                styleTokens: preview.styleTokens

                DCommon.DIcon {
                    anchors.centerIn: parent
                    name: preview.command?.icon ?? ""
                    size: 30
                    color: preview.styleTokens?.accentColor ?? Theme.primary
                }
            }

            Column {
                width: Math.max(0, contents.width - iconSurface.width - Theme.spacingL)
                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width
                    text: preview.positionLabel
                    font.pixelSize: Theme.fontSizeSmall
                    color: preview.styleTokens?.accentColor ?? Theme.primary
                    elide: Text.ElideRight
                }

                DisplayTitle {
                    width: parent.width
                    text: preview.command?.title ?? ""
                    styleTokens: preview.styleTokens
                    font.pixelSize: Theme.fontSizeXXLarge + Theme.spacingS
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: preview.command?.description ?? ""
                    color: preview.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
                    opacity: 0.86
                    wrapMode: Text.Wrap
                }

                StyledText {
                    visible: text !== ""
                    text: preview.currentValue
                    color: preview.styleTokens?.accentColor ?? Theme.primary
                    font.weight: Font.DemiBold
                }
            }
        }

        Flow {
            width: contents.width
            spacing: Theme.spacingS
            visible: preview.choices.length > 0

            Repeater {
                model: preview.choices

                Rectangle {
                    id: option
                    required property string modelData
                    required property int index

                    implicitWidth: Math.max(120, optionLabel.implicitWidth + Theme.spacingL * 2)
                    implicitHeight: 34
                    radius: Theme.cornerRadius
                    color: option.index === preview.chosenIndex
                        ? (preview.styleTokens?.accentColor ?? Theme.primary)
                        : (preview.styleTokens?.surfaceColor("selectedCard") ?? Theme.surfaceContainerHighest)

                    StyledText {
                        id: optionLabel
                        anchors.centerIn: parent
                        text: option.modelData
                        color: preview.styleTokens?.onSurfaceColor(option.index === preview.chosenIndex ? "chrome" : "card") ?? Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        Repeater {
            model: preview.companionRows

            Rectangle {
                id: companion
                required property var modelData

                width: contents.width
                height: 56
                radius: Theme.cornerRadius
                color: preview.styleTokens?.surfaceColor("selectedCard") ?? Theme.surfaceContainerHighest

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Theme.spacingM
                    width: parent.width - x * 2
                    spacing: Theme.spacingXS

                    StyledText {
                        width: parent.width
                        text: companion.modelData.name
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        width: parent.width
                        text: companion.modelData.status
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
    ValueMeter {
        visible: preview.showMeter
        x: preview.meterOnLeft ? Theme.spacingL : parent.width - width - Theme.spacingL
        anchors.verticalCenter: parent.verticalCenter
        width: preview.meterSize
        height: width
        radial: true
        value: Math.max(0, preview.level)
        unit: "%"
        label: preview.command?.title ?? ""
        styleTokens: preview.styleTokens
        motionTokens: preview.motionTokens
    }

}
