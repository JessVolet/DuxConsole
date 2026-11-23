.pragma library

function horizontalShearOffset(height, angleDeg) {
    return Math.abs(Math.tan(angleDeg * Math.PI / 180)) * Math.max(0, height)
}

function safeHorizontalInset(height, angleDeg, radius, extraMargin) {
    const shear = horizontalShearOffset(height, angleDeg)
    const corner = Math.max(0, radius || 0) * 0.25
    return Math.ceil(shear * 0.5 + corner + (extraMargin || 0))
}

function effectiveSkewAngle(baseAngle, width, height) {
    if (width < 680 || height < 400)
        return baseAngle * 0.5
    if (width < 880 || height < 500)
        return baseAngle * 0.75
    return baseAngle
}
