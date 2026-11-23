.pragma library

function createDecoder() {
    return { axis: "", axes: new Map(), held: new Set(), sources: new Map() }
}

function emitButton(state, buttons, code, pressed, source = code) {
    const sources = state.sources.get(code) ?? new Set()
    if (pressed)
        sources.add(source)
    else
        sources.delete(source)
    if (sources.size)
        state.sources.set(code, sources)
    else
        state.sources.delete(code)

    const held = sources.size > 0
    if (held === state.held.has(code))
        return
    if (held)
        state.held.add(code)
    else
        state.held.delete(code)
    buttons.push({ code, pressed: held })
}

function emitHat(state, buttons, axis, value, negative, positive) {
    if (value >= 0)
        emitButton(state, buttons, negative, false, axis)
    if (value <= 0)
        emitButton(state, buttons, positive, false, axis)
    if (value < 0)
        emitButton(state, buttons, negative, true, axis)
    if (value > 0)
        emitButton(state, buttons, positive, true, axis)
}

function consume(state, line) {
    const buttons = []
    const axis = /^\s+Event code \d+ \((ABS_[A-Z0-9_]+)\)/.exec(line)
    if (axis) {
        state.axis = axis[1]
        state.axes.set(state.axis, {})
    }
    const bound = /^\s+(Min|Max)\s+(-?\d+)\s*$/.exec(line)
    if (bound && state.axes.has(state.axis))
        state.axes.get(state.axis)[bound[1]] = Number(bound[2])

    const event = /^Event: .*type \d+ \(EV_(KEY|ABS)\), code \d+ \(([A-Z0-9_]+)\), value (-?\d+)\s*$/.exec(line)
    if (!event)
        return { ready: line.startsWith("Testing ..."), buttons }

    const code = event[2]
    const value = Number(event[3])
    if (event[1] === "KEY" && code.startsWith("BTN_") && (value === 0 || value === 1)) {
        const aliases = {
            BTN_TRIGGER_HAPPY1: "BTN_DPAD_LEFT",
            BTN_TRIGGER_HAPPY2: "BTN_DPAD_RIGHT",
            BTN_TRIGGER_HAPPY3: "BTN_DPAD_UP",
            BTN_TRIGGER_HAPPY4: "BTN_DPAD_DOWN"
        }
        emitButton(state, buttons, aliases[code] ?? code, value === 1, code)
    } else if (event[1] === "ABS") {
        if (code === "ABS_HAT0X")
            emitHat(state, buttons, code, value, "BTN_DPAD_LEFT", "BTN_DPAD_RIGHT")
        else if (code === "ABS_HAT0Y")
            emitHat(state, buttons, code, value, "BTN_DPAD_UP", "BTN_DPAD_DOWN")
        else if (code === "ABS_Z" || code === "ABS_RZ") {
            const range = state.axes.get(code)
            if (range && range.Max > range.Min) {
                const fraction = (value - range.Min) / (range.Max - range.Min)
                emitButton(state, buttons, code, fraction >= (state.held.has(code) ? 0.4 : 0.6))
            }
        }
    }
    return { ready: false, buttons }
}
