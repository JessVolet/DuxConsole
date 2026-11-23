import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/text"
import "../primitives/buttons"

Column {
    id: hero

    property var entry: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null
    property string actionLabel: ""
    property string emptyLabel: ""
    property bool interactive: true
    signal launchRequested()

    spacing: Theme.spacingXS

    StyledText {
        text: hero.entry?.category ?? ""
        color: hero.styleTokens?.accentColor ?? Theme.primary
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        visible: text !== ""
    }

    DisplayTitle {
        width: hero.width
        text: hero.entry?.title ?? hero.emptyLabel
        styleTokens: hero.styleTokens
        font.pixelSize: Math.round(Math.max(Theme.fontSizeXXLarge, Math.min(82, hero.width * 0.09)))
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 2
    }

    StyledText {
        text: hero.entry?.subtitle ?? ""
        color: hero.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        opacity: 0.8
        font.pixelSize: Theme.fontSizeMedium
        visible: text !== ""
    }

    ActionButton {
        label: hero.actionLabel
        visible: !!hero.entry
        styleTokens: hero.styleTokens
        motionTokens: hero.motionTokens
        iconsPadManager: hero.iconsPadManager
        action: "I.Accept"
        width: Math.min(hero.width, textMetrics.width + Theme.spacingXL * 2 + 28)
        height: 38
        radius: height / 2
        skewAngle: 0

        TextMetrics {
            id: textMetrics
            text: hero.actionLabel

            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
        }

        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.ignored: !hero.interactive
        Accessible.onPressAction: {
            if (hero.interactive)
                hero.launchRequested()
        }

        TapHandler {
            enabled: hero.interactive
            onTapped: hero.launchRequested()
        }
    }
}
