import QtQuick
import QtTest
import "../../services"

TestCase {
    name: "AudioPreferences"
    QtObject {
        id: store
        property var state: ({})
        function loadPluginState(plugin, key, fallback) { return state[key] ?? fallback }
        function savePluginState(plugin, key, value) { const next = Object.assign({}, state); next[key] = value; state = next }
    }
    AudioDevicePreferences { id: preferences; store: store }
    function test_multiplePinsAndPersistence() {
        preferences.toggle("output", "b")
        preferences.toggle("output", "a")
        preferences.toggle("input", "mic")
        compare(preferences.sorted([{key:"a"}, {key:"b"}, {key:"c"}], "output")[0].key, "b")
        compare(preferences.inputPins.length, 1)
        preferences.outputPins = []
        preferences.load()
        compare(preferences.outputPins.length, 2)
        preferences.toggle("output", "b")
        compare(preferences.outputPins[0], "a")
        compare(preferences.inputPins[0], "mic")
    }
}
