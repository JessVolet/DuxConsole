pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets

// Material 3 list row: tonal leading avatar, title, trailing value. Selection
// is a filled secondaryContainer; the focused row adds the controller outline.
Rectangle {
    id: row

    property var styleTokens: null
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property url iconSource: ""
    property string fallbackText: ""
    property bool iconTinted: false
    property bool selected: false
    property bool focused: false

    signal chosen()

    implicitHeight: 64
    radius: 18
    color: selected
           ? (styleTokens ? styleTokens.m3SecondaryContainer : Theme.secondaryContainer)
           : (hover.hovered ? (styleTokens ? styleTokens.m3Alpha(styleTokens.m3OnSurface, 0.06) : Qt.alpha(Theme.onSurface, 0.06)) : "transparent")
    border.width: focused && selected ? 2 : 0
    border.color: styleTokens ? styleTokens.m3Primary : Theme.primary

    readonly property color _onSelection: styleTokens ? styleTokens.m3OnSecondaryContainer : Theme.onSecondaryContainer
    readonly property color _onSurface: styleTokens ? styleTokens.m3OnSurface : Theme.onSurface
    readonly property color _variant: styleTokens ? styleTokens.m3OnSurfaceVariant : Theme.onSurfaceVariant
    readonly property color _iconOnSelection: styleTokens ? styleTokens.m3SecondaryContainer : Theme.secondaryContainer
    readonly property color _onSelectionMuted: styleTokens ? styleTokens.m3Alpha(_onSelection, 0.8) : Qt.alpha(Theme.onSecondaryContainer, 0.8)

    HoverHandler { id: hover }

    Item {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 18

        Rectangle {
            id: avatar
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 12
            color: row.selected
                   ? row._onSelection
                   : (row.styleTokens ? row.styleTokens.m3SurfaceHighest : Theme.surfaceContainerHighest)

            Image {
                id: leadingImage
                anchors.centerIn: parent
                width: 22
                height: 22
                visible: row.iconSource.toString() !== ""
                source: row.iconSource
                sourceSize: Qt.size(44, 44)
                fillMode: Image.PreserveAspectFit
                layer.enabled: row.iconTinted
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: row.selected ? row._iconOnSelection : row._variant
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: row.iconSource.toString() === ""
                text: row.fallbackText
                color: row.selected ? row._iconOnSelection : row._variant
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }

        StyledText {
            id: trailingLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.trailing
            color: row.selected ? row._onSelection : row._variant
            font.pixelSize: 13
        }

        Column {
            anchors.left: avatar.right
            anchors.leftMargin: 14
            anchors.right: trailingLabel.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            StyledText {
                width: parent.width
                text: row.title
                elide: Text.ElideRight
                color: row.selected ? row._onSelection : row._onSurface
                font.pixelSize: 15
                font.weight: row.selected ? Font.Medium : Font.Normal
            }
            StyledText {
                width: parent.width
                visible: row.subtitle !== ""
                text: row.subtitle
                elide: Text.ElideRight
                color: row.selected ? row._onSelectionMuted : row._variant
                font.pixelSize: 12
            }
        }
    }

    TapHandler {
        onTapped: row.chosen()
    }

    Accessible.role: Accessible.ListItem
    Accessible.name: title
    Accessible.selected: selected
    Accessible.onPressAction: row.chosen()
}
