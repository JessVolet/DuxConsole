import QtQuick

Item {
    id: manager

    required property var registry
    required property var inputManager
    property var layerManager: null
    property var navigationManager: null
    property var iconsPadManager: null
    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
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
            if ("navigationManager" in item)
                item.navigationManager = manager.navigationManager
            if ("iconsPadManager" in item)
                item.iconsPadManager = manager.iconsPadManager
            if ("i18n" in item)
                item.i18n = manager.i18n
            if ("styleTokens" in item)
                item.styleTokens = manager.styleTokens
            if ("motionTokens" in item)
                item.motionTokens = manager.motionTokens
            if ("registry" in item)
                item.registry = manager.registry
            if ("currentSlideIndex" in item)
                item.currentSlideIndex = Qt.binding(() => manager.currentIndex)
        }
    }
}