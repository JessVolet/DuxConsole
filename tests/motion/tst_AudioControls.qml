pragma ComponentBehavior: Bound
import QtQuick
import QtTest
import "../../services"
import "../../components/widgets/audio"
import "../../core/interaction"

TestCase {
    id: test
    name: "AudioControls"
    width: 1200
    height: 800
    visible: true
    when: windowShown
    QtObject { id: appAudio; property real volume: 0.4; property bool muted: false }
    QtObject { id: secondAudio; property real volume: 0.8; property bool muted: false }
    QtObject { id: outputAudio; property real volume: 0.6; property bool muted: false }
    QtObject { id: inputAudio; property real volume: 0.3; property bool muted: false }
    QtObject { id: app; property string name: "stream1"; property bool isStream: true; property bool isSink: true; property var properties: ({"application.id":"game"}); property var audio: appAudio }
    QtObject { id: app2; property string name: "stream2"; property bool isStream: true; property bool isSink: true; property var properties: ({"application.id":"game"}); property var audio: secondAudio }
    QtObject { id: output; property string name: "speaker"; property bool isStream: false; property bool isSink: true; property var audio: outputAudio }
    QtObject { id: input; property string name: "microphone"; property bool isStream: false; property bool isSink: false; property var audio: inputAudio }
    QtObject {
        id: backend
        property var allNodes: [app, app2, output, input]
        property var sink: null
        property var source: null
        property int references: 0
        property var outputChoices: ({speaker:[{kind:"port", sinkName:"speaker", portName:"headphones", title:"Headphones"}]})
        property string lastPort: ""
        function addRef() { references++ }
        function removeRef() { references-- }
        function setSink(node) { sink = node; return true }
        function setSource(node) { source = node; return true }
        function displayName(node) { return node.name }
        function getMaxVolumePercent(node) { return 100 }
        function activateOutputChoice(choice, callback) { lastPort = choice.portName; callback(true, "") }
    }
    QtObject {
        id: style
        property real skewAngle: -8
        property color errorColor: "#B00020"
        property color accentColor: "white"
        function surfaceColor(role, opacity) { return "black" }
        function onSurfaceColor(role) { return "white" }
        function disabledSurfaceColor(role) { return "black" }
        function borderColor(role) { return "gray" }
    }
    AudioControlService { id: audio; backend: backend }
    QtObject {
        id: inputBus
        property var config: ({analog:{right:{action:"I.Stick.R"}}})
        signal triggered(string action, var payload)
        signal analogReset()
    }
    LayerManager { id: layers; navigationManager: navigation }
    NavigationManager { id: navigation; layerManager: layers; rootContainer: test }
    AudioControls {
        id: controls
        anchors.fill: parent
        audioService: audio
        inputManager: inputBus
        layerManager: layers
        navigationManager: navigation
        styleTokens: style
    }
    function test_groupVolumeAndStaleKey() {
        compare(audio.applications.length, 1)
        fuzzyCompare(audio.applications[0].volume, 0.8, 0.001)
        verify(audio.setVolume("app:game", 0.5))
        compare(appAudio.volume, 0.5)
        compare(secondAudio.volume, 0.5)
        compare(audio.applications[0].volume, 0.5)
        compare(outputAudio.volume, 0.6)
        verify(!audio.setVolume("app:missing", 1))
        verify(!audio.setVolume("unknown:microphone", 1))
        audio.setMuted("app:game", true)
        verify(appAudio.muted && secondAudio.muted && !outputAudio.muted)
    }
    function test_optionsFocusReturn() {
        navigation.ensureFocus("dashboard")
        const sourceZone = layers.activeZone
        const options = findChild(controls, "audio-device-options")
        options.open("output:speaker", controls)
        tryVerify(() => layers.activeZone?.layerName === options.layerName)
        layers.pop()
        tryCompare(layers, "activeZone", sourceZone)
    }
    function test_supportedOptions() {
        compare(audio.choices("input:microphone").length, 0)
        const choices = audio.choices("output:speaker")
        compare(choices.length, 1)
        audio.applyChoice("output:speaker", choices[0])
        compare(backend.lastPort, "headphones")
        backend.lastPort = ""
        audio.applyChoice("output:missing", choices[0])
        compare(backend.lastPort, "")
    }
    function test_rightStickAndMuteRouting() {
        navigation.ensureFocus("dashboard")
        inputBus.triggered("I.Stick.R", {x:0,y:0})
        inputBus.triggered("I.Stick.R", {x:1,y:0})
        fuzzyCompare(appAudio.volume, 5/6, 0.001)
        compare(outputAudio.volume, 0.6)
        const before = appAudio.muted
        const volumeBeforeMute = appAudio.volume
        inputBus.triggered("I.PressStick.R", null)
        compare(appAudio.muted, !before)
        fuzzyCompare(appAudio.volume, volumeBeforeMute, 0.001)
        // The bottom gap keeps the last value and drops engagement.
        inputBus.triggered("I.Stick.R", {x:0,y:1})
        fuzzyCompare(appAudio.volume, volumeBeforeMute, 0.001)
        inputBus.analogReset()
        inputBus.triggered("I.Stick.R", {x:0,y:-1})
        fuzzyCompare(appAudio.volume, volumeBeforeMute, 0.001)
        // Re-engagement requires a neutral position first.
        inputBus.triggered("I.Stick.R", {x:0,y:0})
        inputBus.triggered("I.Stick.R", {x:0,y:-1})
        fuzzyCompare(appAudio.volume, 0.5, 0.001)
    }
    function test_deviceIndependence() {
        verify(audio.activate("output:speaker"))
        compare(backend.sink, output)
        compare(backend.source, null)
        verify(audio.activate("input:microphone"))
        compare(backend.source, input)
        audio.togglePin("output:speaker")
        verify(audio.outputs[0].pinned)
        verify(!audio.inputs[0].pinned)
    }
    function test_compositionFocus() {
        navigation.ensureFocus("dashboard")
        tryVerify(() => controls.focusedTarget !== null)
        compare(controls.focusedTarget.kind, "app")
        verify(backend.references > 0)
    }
}
