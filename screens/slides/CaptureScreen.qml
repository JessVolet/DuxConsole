import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/text"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: screen

    fixtureSelection: ({ base: selectedEntry?.id ?? "", detail: layerManager?.topLayer === "mock-capture-viewer" ? viewerEntryId : "" })
    screenId: "mock-capture"
    title: tr("mockup.nav.capture", "Capture")

    readonly property var captureState: mockSession?.capture ?? null
    readonly property var entries: captureState?.items ?? []
    readonly property var selectedEntry: entries[selectedIndex] ?? null
    readonly property int selectedIndex: {
        const index = entries.findIndex(entry => entry.id === selectedId)
        return index >= 0 ? index : Math.max(0, Math.min(initialIndex, entries.length - 1))
    }
    readonly property int initialIndex: mockSession?.scene === "capture-viewer-image" ? 0 : 2
    property string selectedId: ""
    property string viewerEntryId: ""
    readonly property int viewerIndex: Math.max(0, entries.findIndex(entry => entry.id === viewerEntryId))
    property bool fixtureOpened: false

    function select(index) {
        if (entries[index])
            selectedId = entries[index].id
    }

    function openViewer() {
        if (selectedEntry) {
            viewerEntryId = selectedEntry.id
            layerManager?.push("mock-capture-viewer")
        }
    }

    function activateCommand(index) {
        if (index === 3)
            layerManager?.push("mock-capture-settings")
        else
            mockSession?.dispatch(["capture.screenshot", "capture.record", "capture.replay"][index], {})
    }

    Timer {
        id: fixtureOpening
        interval: 0
        onTriggered: screen.openFixture()
    }

    function openFixture() {
        if (fixtureOpened || layerManager?.topLayer !== "dashboard")
            return
        const scene = mockSession?.scene
        if ((scene === "capture-viewer" || scene === "capture-viewer-image") && selectedEntry) {
            fixtureOpened = true
            openViewer()
        } else if (scene === "capture-settings") {
            fixtureOpened = true
            layerManager.push("mock-capture-settings")
        }
    }

    onMockSessionChanged: fixtureOpening.restart()
    onEntriesChanged: fixtureOpening.restart()
    onSelectedIndexChanged: galleryZone.currentSubIndex = selectedIndex
    Component.onCompleted: galleryZone.currentSubIndex = selectedIndex

    SectionTitle {
        x: parent.width * 0.03
        width: parent.width - x
        titleSize: Theme.fontSizeXXLarge
        title: screen.title
        styleTokens: screen.styleTokens
    }

    FocusZone {
        id: actionZone

        x: parent.width * 0.028
        y: parent.height * 0.15
        width: Math.max(180, Math.min(parent.width * 0.20, 255))
        height: buttons.implicitHeight
        zoneId: "mock-capture-actions"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        defaultFocus: true
        showFocusRing: false
        navRight: previewZone
        navDown: galleryZone
        expandable: true
        subItemCount: 4
        onActivated: index => screen.activateCommand(index)
        onOptionsTriggered: screen.activateCommand(3)
        onExpandRequested: screen.activateCommand(3)
        actionHints: [
            { action: "I.Accept", labelKey: "mockup.capture.run", fallback: "Run action" },
            { action: "I.Options", labelKey: "mockup.capture.settings", fallback: "Settings" }
        ]

        CaptureActions {
            id: buttons

            width: parent.width
            styleTokens: screen.styleTokens
            motionTokens: screen.motionTokens
            iconsPadManager: screen.iconsPadManager
            i18n: screen.i18n
            recording: screen.captureState?.recording ?? false
            replayEnabled: screen.captureState?.replayEnabled ?? false
            interactive: !actionZone.inert
            focusedIndex: actionZone.active ? actionZone.currentSubIndex : -1
            onCommandRequested: index => {
                if (actionZone.requestZoneFocus()) {
                    actionZone.currentSubIndex = index
                    actionZone.activate()
                }
            }
        }
    }

    FocusZone {
        id: previewZone

        anchors.right: parent.right
        y: parent.height * 0.10
        width: Math.min(parent.width * 0.50, height * 16 / 9)
        height: Math.min(parent.height * 0.53, parent.width * 0.50 * 9 / 16)
        zoneId: "mock-capture-preview"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        enabled: Boolean(screen.selectedEntry)
        expandable: enabled
        showFocusRing: false
        navLeft: actionZone
        navDown: galleryZone
        onActivated: screen.openViewer()
        onExpandRequested: screen.openViewer()
        actionHints: galleryZone.actionHints

        CapturePreview {
            anchors.fill: parent
            entry: screen.selectedEntry
            styleTokens: screen.styleTokens
            motionTokens: screen.motionTokens
            iconsPadManager: screen.iconsPadManager
            i18n: screen.i18n
            focused: previewZone.active
            interactive: !previewZone.inert
            onActivated: {
                if (previewZone.requestZoneFocus())
                    previewZone.activate()
            }
        }
    }

    FocusZone {
        id: galleryZone

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.25
        zoneId: "mock-capture-gallery"
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        enabled: subItemCount > 0
        expandable: enabled
        showFocusRing: false
        navUp: previewZone
        subItemCount: screen.entries.length
        onSubItemCycled: index => screen.select(index)
        onActivated: screen.openViewer()
        onExpandRequested: screen.openViewer()
        actionHints: [
            { action: "I.Select", labelKey: "mockup.capture.viewer", fallback: "Capture viewer" },
            { action: "I.ActionOption.L", labelKey: "hints.cycle", fallback: "Cycle" },
            { action: "I.ActionOption.R", labelKey: "hints.cycle", fallback: "Cycle" }
        ]

        CaptureGallery {
            anchors.fill: parent
            entries: screen.entries
            currentIndex: screen.selectedIndex
            styleTokens: screen.styleTokens
            motionTokens: screen.motionTokens
            i18n: screen.i18n
            focused: galleryZone.active
            interactive: !galleryZone.inert
            onEntryRequested: index => {
                if (galleryZone.requestZoneFocus()) {
                    if (index === screen.selectedIndex)
                        galleryZone.activate()
                    else
                        screen.select(index)
                }
            }
        }
    }

    CaptureViewerModal {
        anchors.fill: parent
        entries: screen.entries
        currentIndex: screen.viewerIndex
        i18n: screen.i18n
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        onEntryRequested: index => screen.viewerEntryId = screen.entries[index]?.id ?? ""
    }

    CaptureSettingsModal {
        anchors.fill: parent
        replayEnabled: screen.captureState?.replayEnabled ?? false
        microphone: screen.captureState?.microphone ?? false
        i18n: screen.i18n
        styleTokens: screen.styleTokens
        motionTokens: screen.motionTokens
        iconsPadManager: screen.iconsPadManager
        layerManager: screen.layerManager
        navigationManager: screen.navigationManager
        onOptionRequested: index => screen.mockSession?.dispatch(index === 0 ? "capture.buffer" : "capture.microphone", {})
    }
}
