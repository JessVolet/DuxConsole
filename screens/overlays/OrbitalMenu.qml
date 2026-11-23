import QtQuick
import qs.Common
import "../../core/interaction"
import "../../components/widgets"
import "../../services"
import "../modals"

Item {
    id: menu

    property string side: "left"
    property var layerManager: null
    property var navigationManager: null
    property var mockSession: null
    property var i18n: null
    property var styleTokens: null
    property var motionTokens: null
    property var iconsPadManager: null

    property var selectedCategories: ({ left: 0, right: 0 })
    property var selectedCommands: ({})
    property var detailCommand: null

    readonly property bool owningModal: detailCommand !== null
    readonly property bool ringActive: layerManager?.topLayer === "wheel"
    readonly property bool ringVisible: ringActive || (owningModal && layerManager?.topLayer === "modal")
    readonly property var categories: (source.value?.[side] ?? []).map(category => Object.assign({}, category, {
        label: tr("mockWheel.categories." + category.id, "")
    }))
    readonly property int categoryIndex: Math.max(0, Math.min(categories.length - 1, selectedCategories[side] ?? 0))
    readonly property var activeCategory: categories[categoryIndex] ?? null
    readonly property string commandScope: side + ":" + (activeCategory?.id ?? "")
    readonly property var commands: (activeCategory?.commands ?? []).map(command => Object.assign({}, command, {
        title: tr("mockWheel.commands." + command.id + ".title", ""),
        description: tr("mockWheel.commands." + command.id + ".description", "")
    }))
    readonly property int commandIndex: Math.max(0, Math.min(commands.length - 1, selectedCommands[commandScope] ?? 0))
    readonly property var activeCommand: commands[commandIndex] ?? null
    readonly property var telemetry: [
        tr("mockWheel.controllerBattery", "Controller %1%").arg(source.value?.telemetry?.controller ?? 0),
        tr("mockWheel.hostBattery", "Battery %1%").arg(source.value?.telemetry?.host ?? 0),
        tr("mockWheel.performance", "Balanced · %1 FPS").arg(source.value?.telemetry?.fps ?? 0)
    ]

    function tr(key, fallback) {
        return i18n ? i18n.t(key, fallback) : fallback
    }

    function setCategory(index) {
        if (!categories[index])
            return
        const next = Object.assign({}, selectedCategories)
        next[side] = index
        selectedCategories = next
    }

    function setCommand(index) {
        if (!commands[index])
            return
        const next = Object.assign({}, selectedCommands)
        next[commandScope] = index
        selectedCommands = next
    }

    function resetScene() {
        detailCommand = null
        selectedCategories = ({ left: 0, right: 0 })
        selectedCommands = ({})
    }

    function applyScene() {
        const scene = source.value?.scenes?.[mockSession?.scene]
        if (!scene || scene.side !== side)
            return

        const category = categories.findIndex(entry => entry.id === scene.category)
        if (category < 0)
            return

        setCategory(category)
        const command = commands.findIndex(entry => entry.id === scene.command)
        if (command >= 0)
            setCommand(command)
    }

    readonly property string sceneKey: mockSession?.scene ?? ""
    onSceneKeyChanged: applyScene()
    onSideChanged: applyScene()

    function execute(command, value) {
        if (command && mockSession)
            mockSession.dispatch("wheel-command", { id: command.id, value: value })
    }

    function activateCommand(index, expand) {
        if (!ringActive || !commands[index])
            return

        setCommand(index)
        const command = commands[index]
        if (command.detail || expand) {
            detailCommand = command
            layerManager.push("modal")
        } else {
            execute(command, true)
        }
    }

    function closeWheel() {
        if (ringActive)
            layerManager.pop()
    }

    MockCollectionData {
        id: source
        source: Qt.resolvedUrl("../../fixtures/mockup/wheels.json")
        onValueChanged: menu.applyScene()
    }

    Connections {
        target: menu.layerManager
        function onLayerPopped(layer) {
            if (layer === "modal")
                menu.detailCommand = null
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: menu.ringVisible
        onWheel: wheelEvent => wheelEvent.accepted = true
    }

    OrbitWheel {
        id: wheel
        anchors.fill: parent
        side: menu.side
        opened: menu.ringVisible
        categories: menu.categories
        commands: menu.commands
        currentCategory: menu.categoryIndex
        currentCommand: menu.commandIndex
        categoryFocused: categoryZone.active
        commandFocused: commandZone.active
        interactive: menu.ringActive
        styleTokens: menu.styleTokens
        motionTokens: menu.motionTokens
        originIcon: source.value?.originIcon ?? ""
        closeLabel: menu.tr("hints.back", "Back / Close")
        onCloseRequested: menu.closeWheel()
        onCategoryPicked: categoryIndex => {
            if (categoryZone.requestZoneFocus())
                menu.setCategory(categoryIndex)
        }
        onCommandPicked: commandIndex => {
            if (!commandZone.requestZoneFocus())
                return
            if (commandIndex === menu.commandIndex)
                menu.activateCommand(commandIndex, false)
            else
                menu.setCommand(commandIndex)
        }
    }

    CommandPreview {
        id: preview
        visible: menu.ringVisible && menu.activeCommand !== null
        x: menu.side === "right" ? parent.width * 0.04 : parent.width - width - parent.width * 0.04
        y: Theme.spacingL
        width: Math.max(0, Math.min(620, parent.width - wheel.outerRadius - Theme.spacingXL * 3))
        height: implicitHeight
        command: menu.activeCommand
        telemetry: menu.telemetry
        positionLabel: menu.activeCategory
            ? menu.activeCategory.label + " · " + (menu.commandIndex + 1) + " / " + menu.commands.length : ""
        currentValue: menu.mockSession?.wheelValue?.(menu.activeCommand?.id) ?? ""
        choices: (menu.activeCommand?.choices ?? []).map(choice => menu.tr("mockWheel.choices." + choice, choice.toString()))
        companionRows: menu.activeCommand?.id === "social-profile" ? (source.value?.companions ?? []).map(row => ({
            name: row.name,
            status: menu.tr(row.statusKey, "")
        })) : []
        styleTokens: menu.styleTokens
        motionTokens: menu.motionTokens
    }

    FocusZone {
        id: categoryZone
        x: wheel.originX - width / 2
        y: wheel.originY + wheel.innerRadius / 2
        width: wheel.innerRadius / 2
        height: width
        visible: menu.ringVisible
        enabled: menu.categories.length > 0
        zoneId: "mock-wheel-category"
        layerName: "wheel"
        layerManager: menu.layerManager
        navigationManager: menu.navigationManager
        showFocusRing: false
        subItemCount: menu.categories.length
        currentSubIndex: menu.categoryIndex
        navUp: commandZone
        navDown: commandZone
        navLeft: commandZone
        navRight: commandZone
        actionHints: [
            { action: "I.ActionOption.L", labelKey: "mockWheel.category", fallback: "Category" },
            { action: "I.ActionOption.R", labelKey: "mockWheel.category", fallback: "Category" }
        ]
        onActivated: commandZone.requestZoneFocus()
        onSubItemCycled: newIndex => menu.setCategory(newIndex)
    }

    FocusZone {
        id: commandZone
        x: wheel.originX + wheel.sideSign * wheel.outerRadius * 0.5 - width / 2
        y: wheel.originY + wheel.outerRadius * 0.58
        width: wheel.outerRadius / 2
        height: width
        visible: menu.ringVisible
        enabled: menu.commands.length > 0
        zoneId: "mock-wheel-command"
        layerName: "wheel"
        layerManager: menu.layerManager
        navigationManager: menu.navigationManager
        defaultFocus: true
        showFocusRing: false
        subItemCount: menu.commands.length
        currentSubIndex: menu.commandIndex
        expandable: menu.activeCommand !== null
        navUp: categoryZone
        navDown: categoryZone
        navLeft: categoryZone
        navRight: categoryZone
        actionHints: [
            { action: "I.Accept", labelKey: "hints.accept", fallback: "Accept" },
            { action: "I.Select", labelKey: "mockCollection.details", fallback: "Details" },
            { action: "I.ActionOption.L", labelKey: "mockCollection.browse", fallback: "Browse" },
            { action: "I.ActionOption.R", labelKey: "mockCollection.browse", fallback: "Browse" }
        ]
        onSubItemCycled: newIndex => menu.setCommand(newIndex)
        onActivated: itemIndex => menu.activateCommand(itemIndex, false)
        onExpandRequested: itemIndex => menu.activateCommand(itemIndex, true)
    }

    CommandDetailsModal {
        command: menu.detailCommand
        options: (menu.detailCommand?.choices ?? []).map(choice => ({
            id: choice,
            label: menu.tr("mockWheel.choices." + choice, choice.toString())
        }))
        telemetry: menu.telemetry
        layerManager: menu.layerManager
        navigationManager: menu.navigationManager
        styleTokens: menu.styleTokens
        motionTokens: menu.motionTokens
        confirmLabel: menu.tr("hints.accept", "Accept")
        cancelLabel: menu.tr("hints.back", "Back / Close")
        onCancelled: menu.layerManager?.pop()
        onChosen: value => {
            menu.execute(menu.detailCommand, value)
            if (menu.layerManager?.topLayer === "modal")
                menu.layerManager.pop()
        }
    }
}
