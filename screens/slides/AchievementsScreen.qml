import QtQuick
import qs.Common
import "../../core/shell"
import "../../components/widgets"
import "../../services"
import "../modals"

ScreenBase {
    id: screen

    fixtureSelection: ({ base: selectedId, detail: detailOpen ? detailId : "" })
    screenId: "achievements"
    title: tr("nav.achievements", "Achievements")

    property int filterIndex: 0
    property string selectedId: "relay"
    property bool detailOpen: false
    property string detailId: ""
    readonly property int detailIndex: Math.max(0, entries.findIndex(entry => entry.id === detailId))

    property bool fixtureOpened: false
    readonly property bool restoreDetailScene: mockSession?.scene === "achievement-detail" && layerManager !== null

    onRestoreDetailSceneChanged: fixtureOpening.restart()

    Timer {
        id: fixtureOpening
        interval: 0
        onTriggered: screen.openFixture()
    }

    function openFixture() {
        if (!restoreDetailScene || fixtureOpened || !selectedEntry || layerManager.topLayer !== "dashboard")
            return
        fixtureOpened = true
        openDetail(selectedIndex)
    }
    readonly property var filterStates: [
        { id: "all", label: tr("mockCollection.all", "All") },
        { id: "unlocked", label: tr("mockAchievements.unlocked", "Unlocked") },
        { id: "locked", label: tr("mockAchievements.locked", "Locked") }
    ]
    readonly property var allEntries: source.value?.entries ?? []
    readonly property int unlockedCount: allEntries.filter(entry => entry.unlocked).length
    readonly property var entries: allEntries
        .filter(entry => filterIndex === 0 || entry.unlocked === (filterStates[filterIndex].id === "unlocked"))
        .map(entry => Object.assign({}, entry, {
            title: tr(entry.titleKey, ""),
            description: tr(entry.descriptionKey, ""),
            subtitle: entry.unlocked ? tr("mockAchievements.unlocked", "Unlocked") : tr("mockAchievements.locked", "Locked"),
            art: entry.art ? Qt.resolvedUrl("../../" + entry.art) : ""
        }))
    readonly property int selectedIndex: Math.max(0, entries.findIndex(entry => entry.id === selectedId))
    readonly property var selectedEntry: entries[selectedIndex] ?? null

    onEntriesChanged: {
        if (selectedEntry)
            selectedId = selectedEntry.id
        fixtureOpening.restart()
    }

    function pick(index) {
        if (entries[index])
            selectedId = entries[index].id
    }

    function openDetail(index) {
        if (!entries[index] || !layerManager)
            return

        detailId = entries[index].id
        detailOpen = true
        layerManager.push("modal")
    }

    MockCollectionData {
        id: source
        source: Qt.resolvedUrl("../../fixtures/mockup/achievements.json")
    }

    AchievementSummary {
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        y: parent.height * 0.26
        width: parent.width * 0.44
        title: screen.title
        subtitle: screen.mockSession?.session?.title ?? ""
        progress: screen.allEntries.length ? screen.unlockedCount / screen.allEntries.length : 0
        progressLabel: screen.tr("mockAchievements.progress", "%1 of %2 unlocked")
            .arg(screen.unlockedCount).arg(screen.allEntries.length)
        styleTokens: screen.styleTokens
    }

    AchievementDetail {
        anchors.right: parent.right
        anchors.rightMargin: parent.width * 0.03
        y: parent.height * 0.09
        width: Math.min(680, parent.width * 0.41)
        previewHeight: Math.min(width * 9 / 16, parent.height * 0.45)
        showInsignia: true
        visible: !!screen.selectedEntry
        entry: screen.selectedEntry
        missingLabel: screen.tr("mockCollection.missingArt", "Not found")
        missingDescription: screen.tr("mockAchievements.missingArt", "No screenshot is available for this achievement.")
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
    }

    CollectionShelf {
        id: shelf
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.085
        anchors.bottom: filters.top
        anchors.bottomMargin: screen.entries.length > 2 ? -Theme.spacingS : Theme.spacingS
        width: parent.width * 0.83
        height: parent.height * 0.21
        featuredWidth: Math.min(340, width * 0.30)
        featuredHeight: Math.min(165, height * 0.94)
        sideWidthLimit: 235
        aspectRatio: 1.56
        sideHeightLimit: 152
        leadingItems: 1
        cardGap: Theme.spacingL * 4
        cardSkew: -11
        badgeLayout: true
        zoneId: "mock-achievements-shelf"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        items: screen.entries
        selectedIndex: screen.selectedIndex
        maxVisibleItems: 4
        defaultFocus: true
        navDown: filters
        emptyLabel: screen.tr("mockAchievements.empty", "No achievements match this filter.")
        onPicked: itemIndex => screen.pick(itemIndex)
        onOpenItem: itemIndex => screen.openDetail(itemIndex)
        onExpandRequested: itemIndex => screen.openDetail(itemIndex)
        onOptionsTriggered: filters.toggle()
    }

    CollectionFilterBar {
        id: filters
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.bottom: parent.bottom
        width: implicitWidth
        height: implicitHeight
        zoneId: "mock-achievements-filters"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        filterLabel: screen.tr("mockCollection.filter", "Filters") + " · " + options[selectedIndex].label
        options: screen.filterStates
        selectedIndex: screen.filterIndex
        navUp: shelf
        onPicked: optionIndex => screen.filterIndex = optionIndex
    }

    CollectionDetailModal {
        zoneId: "mock-achievements-detail"
        selectedEntry: screen.detailOpen ? screen.entries[screen.detailIndex] : null
        entries: screen.entries
        selectedIndex: screen.detailIndex
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        missingLabel: screen.tr("mockCollection.missingArt", "Not found")
        missingDescription: screen.tr("mockAchievements.missingArt", "No screenshot is available for this achievement.")
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
