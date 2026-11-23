.pragma library

function fraction(x, y) {
    if (!Number.isFinite(x) || !Number.isFinite(y)) return -1
    const angle = Math.atan2(x, -y) * 180 / Math.PI
    return Math.abs(angle) <= 135 ? (angle + 135) / 270 : -1
}
