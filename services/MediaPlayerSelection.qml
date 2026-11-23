import QtQuick

QtObject {
    id: selection
    property var players: []
    property string selectedKey: ""
    property string pinnedKey: ""
    readonly property bool pinnedUnavailable: pinnedKey !== "" && !find(pinnedKey)
    readonly property var activePlayer: {
        if (pinnedKey !== "")
            return find(pinnedKey)
        return find(selectedKey) ?? players.find(p => p && p.isPlaying) ?? players[0] ?? null
    }

    function key(player) { return String(player?.dbusName ?? "") }
    function find(id) { return id !== "" ? players.find(p => key(p) === id) ?? null : null }
    function select(player) {
        if (!player || !find(key(player))) return
        selectedKey = key(player)
        if (pinnedKey !== "") pinnedKey = selectedKey
    }
    function togglePin(player) {
        const id = key(player)
        if (!id || !find(id)) return
        if (pinnedKey === id) pinnedKey = ""
        else { selectedKey = id; pinnedKey = id }
    }
    function automatic() { selectedKey = ""; pinnedKey = "" }
}
