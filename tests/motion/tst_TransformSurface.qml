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
        property color errorColor: "#B00020"
        property color accentColor: "white"
        property color m3Surface: "#130c0c"
        property color m3SurfaceLow: "#191111"
        property color m3SurfaceContainer: "#201717"
        property color m3SurfaceHigh: "#271d1d"
        property color m3SurfaceHighest: "#2e2323"
        property color m3OnSurface: "#f7e7e6"
        property color m3OnSurfaceVariant: "#b6a8a7"
        property color m3OutlineVariant: "#504645"
        property color m3Primary: "#fd9c97"
        property color m3OnPrimary: "#5f1f1e"
        property color m3SecondaryContainer: "#6b3836"
        property color m3OnSecondaryContainer: "#ffc1bd"
        function m3Alpha(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha) }
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
