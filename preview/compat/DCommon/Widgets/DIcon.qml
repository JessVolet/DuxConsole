import QtQuick
import qs.Common

Text {
    id: icon

    property string name: ""
    property alias size: icon.font.pixelSize
    readonly property var characters: ({
        photo_camera: "◉", videocam: "▣", stop_circle: "●", replay: "↻",
        sports_esports: "✛", volume_up: "◖", volume_off: "⊘", brightness_6: "☀",
        power_settings_new: "⏻", play_arrow: "▶", pause: "Ⅱ", settings: "⚙",
        emoji_events: "✦", person: "✿", headset: "♫", mic: "♩", close: "×",
        apps: "⠿", computer: "▣", language: "◎", headphones: "♫",
        auto_awesome: "✦", bedtime: "☾", bolt: "ϟ", group: "♟", light_mode: "☀",
        mic_off: "⊘", monitor: "▱", nightlight: "☾", play_pause: "⏯",
        queue_music: "♬", replay_30: "↺", skip_next: "⏭", skip_previous: "⏮",
        speed: "◴", tune: "≋", sensors: "◌", collections_bookmark: "▣", explore: "✧", live_tv: "▶", multitrack_audio: "♫", landscape: "▵"
    })

    font.pixelSize: Theme.iconSize
    color: Theme.surfaceText
    text: characters[name] ?? "•"
}
