.pragma library

function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value))
}

function clampRect(rect, bounds) {
    const width = clamp(rect.width, 0, bounds.width)
    const height = clamp(rect.height, 0, bounds.height)
    const maxX = Math.max(bounds.x, bounds.x + bounds.width - width)
    const maxY = Math.max(bounds.y, bounds.y + bounds.height - height)
    return Qt.rect(clamp(rect.x, bounds.x, maxX),
                   clamp(rect.y, bounds.y, maxY),
                   width, height)
}

function destination(source, bounds, size, horizontal, vertical, explicitTarget) {
    if (explicitTarget && explicitTarget.width > 0 && explicitTarget.height > 0)
        return clampRect(explicitTarget, bounds)
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
    return clampRect(Qt.rect(x, y, width, height), bounds)
}
