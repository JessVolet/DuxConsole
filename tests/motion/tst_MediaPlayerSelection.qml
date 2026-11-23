import QtQuick
import QtTest
import "../../services"

TestCase {
    name: "MediaPlayerSelection"
    MediaPlayerSelection { id: selection }
    QtObject { id: first; property string dbusName: "org.mpris.MediaPlayer2.one"; property string identity: "Same name"; property bool isPlaying: false }
    QtObject { id: second; property string dbusName: "org.mpris.MediaPlayer2.two"; property string identity: "Same name"; property bool isPlaying: true }
    function init() {
        selection.automatic()
        selection.players = [first, second]
    }
    function test_manualAndAutomatic() {
        compare(selection.activePlayer, second)
        selection.select(first)
        compare(selection.activePlayer, first)
        selection.automatic()
        compare(selection.activePlayer, second)
    }
    function test_pinDisconnectReconnect() {
        selection.togglePin(first)
        compare(selection.activePlayer, first)
        selection.players = [second]
        compare(selection.activePlayer, null)
        verify(selection.pinnedUnavailable)
        selection.players = [first, second]
        compare(selection.activePlayer, first)
        selection.automatic()
        compare(selection.activePlayer, second)
    }
    function test_removedUnpinnedFallsBack() {
        selection.select(first)
        selection.players = [second]
        compare(selection.activePlayer, second)
        selection.togglePin(second)
        selection.togglePin(second)
        compare(selection.pinnedKey, "")
    }
}
