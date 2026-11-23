.pragma library

function wrap(index, count) {
    return ((index % count) + count) % count
}

function direction(from, to, count) {
    if (from < 0 || to < 0 || count < 2 || from === to)
        return 0
    const forward = wrap(to - from, count)
    return forward <= count / 2 ? 1 : -1
}

function placements(items, selectedId, budget, leading) {
    const count = items.length
    if (!count)
        return []

    const visibleCount = Math.min(count, Math.max(1, budget))
    const leadingCount = Math.min(leading, Math.max(0, visibleCount - 2))
    const first = items.findIndex(item => item.id === selectedId)
    const selectedIndex = first < 0 ? 0 : first
    const placements = []
    for (let slot = 0; slot < visibleCount; ++slot) {
        const offset = slot - leadingCount
        const index = wrap(selectedIndex + offset, count)
        placements.push({ entry: items[index], index, offset, slot })
    }
    return placements
}
