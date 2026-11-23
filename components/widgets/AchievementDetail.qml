import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets as DCommon
import "../primitives/text"
import "../primitives/surfaces"

Column {
    id: detail

    property var entry: null
    property var styleTokens: null
    property var motionTokens: null
    property string missingLabel: ""
    property string missingDescription: ""
    property real previewHeight: width * 0.52
    property bool showInsignia: false
    readonly property real insigniaSize: Math.min(94, previewHeight * 0.28)

    spacing: Theme.spacingM

    SlantedImage {
        width: detail.width
        height: detail.previewHeight
        skewAngle: 0
        styleTokens: detail.styleTokens
        motionTokens: detail.motionTokens
        source: detail.entry?.art ?? ""

        Column {
            width: parent.width - Theme.spacingXL * 2
            anchors.centerIn: parent
            visible: !detail.previewHasArt
            spacing: Theme.spacingS

            DCommon.DIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: detail.entry?.icon ?? ""
                size: 28
                color: detail.styleTokens?.accentColor ?? Theme.primary
            }

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: detail.missingLabel
                color: detail.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
                font.weight: Font.Bold
                font.letterSpacing: 2
            }

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: detail.missingDescription
                color: detail.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
                opacity: 0.7
                wrapMode: Text.Wrap
            }
        }

        id: preview
    }

    readonly property bool previewHasArt: preview.hasImage

    Item {
        width: detail.width
        height: caption.implicitHeight + (detail.showInsignia ? Theme.spacingXL : 0)

        SlantedSurface {
            visible: detail.showInsignia
            width: detail.insigniaSize
            height: width
            x: Theme.spacingS
            y: -height * 0.66
            role: "selectedCard"
            styleTokens: detail.styleTokens

            DCommon.DIcon {
                anchors.centerIn: parent
                name: detail.entry?.icon ?? ""
                size: Math.round(detail.insigniaSize * 0.38)
                color: detail.styleTokens?.accentColor ?? Theme.primary
            }
        }

        SectionTitle {
            id: caption
            x: detail.showInsignia ? detail.insigniaSize + Theme.spacingXL : 0
            y: detail.showInsignia ? Theme.spacingXL : 0
            width: parent.width - x
            titleSize: detail.showInsignia ? Theme.fontSizeXLarge : Theme.fontSizeMedium
            styleTokens: detail.styleTokens
            title: detail.entry?.title ?? ""
            subtitle: detail.entry?.description ?? detail.entry?.subtitle ?? ""
        }
    }
}
