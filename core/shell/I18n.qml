import QtQuick
import Quickshell.Io

Item {
    id: i18n
    visible: false

    property string configuredLanguage: "es"
    readonly property string effectiveLanguage: {
        if (configuredLanguage === "auto") {
            const sys = Qt.locale().name.slice(0, 2).toLowerCase()
            return (sys === "es" || sys === "en") ? sys : "es"
        }
        return configuredLanguage || "es"
    }

    property var translations: ({})

    FileView {
        id: uiConfigFile
        path: Qt.resolvedUrl("../../uiconfig.json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const cfg = JSON.parse(text())
                if (cfg && typeof cfg.language === "string" && cfg.language.length > 0)
                    i18n.configuredLanguage = cfg.language
            } catch (e) {
                console.warn("DuxConsole [I18n]: Error en uiconfig.json ->", e)
            }
        }
    }

    FileView {
        id: localeFile
        path: Qt.resolvedUrl("../../locales/" + i18n.effectiveLanguage + ".json").toString().replace("file://", "")
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                i18n.translations = JSON.parse(text())
            } catch (e) {
                console.warn("DuxConsole [I18n]: Error en locale ->", e)
                i18n.translations = ({})
            }
        }
    }

    function t(key, fallback) {
        if (!key)
            return fallback ?? ""

        if (translations && Object.prototype.hasOwnProperty.call(translations, key))
            return translations[key]

        const parts = key.split(".")
        let cur = translations
        for (let i = 0; i < parts.length; i++) {
            if (cur && typeof cur === "object" && Object.prototype.hasOwnProperty.call(cur, parts[i]))
                cur = cur[parts[i]]
            else
                return fallback ?? key
        }
        return typeof cur === "string" ? cur : (fallback ?? key)
    }
}
