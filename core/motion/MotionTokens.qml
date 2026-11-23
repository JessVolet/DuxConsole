import QtQuick
import Quickshell.Io

Item {
    id: motion
    visible: false

    property bool animationsEnabled: true
    property bool suppressAnimations: false
    property real speedScale: 1.0
    property int fadeInMs: 180
    property int fadeOutMs: 140
    property int noticeMs: 2600
    property int homeCarouselMs: 350
    property int wheelWaveMs: 420
    property int wheelCloseMs: 180
    property real wheelOvershoot: 0.8
    property int sheetEntranceMs: 250

    function scaled(baseMs) {
        if (!animationsEnabled || suppressAnimations)
            return 0
        return Math.max(0, Math.round(baseMs / Math.max(0.1, speedScale)))
    }

    readonly property int durationFast: scaled(120)
    readonly property int durationNormal: scaled(220)
    readonly property int durationMorph: scaled(280)
    readonly property int homeCarouselDuration: scaled(homeCarouselMs)
    readonly property int wheelWaveDuration: scaled(wheelWaveMs)
    readonly property int wheelCloseDuration: scaled(wheelCloseMs)
    readonly property int sheetEntranceDuration: scaled(sheetEntranceMs)
    readonly property int fadeInDuration: scaled(fadeInMs)
    readonly property int fadeOutDuration: scaled(fadeOutMs)

    readonly property int easingSnappy: Easing.OutCubic
    readonly property int easingSmooth: Easing.InOutCubic
    readonly property int easingSpring: Easing.OutBack
    readonly property int fadeInEasing: Easing.OutCubic
    readonly property int fadeOutEasing: Easing.InCubic

    FileView {
        id: uiConfigFile
        path: Qt.resolvedUrl("../../uiconfig.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const cfg = JSON.parse(text())
                if (cfg?.animations) {
                    if (typeof cfg.animations.enabled === "boolean")
                        motion.animationsEnabled = cfg.animations.enabled
                    if (typeof cfg.animations.speed === "number")
                        motion.speedScale = cfg.animations.speed
                    if (typeof cfg.animations.homeCarouselMs === "number")
                        motion.homeCarouselMs = Math.max(0, cfg.animations.homeCarouselMs)
                    if (typeof cfg.animations.wheelWaveMs === "number")
                        motion.wheelWaveMs = Math.max(0, cfg.animations.wheelWaveMs)
                    if (typeof cfg.animations.wheelCloseMs === "number")
                        motion.wheelCloseMs = Math.max(0, cfg.animations.wheelCloseMs)
                    if (typeof cfg.animations.wheelOvershoot === "number")
                        motion.wheelOvershoot = Math.max(0, Math.min(2, cfg.animations.wheelOvershoot))
                    if (typeof cfg.animations.sheetEntranceMs === "number")
                        motion.sheetEntranceMs = Math.max(0, cfg.animations.sheetEntranceMs)
                    if (typeof cfg.animations.fadeInMs === "number")
                        motion.fadeInMs = cfg.animations.fadeInMs
                    if (typeof cfg.animations.noticeMs === "number")
                        motion.noticeMs = Math.max(0, cfg.animations.noticeMs)
                    if (typeof cfg.animations.fadeOutMs === "number")
                        motion.fadeOutMs = cfg.animations.fadeOutMs
                }
            } catch (e) {
                console.warn("DuxConsole [MotionTokens]: Error en uiconfig.json ->", e)
            }
        }
    }
}
