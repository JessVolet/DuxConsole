pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../components/widgets"

TestCase {
    id: test
    name: "CarouselView"
    width: 700
    height: 700
    visible: true
    when: windowShown

    CarouselView {
        id: view
        width: 500
        height: 400
        model: 1
        cardWidth: 180
        selectedWidth: 240
        cardHeight: 100
        selectedHeight: 120
        delegate: Item {
            property int index: 0
            property var itemData: null
            width: 10
            height: 10
        }
    }

    function test_singleItemStaysCentered() {
        tryVerify(() => view.selectedItem !== null)
        const item = view.selectedItem
        const center = item.mapToItem(view, item.width / 2, item.height / 2)
        fuzzyCompare(center.x, view.width / 2, 1)
        fuzzyCompare(center.y, view.height / 2, 1)
    }

    function test_counts() {
        for (const count of [0, 1, 2, 5, 6]) {
            view.model = count
            compare(view.count, count)
            compare(view.visibleItemCount, Math.min(6, count))
        }
    }
}
