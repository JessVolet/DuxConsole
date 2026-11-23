import QtQuick
import Quickshell
import Quickshell.Io
import "./core/shell"
import "./services"

ShellRoot {
    id: preview

    property bool dashboardOpen: true

    ConsoleOverlay {
        id: overlay
        active: preview.dashboardOpen
        fixtureMode: true
        fixtureControllerAvailable: gamepad.available
        onCloseRequested: preview.dashboardOpen = false
    }

    FixtureGamepad {
        id: gamepad
        devicePath: Quickshell.env("DUX_PREVIEW_CONTROLLER") ?? ""
        onButtonChanged: (code, pressed) => overlay.handleFixtureButton(code, pressed)
    }

    IpcHandler {
        target: "duxConsoleMock"

        function scene(name: string): void {
            preview.dashboardOpen = true
            overlay.showFixture(name)
        }

        function action(name: string): void {
            overlay.dispatchAction(name, null)
        }

        function close(): void {
            overlay.showFixture("dismissed")
        }

        function state(): string {
            return overlay.previewState()
        }

        function viewport(width: int, height: int): void {
            overlay.previewSize = Qt.size(width, height)
        }

        function frame(path: string): bool {
            return overlay.saveFrame(path)
        }
    }
}
