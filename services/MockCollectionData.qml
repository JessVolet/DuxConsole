import QtQuick
import Quickshell.Io

Item {
    id: data

    required property url source

    property var value: null

    visible: false

    FileView {
        id: file
        path: data.source.toString().replace(/^file:\/\//, "")
        blockLoading: true
        onLoaded: {
            try {
                data.value = JSON.parse(text())
            } catch (error) {
                console.warn("DuxConsole fixture JSON:", data.source, error)
                data.value = null
            }
        }
    }
}
