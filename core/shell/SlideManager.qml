import QtQuick

Item {
    id: manager

    required property var registry
    required property var inputManager
    property var layerManager: null
    property var iconsManager: null
    property var i18n: null
    property int currentIndex: 0

    readonly property var currentScreenMeta: registry.screens[currentIndex] ?? null

    function next() {
        if (!registry.screens.length) return
        currentIndex = (currentIndex + 1) % registry.screens.length
    }

    function prev() {
        if (!registry.screens.length) return
        currentIndex = (currentIndex - 1 + registry.screens.length) % registry.screens.length
    }

    Loader {
        id: slideLoader
        anchors.fill: parent
        source: manager.currentScreenMeta ? Qt.resolvedUrl(manager.currentScreenMeta.source) : ""

        onLoaded: {
            if (!item) return
            if ("inputManager" in item)
                item.inputManager = manager.inputManager
            if ("layerManager" in item)
                item.layerManager = manager.layerManager
            if ("iconsManager" in item)
                item.iconsManager = manager.iconsManager
            if ("i18n" in item)
                item.i18n = manager.i18n
        }
    }
}