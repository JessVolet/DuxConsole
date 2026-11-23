import QtQuick
import Quickshell.Io
import "FixtureEvdev.js" as Evdev

Item {
    id: adapter

    property string devicePath: ""
    readonly property bool available: ready
    property bool ready: false
    property var decoder: Evdev.createDecoder()

    signal buttonChanged(string code, bool pressed)

    function consume(line) {
        const result = Evdev.consume(decoder, line)
        if (result.ready)
            ready = true
        for (const event of result.buttons)
            buttonChanged(event.code, event.pressed)
    }

    function reset() {
        for (const code of decoder.held)
            buttonChanged(code, false)
        decoder = Evdev.createDecoder()
        ready = false
    }

    Process {
        command: ["stdbuf", "-oL", "evtest", adapter.devicePath]
        running: /^\/dev\/input\/event\d+$/.test(adapter.devicePath)
        stdout: SplitParser {
            onRead: line => adapter.consume(line)
        }
        onRunningChanged: {
            if (!running)
                adapter.reset()
        }
    }
}
