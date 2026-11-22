import QtQuick
import "../../core/shell"
import "../../components/primitives/text"

ScreenBase {
    id: root
    screenId: "test2"
    title: root.i18n ? root.i18n.t("nav.sound", "Sound") : "Sound"

    TestText {
        anchors.centerIn: root
        label: root.title
    }
}
