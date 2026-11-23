import QtQuick
import qs.Common
import "../../core/shell"
import "../../components/widgets"
import "../../components/primitives/text"
import "../../services"
import "../modals"

ScreenBase {
    id: screen

    fixtureSelection: ({ base: selectedId, detail: detailOpen ? detailId : "" })
    screenId: "launcher"
    title: tr("nav.launcher", "Launcher")

    property int filterIndex: 0
    property string selectedId: "frontier"
    property bool detailOpen: false
    property string detailId: ""
    readonly property int detailIndex: Math.max(0, entries.findIndex(entry => entry.id === detailId))

    readonly property var categories: [
        { id: "all", label: tr("mockCollection.all", "All") },
        { id: "games", label: tr("mockLibrary.games", "Games") },
        { id: "apps", label: tr("mockLibrary.apps", "Apps") }
    ]
    readonly property var entries: (source.value?.entries ?? [])
        .filter(entry => categories[filterIndex].id === "all" || entry.category === categories[filterIndex].id)
        .map(entry => Object.assign({}, entry, {
            category: tr("mockLibrary." + entry.category, ""),
            subtitle: tr(entry.subtitleKey, ""),
            art: entry.art ? Qt.resolvedUrl("../../" + entry.art) : ""
        }))
    readonly property int selectedIndex: Math.max(0, entries.findIndex(entry => entry.id === selectedId))
    readonly property var selectedEntry: entries[selectedIndex] ?? null

    onEntriesChanged: {
        if (selectedEntry)
            selectedId = selectedEntry.id
    }

    function pick(index) {
        if (entries[index])
            selectedId = entries[index].id
    }

    function launch(index) {
        const entry = entries[index]
        if (entry && mockSession)
            mockSession.dispatch("launch-entry", { id: entry.id, title: entry.title })
    }

    MockCollectionData {
        id: source
        source: Qt.resolvedUrl("../../fixtures/mockup/library.json")
    }

    LibraryHero {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.bottom: shelfTitle.top
        anchors.bottomMargin: Theme.spacingM
        width: parent.width * 0.68
        entry: screen.selectedEntry
        emptyLabel: screen.tr("mockLibrary.empty", "No entries")
        actionLabel: screen.tr("mockLibrary.play", "Play")
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        interactive: !shelf.inert
        onLaunchRequested: {
            if (shelf.requestZoneFocus())
                screen.launch(screen.selectedIndex)
        }
    }

    DisplayTitle {
        id: shelfTitle
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.bottom: shelf.top
        color: screen.styleTokens?.onSurfaceColor("card") ?? Theme.surfaceText
        text: screen.tr("mockLibrary.title", "Library")
        font.pixelSize: Theme.fontSizeXXLarge
    }

    CollectionShelf {
        id: shelf
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.03
        anchors.bottom: filters.top
        anchors.bottomMargin: Theme.spacingS
        height: parent.height * 0.29
        zoneId: "mock-launcher-shelf"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        items: screen.entries
        selectedIndex: screen.selectedIndex
        defaultFocus: true
        navDown: filters
        emptyLabel: screen.tr("mockLibrary.empty", "No entries")
        onPicked: itemIndex => screen.pick(itemIndex)
        onOpenItem: itemIndex => screen.launch(itemIndex)
        onExpandRequested: itemIndex => {
            screen.detailId = screen.entries[itemIndex]?.id ?? ""
            screen.detailOpen = true
            screen.layerManager?.push("modal")
        }
        onOptionsTriggered: filters.toggle()
    }

    CollectionFilterBar {
        id: filters
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.bottom: parent.bottom
        width: implicitWidth
        height: implicitHeight
        zoneId: "mock-launcher-filters"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        filterLabel: screen.tr("mockCollection.filter", "Filters") + " · " + options[selectedIndex].label
        options: screen.categories
        selectedIndex: screen.filterIndex
        expanded: screen.mockSession?.scene === "launcher-filter"
        navUp: shelf
        onPicked: optionIndex => screen.filterIndex = optionIndex
    }

    CollectionDetailModal {
        zoneId: "mock-launcher-detail"
        selectedEntry: screen.detailOpen ? screen.entries[screen.detailIndex] : null
        entries: screen.entries
        selectedIndex: screen.detailIndex
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        missingLabel: screen.tr("mockCollection.missingArt", "Not found")
        missingDescription: screen.tr("mockLibrary.missingArt", "No artwork is available for this entry.")
        onPicked: itemIndex => screen.detailId = screen.entries[itemIndex]?.id ?? ""
    }

    Connections {
        target: screen.layerManager
        function onLayerPopped(layer) {
            if (layer === "modal")
                screen.detailOpen = false
        }
    }
}
