import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Common
import qs.Widgets
import "../primitives/surfaces"
import "../primitives/glyphs"

SlantedSurface {
    id: bar

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
    readonly property color fgColor: styleTokens ? styleTokens.onSurfaceColor("chrome") : (Theme.surfaceText ?? "#F2F4F8")
    readonly property color mutedFg: styleTokens
        ? Qt.alpha(styleTokens.onSurfaceColor("chrome"), 0.68)
        : (Theme.surfaceVariantText ?? "#9CA3AF")

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

    role: "chrome"
    implicitHeight: 58
    radius: Theme.cornerRadius

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    // Izquierda: Identidad DuxShell (Guide + logo DankLinux + DuxShell / Console)
    Row {
        id: leftRegion
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingL
        spacing: Theme.spacingS

        InputGlyph {
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.Guide"
        }

        CircularProgressGlyph {
            state: bar.guideState
            progress: bar.guideProgress
            styleTokens: bar.styleTokens
            motionTokens: bar.motionTokens
            centerIcon: Qt.resolvedUrl("../../assets/dux-logo.svg")
        }

        Column {
            spacing: 0

            StyledText {
                text: "DuxShell"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: bar.fgColor
            }

            StyledText {
                text: "Console"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: bar.mutedFg
            }
        }
    }

    // Centro: Navegación entre slides (ScreenRegistry + I18n + LB/RB)
    Row {
        id: centerRegion
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(implicitWidth, Math.max(0, rightRegion.x - (leftRegion.x + leftRegion.width) - Theme.spacingL * 2))
        clip: true
        spacing: Theme.spacingS

        InputGlyph {
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.L"
        }

        Repeater {
            model: bar.screens
            delegate: StyledRect {
                required property int index
                required property var modelData
                readonly property bool isCurrent: index === bar.currentIndex

                implicitWidth: tabLabel.implicitWidth + Theme.spacingM * 2
                implicitHeight: 32
                radius: Theme.cornerRadius
                color: isCurrent
                       ? (bar.styleTokens ? bar.styleTokens.accentColor : Theme.primary)
                       : "transparent"

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

        InputGlyph {
            iconsPadManager: bar.iconsPadManager
            styleTokens: bar.styleTokens
            action: "I.ActionSlide.R"
        }
    }

    // Derecha: Start + batería mando + batería equipo + hora local + Profile
    Row {
        id: rightRegion
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Theme.spacingL
        spacing: Theme.spacingM

        CircularProgressGlyph {
            state: bar.startState
            progress: bar.startProgress
            styleTokens: bar.styleTokens
            motionTokens: bar.motionTokens
            iconsPadManager: bar.iconsPadManager
            action: "I.Start"
        }

        StyledText {
            text: "🎮 " + bar.gamepadBatteryText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: bar.mutedFg
        }

        StyledText {
            text: "🔋 " + bar.deviceBatteryText
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: bar.mutedFg
        }

        StyledText {
            text: Qt.formatTime(sysClock.date, "HH:mm")
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: bar.fgColor
        }

        StyledRect {
            implicitWidth: profileLabel.implicitWidth + Theme.spacingM * 2
            implicitHeight: 28
            radius: Theme.cornerRadius
            color: bar.styleTokens ? Qt.alpha(bar.styleTokens.accentColor, 0.16) : Qt.rgba(1, 1, 1, 0.10)

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
