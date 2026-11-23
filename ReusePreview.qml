pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "./components/widgets"
import "./core/motion"
import "./core/shell"
import "./services"

ShellRoot {
    id: demo

    property int index: 0
    readonly property var entries: data.value?.entries ?? []
    readonly property var selection: entries[index]

    function step(delta) {
        if (entries.length)
            index = ((index + delta) % entries.length + entries.length) % entries.length
    }

    MotionTokens { id: motion }
    I18n { id: i18n }
    MockCollectionData {
        id: data
        source: Qt.resolvedUrl("fixtures/mockup/library.json")
    }

    InputManager {
        id: input
        onTriggered: (action, _) => {
            if (action === "I.ActionOption.L")
                demo.step(-1)
            else if (action === "I.ActionOption.R")
                demo.step(1)
            else if (action === "I.Refuse")
                Qt.quit()
        }
    }

    FloatingWindow {
        implicitWidth: 720
        implicitHeight: 250
        title: i18n.t("mockLibrary.title", "Library")
        color: Theme.surface

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => input.processKeyEvent(event, true)
            Keys.onReleased: event => input.processKeyEvent(event, false)

            QueueCarousel {
                id: shelf
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                entries: demo.entries
                selectedId: demo.selection?.id
                visibleBudget: 3
                centerContent: true
                selectedWidth: 230
                selectedHeight: 162
                cardWidth: 148
                cardHeight: 110
                spacing: Theme.spacingL
                motionTokens: motion
                focused: true
                onCardClicked: itemId => {
                    const index = demo.entries.findIndex(entry => entry.id === itemId)
                    if (index >= 0)
                        demo.index = index
                }

                cardDelegate: ShowcaseCard {
                    title: itemData?.title ?? ""
                    iconName: itemData?.icon ?? ""
                    subtitle: i18n.t(itemData?.subtitleKey, "")
                    source: itemData?.art ? Qt.resolvedUrl(itemData.art) : ""
                    onPicked: itemId => shelf.cardClicked(itemId)
                }
            }
        }
    }

    IpcHandler {
        target: "duxConsoleReuse"

        function step(delta: int): void { demo.step(delta) }
        function selectedId(): string { return demo.selection?.id ?? "" }
        function frame(path: string): bool {
            return shelf.grabToImage(result => result.saveToFile(path))
        }
    }
}
