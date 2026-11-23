import QtQuick
import Quickshell.Io

Item {
    id: cava
    visible: false

    property bool active: false
    property int barCount: 20
    property var bars: []

    onActiveChanged: {
        if (!active)
            bars = []
    }

    Process {
        id: cavaProc
        running: cava.active
        command: [
            "sh", "-c",
            "printf '[general]\\nbars = " + cava.barCount + "\\nframerate = 30\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\nbar_delimiter = 59\\n' > /tmp/duxconsole-cava.conf && exec cava -p /tmp/duxconsole-cava.conf"
        ]

        stdout: SplitParser {
            onRead: data => {
                if (!cava.active)
                    return
                const parts = data.trim().split(";").filter(s => s.length > 0)
                if (parts.length === 0)
                    return
                const next = []
                for (let i = 0; i < parts.length; i++) {
                    const n = Number(parts[i])
                    next.push(isNaN(n) ? 0 : Math.max(0, Math.min(1, n / 100)))
                }
                cava.bars = next
            }
        }
    }
}
