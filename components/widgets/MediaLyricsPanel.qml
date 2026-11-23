pragma ComponentBehavior: Bound
import QtQuick
import qs.Common
import qs.Widgets
import qs.Services
import "../primitives/surfaces"

SlantedSurface {
    id: panel
    property bool lyricsActive: false
    readonly property var lyricsCtrl: LyricsService.controller
    readonly property bool isSynced: Boolean(lyricsCtrl?.synced)
    readonly property var lineModel: isSynced ? (lyricsCtrl?.lines ?? []) : (lyricsCtrl?.plainLines ?? [])
    readonly property int activeLineIndex: isSynced ? (lyricsCtrl?.activeIndex ?? -1) : -1
    readonly property color foreground: styleTokens ? styleTokens.onSurfaceColor("card") : Theme.surfaceText
    contained: true
    skewAngle: 0
    radius: Theme.cornerRadius
    contentPadding: Theme.spacingL
    surfaceOpacity: 0.55

    ListView {
        id: lyrics
        anchors.fill: parent
        clip: true
        interactive: panel.lyricsActive && !panel.isSynced
        spacing: Theme.spacingM
        visible: panel.lyricsActive
        model: panel.lineModel
        currentIndex: panel.activeLineIndex
        preferredHighlightBegin: height * 0.36
        preferredHighlightEnd: height * 0.54
        highlightRangeMode: panel.isSynced ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
        highlightMoveDuration: panel.motionTokens ? panel.motionTokens.durationNormal : 0
        delegate: StyledText {
            id: line
            required property int index
            required property var modelData
            readonly property bool current: panel.isSynced && index === lyrics.currentIndex
            width: lyrics.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: panel.isSynced ? String(modelData?.x ?? "") : String(modelData ?? "")
            font.pixelSize: current ? Theme.fontSizeXLarge : Theme.fontSizeLarge
            font.weight: current ? Font.Bold : Font.Medium
            color: current ? panel.foreground : Qt.alpha(panel.foreground, panel.isSynced ? 0.48 : 0.85)
            Behavior on color {
                ColorAnimation { duration: panel.motionTokens ? panel.motionTokens.durationFast : 0 }
            }
        }
    }
}
