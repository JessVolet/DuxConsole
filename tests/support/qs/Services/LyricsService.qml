pragma Singleton
import QtQuick

QtObject {
    property var controller: QtObject {
        property bool available: false
        property bool pending: false
        property string state: "none"
        property bool synced: false
        property var lines: []
        property var plainLines: []
        property int activeIndex: -1
        property var track: null
    }
}
