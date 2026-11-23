pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../components/primitives/surfaces"

TestCase {
    id: test
    name: "TransformSurface"
    width: 800
    height: 600
    when: windowShown
    QtObject {
        id: style
        property real skewAngle: -8
        property color accentColor: "white"
        function surfaceColor(role, opacity) { return "black" }
        function borderColor(role) { return "white" }
    }
    TransformSurface {
        id: morph
        styleTokens: style
        sourceRect: Qt.rect(200, 200, 64, 64)
        expandedSize: Qt.size(360, 260)
        originContent: Component { Item { objectName: "originDelegate" } }
        Item { objectName: "detail" }
    }

    function test_composition() {
        morph.expanded = true
        verify(morph.contentReady)
        const detail = findChild(morph, "detail")
        verify(detail !== null)
        verify(detail.parent !== morph)
        const badge = findChild(morph, "originDelegate")
        verify(badge !== null)
        const center = badge.mapToItem(test, badge.width / 2, badge.height / 2)
        fuzzyCompare(center.x, 232, 0.001)
        fuzzyCompare(center.y, 232, 0.001)
        verify(morph.surfaceItem.shapeInset > 0)
        morph.shape = "rectangle"
        compare(morph.surfaceItem.shapeInset, 0)
        compare(morph.surfaceItem.radius, 0)
        morph.expanded = false
    }
}
