.pragma library

function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value))
}

function destination(source, bounds, size, horizontal, vertical) {
    const width = clamp(size.width, 0, bounds.width)
    const height = clamp(size.height, 0, bounds.height)
    const left = horizontal === "left" || (horizontal === "auto"
        && source.x + source.width / 2 > bounds.x + bounds.width / 2)
    const up = vertical === "up" || (vertical === "auto"
        && source.y + source.height / 2 > bounds.y + bounds.height / 2)
    const x = horizontal === "center" ? source.x + (source.width - width) / 2
        : (left ? source.x + source.width - width : source.x)
    const y = vertical === "center" ? source.y + (source.height - height) / 2
        : (up ? source.y + source.height - height : source.y)
    return Qt.rect(clamp(x, bounds.x, bounds.x + bounds.width - width),
                   clamp(y, bounds.y, bounds.y + bounds.height - height), width, height)
}
