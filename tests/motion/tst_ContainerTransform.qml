pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../core/motion"

TestCase {
    id: test
    name: "ContainerTransform"
    width: 1000
    height: 700
    when: windowShown
    QtObject {
        id: tokens
        property int containerTransformDuration: 80
        property int containerTransformEasing: Easing.OutCubic
        property var containerTransform: ({})
    }
    Item { id: origin; x: 700; y: 400; width: 64; height: 64 }
    ContainerTransform {
        id: morph
        sourceItem: origin
        motionTokens: tokens
        expandedSize: Qt.size(400, 300)
    }

    function init() {
        morph.expanded = false
        wait(tokens.containerTransformDuration + 20)
    }

    function checkAnchor() {
        fuzzyCompare(morph.x + morph.anchorOffset.x, morph.sourceRect.x + morph.sourceRect.width / 2, 0.001)
        fuzzyCompare(morph.y + morph.anchorOffset.y, morph.sourceRect.y + morph.sourceRect.height / 2, 0.001)
    }

    function test_corners() {
        for (const pos of [Qt.point(24,24), Qt.point(912,24), Qt.point(24,612), Qt.point(912,612)]) {
            origin.x = pos.x; origin.y = pos.y
            morph.expanded = true
            for (let frame = 0; frame < 8; frame++) { wait(16); checkAnchor() }
            compare(morph.sourceRect.x, origin.x)
            verify(morph.contentReady)
            verify(morph.x >= 24 && morph.y >= 24)
            verify(morph.x + morph.width <= 976 && morph.y + morph.height <= 676)
            morph.expanded = false
            wait(100)
            compare(morph.x, origin.x)
            compare(morph.y, origin.y)
        }
    }

    function test_reverseAndResize() {
        morph.expanded = true
        wait(25)
        morph.expanded = false
        wait(15)
        checkAnchor()
        morph.expanded = true
        morph.expandedSize = Qt.size(1400, 900)
        wait(120)
        checkAnchor()
        compare(morph.width, 952)
        compare(morph.height, 652)
        morph.expandedSize = Qt.size(400, 300)
    }

    function test_disabledAnimation() {
        tokens.containerTransformDuration = 0
        origin.x = 123
        morph.expanded = true
        compare(morph.sourceRect.x, 123)
        compare(morph.progress, 1)
        verify(morph.contentReady)
        morph.expanded = false
        compare(morph.progress, 0)
        tokens.containerTransformDuration = 80
    }
}
