import QtQuick
import qs.Common

Item {
    id: cards

    property var styleTokens: null
    property var motionTokens: null
    property var windowData: null
    property var i18n: null
    property bool compact: false

    readonly property bool narrow: width < 560

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    readonly property string titleValue: windowData?.title
        || windowData?.appName
        || tr("windows.unknown_app", "Application")
    readonly property string descriptionValue: {
        if (!windowData)
            return tr("windows.empty", "No open windows")
        const values = []
        if (windowData.appName)
            values.push(windowData.appName)
        if (windowData.workspaceIndex >= 0)
            values.push(tr("windows.workspace_prefix", "Workspace") + " " + windowData.workspaceIndex)
        return values.length > 0 ? values.join(" · ") : tr("windows.unknown_app", "Application")
    }
    readonly property string monitorValue: windowData?.output
        || tr("windows.monitor_unavailable", "Monitor unavailable")

    implicitHeight: layout.implicitHeight

    Column {
        id: layout
        anchors.fill: parent
        spacing: Theme.spacingS

        WindowInfoCard {
            width: layout.width
            compact: cards.compact
            prominent: true
            styleTokens: cards.styleTokens
            motionTokens: cards.motionTokens
            label: cards.tr("windows.detail_title", "Window title")
            value: cards.titleValue
        }

        Column {
            id: secondaryCards
            width: layout.width
            spacing: Theme.spacingM

            WindowInfoCard {
                width: secondaryCards.width
                compact: cards.compact
                styleTokens: cards.styleTokens
                motionTokens: cards.motionTokens
                label: cards.tr("windows.detail_description", "Description")
                value: cards.descriptionValue
            }

            WindowInfoCard {
                id: monitorCard
                width: secondaryCards.width
                compact: cards.compact
                styleTokens: cards.styleTokens
                motionTokens: cards.motionTokens
                label: cards.tr("windows.monitor", "Monitor")
                value: cards.monitorValue
            }
        }
    }
}
