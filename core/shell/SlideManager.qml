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
    property var windowManager: null
    property var windowIconProvider: null
    property var mockSession: null
    property int currentIndex: 0

    signal closeOverlayRequested()

    readonly property var currentScreenMeta: registry.screens[currentIndex] ?? null
    readonly property var activeScreen: slideLoader.item
    readonly property var fixtureSelection: activeScreen?.fixtureSelection ?? null
    property string loadError: ""
    property string failedSource: ""

    function reloadCurrent() {
        slideLoader.active = false
        slideLoader.active = true
    }

    function select(slideId) {
        const index = registry.screens.findIndex(entry => entry.id === slideId)
        if (index >= 0)
            currentIndex = index
    }

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

        onStatusChanged: {
            if (status === Loader.Ready) {
                manager.loadError = ""
                manager.failedSource = ""
            } else if (status === Loader.Error) {
                manager.failedSource = source.toString()
                const probe = Qt.createComponent(source)
                manager.loadError = probe.status === Component.Error
                    ? probe.errorString()
                    : "Error al cargar la pantalla (Loader.Error)"
                probe.destroy()
            }
        }

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
            if ("windowManager" in item)
                item.windowManager = Qt.binding(() => manager.windowManager)
            if ("windowIconProvider" in item)
                item.windowIconProvider = Qt.binding(() => manager.windowIconProvider)
            if ("mockSession" in item)
                item.mockSession = Qt.binding(() => manager.mockSession)
            if ("registry" in item)
                item.registry = manager.registry
            if ("currentSlideIndex" in item)
                item.currentSlideIndex = Qt.binding(() => manager.currentIndex)
        }
    }

    Connections {
        target: slideLoader.item ?? null
        function onCloseOverlayRequested() {
            manager.closeOverlayRequested()
        }
        function onSlideRequested(slideId) {
            if (manager.layerManager?.topLayer === "dashboard")
                manager.select(slideId)
        }
    }
}
