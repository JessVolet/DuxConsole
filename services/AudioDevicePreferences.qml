import QtQuick

QtObject {
    id: preferences
    property var store: null
    property var outputPins: []
    property var inputPins: []
    function load() {
        if (!store) return
        const outputs = store.loadPluginState("duxConsole", "audio.outputPins", [])
        const inputs = store.loadPluginState("duxConsole", "audio.inputPins", [])
        outputPins = Array.isArray(outputs) ? outputs.filter(k => typeof k === "string") : []
        inputPins = Array.isArray(inputs) ? inputs.filter(k => typeof k === "string") : []
    }
    onStoreChanged: load()
    Component.onCompleted: load()
    function pins(kind) { return kind === "output" ? outputPins : inputPins }
    function toggle(kind, key) {
        if (!key || (kind !== "output" && kind !== "input")) return
        const before = pins(kind)
        const after = before.includes(key) ? before.filter(k => k !== key) : before.concat([key])
        if (kind === "output") outputPins = after
        else inputPins = after
        store?.savePluginState("duxConsole", "audio." + kind + "Pins", after)
    }
    function sorted(model, kind) {
        const list = pins(kind)
        return model.slice().sort((a, b) => {
            const ai = list.indexOf(a.key), bi = list.indexOf(b.key)
            return (ai < 0 ? list.length : ai) - (bi < 0 ? list.length : bi)
        })
    }
}
