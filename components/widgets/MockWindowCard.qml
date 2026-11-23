import QtQuick
import qs.Common
import qs.Widgets
import "../primitives/buttons"
import "../primitives/surfaces"

SlantedSurface {
    id: card

    property var itemData: null
    property string details: ""
    property string optionsLabel: ""
    property bool interactive: enabled
    property bool accessibilitySelected: selected

    signal optionsRequested()
    signal activationRequested()

    Accessible.role: Accessible.Button
    Accessible.name: cardTitle
    Accessible.description: card.details
    Accessible.ignored: !interactive || !enabled || !visible
    Accessible.focused: focused && !Accessible.ignored
    Accessible.selected: accessibilitySelected
    Accessible.onPressAction: {
        if (!Accessible.ignored)
            activationRequested()
    }

    function optionsContain(localPoint) {
        return card.selected && options.contains(options.mapFromItem(card, localPoint))
    }

    radius: Theme.cornerRadius
    readonly property string cardTitle: itemData?.title || itemData?.appName || ""
    readonly property real inset: Math.max(Theme.spacingXS, width * 0.035)
    readonly property real textSize: Math.min(Theme.fontSizeMedium, Math.max(Theme.fontSizeSmall, width * 0.058))

    SlantedImage {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: card.selected ? details.top : parent.bottom
        anchors.margins: 2
        source: card.itemData?.artwork ?? ""
        fillMode: Image.PreserveAspectCrop
        showGradientOverlay: false
        fallbackText: card.cardTitle.slice(0, 2).toUpperCase()
        styleTokens: card.styleTokens
        motionTokens: card.motionTokens
    }

    Row {
        id: details
        visible: card.selected
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: card.inset
        anchors.rightMargin: card.inset * 2
        anchors.bottomMargin: Theme.spacingXS
        spacing: Theme.spacingS

        Column {
            width: Math.max(0, details.width - options.implicitWidth - details.spacing)
            anchors.verticalCenter: details.verticalCenter

            StyledText {
                width: parent.width
                text: card.cardTitle
                font.pixelSize: card.textSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                color: card.styleTokens?.onSurfaceColor(card.role) ?? Theme.surfaceText
            }

            StyledText {
                width: parent.width
                text: card.details
                font.pixelSize: Theme.fontSizeSmall
                elide: Text.ElideRight
                color: card.styleTokens?.disabledOnSurfaceColor(card.role) ?? Theme.surfaceVariantText
            }
        }

        ActionPill {
            id: options
            anchors.verticalCenter: details.verticalCenter
            text: card.optionsLabel
            primary: true
            styleTokens: card.styleTokens
            enabled: card.interactive && card.selected
            onClicked: card.optionsRequested()
        }
    }
}
