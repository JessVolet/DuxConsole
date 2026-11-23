pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../core/shell"
import "../../core/interaction"
import "../../components/primitives/buttons"
import "../../components/widgets"
import "../modals"

ScreenBase {
    id: root

    screenId: "home"
    title: root.tr("nav.home", "Home")

    property var optionId: null
    readonly property bool captureOptionsFixture: mockSession?.scene === "home-options" && layerManager !== null

    onCaptureOptionsFixtureChanged: {
        if (captureOptionsFixture)
            captureOptionsOpening.restart()
    }

    Timer {
        id: captureOptionsOpening
        interval: 0
        onTriggered: {
            if (root.captureOptionsFixture && root.layerManager.topLayer === "dashboard")
                root.layerManager.push("mock-capture-settings")
        }
    }

    readonly property var entries: mockSession?.windows ?? []
    readonly property var session: mockSession?.session ?? null
    readonly property var track: mockSession?.track?.title ? mockSession.track : null
    readonly property real scaleFactor: Math.max(0.55, Math.min(1.5, width / 1920, height / 870))

    function focusWindow(id) {
        if (mockSession?.dispatch("window.focus", { id })?.status === "success")
            closeOverlayRequested()
    }

    function openOptions(id) {
        optionId = id
        layerManager?.push("mock-window-options")
    }

    SessionHero {
        id: hero
        x: root.width * 0.024
        y: parent.height * 0.11
        width: parent.width * 0.62
        scaleFactor: root.scaleFactor
        session: root.session
        fallbackTitle: root.tr("home.no_active_app", "No active application")
        styleTokens: root.styleTokens

        FocusZone {
            id: continueZone
            zoneId: "mock-home-continue"
            layerManager: root.layerManager
            navigationManager: root.navigationManager
            navRight: audioZone
            navDown: shelf
            showFocusRing: false
            width: continueButton.implicitWidth
            height: continueButton.implicitHeight
            enabled: Boolean(root.session?.title)
            actionHints: [{ action: "I.Accept", labelKey: "home.continue", fallback: "Continue" }]

            onActivated: {
                if (root.mockSession?.dispatch("session.resume", {})?.status === "success")
                    root.closeOverlayRequested()
            }

            ActionPill {
                id: continueButton
                anchors.fill: parent
                text: root.tr("home.continue", "Continue")
                glyphAction: "I.Accept"
                iconsPadManager: root.iconsPadManager
                styleTokens: root.styleTokens
                primary: true
                highlighted: continueZone.active
                enabled: continueZone.enabled && !continueZone.inert
                onClicked: {
                    if (continueZone.requestZoneFocus())
                        continueZone.activate()
                }
            }
        }

        FocusZone {
            id: audioZone
            zoneId: "mock-home-audio"
            layerManager: root.layerManager
            navigationManager: root.navigationManager
            navLeft: continueZone
            navDown: shelf
            showFocusRing: false
            width: audioButton.implicitWidth
            height: audioButton.implicitHeight

            onActivated: root.slideRequested("audio")

            ActionPill {
                id: audioButton
                anchors.fill: parent
                text: root.tr("nav.sound", "Sound")
                glyphAction: "I.Accept"
                iconsPadManager: root.iconsPadManager
                styleTokens: root.styleTokens
                highlighted: audioZone.active
                enabled: !audioZone.inert
                onClicked: {
                    if (audioZone.requestZoneFocus())
                        audioZone.activate()
                }
            }
        }
    }

    AchievementDigest {
        id: achievementDigest
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.spacingXL * 2
        anchors.rightMargin: root.width * 0.018
        width: parent.width * 0.265
        height: Math.max(62, 74 * root.scaleFactor)
        styleTokens: root.styleTokens
        achievement: root.session?.achievement ?? null
        recentLabel: root.tr("mockup.home.recent_achievement", "Recent achievement")
        progressLabel: root.tr("mockup.home.achievement_progress", "Achievement progress")
        unavailableLabel: root.tr("mockup.home.no_achievement", "No recent achievements")
    }

    MockWindowShelf {
        id: shelf
        x: hero.x
        width: parent.width * 0.69
        height: Math.min(parent.height * 0.34, Math.max(170, 258 * root.scaleFactor))
        anchors.bottom: parent.bottom
        entries: root.entries
        selectedId: root.mockSession?.selectedWindowId
        defaultFocus: true
        navUp: continueZone.enabled ? continueZone : audioZone
        navRight: mediaZone
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        i18n: root.i18n
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        onSelectionRequested: id => root.mockSession?.dispatch("window.select", { id })
        onActivationRequested: id => root.focusWindow(id)
        onOptionsRequested: id => root.openOptions(id)
        onExpandRequested: root.layerManager?.push("mock-windows")
    }

    FocusZone {
        id: mediaZone
        zoneId: "mock-home-media"
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        navLeft: shelf
        expandable: root.track !== null
        enabled: root.track !== null
        width: parent.width * 0.27
        height: Math.max(70, 100 * root.scaleFactor)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.width * 0.018
        actionHints: root.track ? [{ action: "I.Select", labelKey: "hints.expand", fallback: "Expand" }] : []

        onActivated: root.mockSession?.dispatch("media.play", {})
        onExpandRequested: root.layerManager?.push("mock-media")

        DemoMediaPlayer {
            anchors.fill: parent
            track: root.track
            i18n: root.i18n
            styleTokens: root.styleTokens
            motionTokens: root.motionTokens
            iconsPadManager: root.iconsPadManager
            interactive: !mediaZone.inert
            onPlayRequested: {
                if (mediaZone.requestZoneFocus())
                    mediaZone.activate()
            }
            onExpandRequested: {
                if (mediaZone.requestZoneFocus())
                    mediaZone.requestExpand()
            }
        }
    }

    SocialStatusCard {
        anchors.right: mediaZone.right
        anchors.bottom: mediaZone.top
        anchors.bottomMargin: Theme.spacingM
        styleTokens: root.styleTokens
        width: Math.min(mediaZone.width, 246 * root.scaleFactor)
        height: Math.max(52, 72 * root.scaleFactor)
        status: root.session?.social ?? null
        unavailableLabel: root.tr("mockup.home.no_social", "Offline")
    }

    MockWindowShelfModal {
        anchors.fill: parent
        entries: root.entries
        selectedId: root.mockSession?.selectedWindowId
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        header: root.tr("home.windows_section", "Active Windows")
        optionsLabel: root.tr("mockup.home.options", "Options")
        onActivationRequested: id => root.focusWindow(id)
        onOptionsRequested: id => root.openOptions(id)
    }

    MockWindowOptionsModal {
        anchors.fill: parent
        z: 41
        entry: root.entries.find(item => item.id === root.optionId) ?? null
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        styleTokens: root.styleTokens
        iconsPadManager: root.iconsPadManager
        title: root.tr("windows.actions_title", "Window Actions")
        focusLabel: root.tr("windows.hint_focus", "Focus window")
        onActivationRequested: id => root.focusWindow(id)
    }

    MediaDetailModal {
        anchors.fill: parent
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        i18n: root.i18n
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        iconsPadManager: root.iconsPadManager
        track: root.track
        onPlayRequested: root.mockSession?.dispatch("media.play", {})
        onSeekRequested: value => root.mockSession?.dispatch("media.seek", { position: value })
    }
    CaptureSettingsModal {
        anchors.fill: parent
        replayEnabled: root.mockSession?.capture?.replayEnabled ?? false
        microphone: root.mockSession?.capture?.microphone ?? false
        i18n: root.i18n
        styleTokens: root.styleTokens
        motionTokens: root.motionTokens
        iconsPadManager: root.iconsPadManager
        layerManager: root.layerManager
        navigationManager: root.navigationManager
        onOptionRequested: index => root.mockSession?.dispatch(index === 0 ? "capture.buffer" : "capture.microphone", {})
    }

}
