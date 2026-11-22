import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets
import "../primitives/glyphs"

Item {
    id: bar

    property var styleTokens: null
    property var motionTokens: null
    property var i18n: null
    property var iconsPadManager: null
    property var screens: []
    property int currentIndex: 0

    // Estados visuales para Guide / Start (sin acciones nuevas)
    property string guideState: "idle"
    property real guideProgress: 0.0
    property string startState: "idle"
    property real startProgress: 0.0

    // Datos opcionales de mando / perfil (sin inventar porcentajes)
    property bool gamepadConnected: false
    property real gamepadBattery: -1
    property string profileName: ""

    readonly property int animDuration: motionTokens ? motionTokens.durationFast : 120
    readonly property int animEasing: motionTokens ? motionTokens.easingSnappy : Easing.OutCubic

    // Superficies sólidas y opacas (sin blur ni transparencia en las cápsulas)
    readonly property color pillBg: {
        const c = styleTokens ? styleTokens.surfaceColor("chrome") : Theme.surfaceContainerHigh
        return Qt.rgba(c.r, c.g, c.b, 1.0)
    }
    readonly property color pillBorder: styleTokens ? styleTokens.borderColor("chrome") : Theme.outlineVariant
    readonly property color fgColor: styleTokens ? styleTokens.onSurfaceColor("chrome") : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color mutedFg: styleTokens
        ? Qt.alpha(styleTokens.onSurfaceColor("chrome"), 0.65)
        : (Theme.surfaceVariantText ?? "#9CA3AF")
    readonly property color accentColor: styleTokens ? styleTokens.accentColor : Theme.primary

    readonly property string deviceBatteryText: {
        const dev = UPower.displayDevice
        if (!dev || !dev.ready || !dev.isPresent)
            return "--"
        if (!dev.isLaptopBattery)
            return "AC"
        return Math.round(dev.percentage * 100) + "%"
    }

    readonly property string gamepadBatteryText: {
        if (!gamepadConnected || gamepadBattery < 0)
            return "--"
        return Math.round(gamepadBattery * 100) + "%"
    }

    readonly property string resolvedProfile: profileName !== ""
        ? profileName
        : (i18n ? i18n.t("topbar.profile_fallback", "Console") : "Console")

    implicitHeight: 50

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // Bloque 1: Brand (izquierda) — cápsula independiente ajustada al contenido
    Rectangle {
        id: brandPill
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: brandRow.implicitWidth + Theme.spacingL * 2
        height: 48
        radius: height / 2
        color: bar.pillBg
        border.width: 1
        border.color: bar.pillBorder

        RowLayout {
            id: brandRow
            anchors.centerIn: parent
            spacing: Theme.spacingS

            // Círculo oscuro con logo + anillo circular de progreso Guide
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 34
                height: 34
                radius: 17
                color: "#14161D"

                CircularProgressGlyph {
                    anchors.centerIn: parent
                    ringSize: 34
                    state: bar.guideState
                    progress: bar.guideProgress
                    styleTokens: bar.styleTokens
                    motionTokens: bar.motionTokens
                    centerIcon: Qt.resolvedUrl("../../assets/dux-logo.svg")
                }
            }

            InputGlyph {
                Layout.alignment: Qt.AlignVCenter
                iconsPadManager: bar.iconsPadManager
                styleTokens: bar.styleTokens
                action: "I.Guide"
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    text: "DUXSHELL"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: bar.fgColor
                }

                StyledText {
                    text: "CONSOLE"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    color: bar.mutedFg
                }
            }
        }
    }

    // Bloque 2: Navigation (centro) — LB/RB fuera + cápsula central independiente
    RowLayout {
        id: navBlock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS
        // Evita solapamiento con Brand y Status en resoluciones reducidas
        readonly property real availableCenterWidth: Math.max(
            120,
            bar.width - brandPill.width - statusPill.width - Theme.spacingL * 2
        )
        scale: implicitWidth > availableCenterWidth ? availableCenterWidth / implicitWidth : 1.0

        InputGlyph {
            Layout.alignment: Qt.AlignVCenter
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.L"
        }

        Rectangle {
            id: navPill
            Layout.alignment: Qt.AlignVCenter
            width: navTabsRow.implicitWidth + Theme.spacingS * 2
            height: 46
            radius: height / 2
            color: bar.pillBg
            border.width: 1
            border.color: bar.pillBorder

            Row {
                id: navTabsRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: bar.screens
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        readonly property bool isCurrent: index === bar.currentIndex

                        implicitWidth: tabLabel.implicitWidth + Theme.spacingL * 1.5
                        height: 34
                        radius: height / 2
                        color: isCurrent ? bar.accentColor : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: bar.animDuration; easing.type: bar.animEasing }
                        }

                        StyledText {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: bar.i18n
                                  ? bar.i18n.t(modelData.labelKey ?? "", modelData.id ?? "")
                                  : (modelData.id ?? "")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: isCurrent ? Font.Bold : Font.Medium
                            color: isCurrent ? "#FFFFFF" : bar.fgColor
                        }
                    }
                }
            }
        }

        InputGlyph {
            Layout.alignment: Qt.AlignVCenter
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.R"
        }
    }

    // Bloque 3: Status (derecha) — cápsula compacta independiente
    Rectangle {
        id: statusPill
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: statusRow.implicitWidth + Theme.spacingL * 2
        height: 48
        radius: height / 2
        color: bar.pillBg
        border.width: 1
        border.color: bar.pillBorder

        RowLayout {
            id: statusRow
            anchors.centerIn: parent
            spacing: Theme.spacingM

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: "🎮 " + bar.gamepadBatteryText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: bar.mutedFg
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: "🔋 " + bar.deviceBatteryText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: bar.mutedFg
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatTime(sysClock.date, "HH:mm")
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: bar.fgColor
            }

            CircularProgressGlyph {
                Layout.alignment: Qt.AlignVCenter
                ringSize: 32
                state: bar.startState
                progress: bar.startProgress
                styleTokens: bar.styleTokens
                motionTokens: bar.motionTokens
                iconsPadManager: bar.iconsPadManager
                action: "I.Start"
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: profileLabel.implicitWidth + Theme.spacingM * 2
                height: 28
                radius: height / 2
                color: Qt.alpha(bar.accentColor, 0.16)

                StyledText {
                    id: profileLabel
                    anchors.centerIn: parent
                    text: bar.resolvedProfile
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: bar.fgColor
                }
            }
        }
    }
}
