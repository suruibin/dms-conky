import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginSettings {
    id: root
    pluginId: "dmsconky"

    // ── Settings I18n (loaded from translations/i18n/*.json via FileView) ─────
    property string _settingsLang: root.loadValue("pluginLanguage", "en")
    on_SettingsLangChanged: _applySettingsI18n(_settingsLang)
    property var _settingsI18nMap: ({})
    property int _settingsI18nToken: 0
    property string _pickerTargetKey: ""
    property string _schemeFeedback: ""

    FileView {
        id: settingsI18nLoader
        onLoaded: {
            try {
                root._settingsI18nMap = JSON.parse(text());
                root._settingsI18nToken++;
                console.info("DmsConky Settings: loaded translations for", root._settingsLang);
            } catch (e) {
                console.warn("DmsConky Settings: error parsing i18n:", e);
            }
        }
        onLoadFailed: error => {
            console.warn("DmsConky Settings: failed to load i18n:", error);
            if (root._settingsLang !== "en") {
                settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/en.json");
            }
        }
    }

    function _applySettingsI18n(locale) {
        if (locale === "System Default" || locale === "") locale = "system";
        if (!locale) { _settingsI18nMap = {}; return; }
        if (locale === "system") {
            var sys = Qt.locale().name;
            var parts = sys.split("_");
            sys = parts.length > 0 ? parts[0] : "en";
            settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/" + sys + ".json");
        } else {
            settingsI18nLoader.path = Qt.resolvedUrl("translations/i18n/" + locale + ".json");
        }
    }

    // Poll for language changes
    Timer {
        running: true
        repeat: true
        interval: 800
        onTriggered: {
            var lang = root.loadValue("pluginLanguage", "en")
            if (lang !== root._settingsLang)
                root._settingsLang = lang
        }
    }

    // ── Exposed translated properties (direct property bindings for reliable re-eval) ──
    readonly property string _trModule:    { _settingsI18nToken; return _settingsI18nMap["Module"]     || I18n.tr("Module") }
    readonly property string _trClock:     { _settingsI18nToken; return _settingsI18nMap["Clock"]      || I18n.tr("Clock") }
    readonly property string _trWeather:   { _settingsI18nToken; return _settingsI18nMap["Weather"]     || I18n.tr("Weather") }
    readonly property string _trNetwork:   { _settingsI18nToken; return _settingsI18nMap["Network"]     || I18n.tr("Network") }
    readonly property string _trMusic:     { _settingsI18nToken; return _settingsI18nMap["Music"]       || I18n.tr("Music") }
    readonly property string _trStorage:   { _settingsI18nToken; return _settingsI18nMap["Storage"]     || I18n.tr("Storage") }
    readonly property string _trRotatingAlbum: { _settingsI18nToken; return _settingsI18nMap["Rotating Album"] || I18n.tr("Rotating Album") }
    readonly property string _trDefaultView:   { _settingsI18nToken; return _settingsI18nMap["Default View"]   || I18n.tr("Default View") }
    readonly property string _trConky:    { _settingsI18nToken; return _settingsI18nMap["Conky"]        || I18n.tr("Conky") }
    readonly property string _trApps:     { _settingsI18nToken; return _settingsI18nMap["Apps"]         || I18n.tr("Apps") }
    readonly property string _trColors:   { _settingsI18nToken; return _settingsI18nMap["Colors"]       || I18n.tr("Colors") }
    readonly property string _trClockColors:    { _settingsI18nToken; return _settingsI18nMap["Clock Colors"]    || I18n.tr("Clock Colors") }
    readonly property string _trHour:    { _settingsI18nToken; return _settingsI18nMap["Hour"]   || I18n.tr("Hour") }
    readonly property string _trMinute:  { _settingsI18nToken; return _settingsI18nMap["Minute"] || I18n.tr("Minute") }
    readonly property string _trSecond:  { _settingsI18nToken; return _settingsI18nMap["Second"] || I18n.tr("Second") }
    readonly property string _trColon:   { _settingsI18nToken; return _settingsI18nMap["Colon"]  || I18n.tr("Colon") }
    readonly property string _trWeekday: { _settingsI18nToken; return _settingsI18nMap["Weekday"]|| I18n.tr("Weekday") }
    readonly property string _trDay:     { _settingsI18nToken; return _settingsI18nMap["Day"]    || I18n.tr("Day") }
    readonly property string _trMonth:   { _settingsI18nToken; return _settingsI18nMap["Month"]  || I18n.tr("Month") }
    readonly property string _trRingGaugeColors:{ _settingsI18nToken; return _settingsI18nMap["Ring Gauge Colors"] || I18n.tr("Ring Gauge Colors") }
    readonly property string _trCPU:     { _settingsI18nToken; return _settingsI18nMap["CPU"]     || I18n.tr("CPU") }
    readonly property string _trMemory:  { _settingsI18nToken; return _settingsI18nMap["Memory"]  || I18n.tr("Memory") }
    readonly property string _trBattery: { _settingsI18nToken; return _settingsI18nMap["Battery"] || I18n.tr("Battery") }
    readonly property string _trAC:      { _settingsI18nToken; return _settingsI18nMap["AC"]      || I18n.tr("AC") }
    readonly property string _trTemp:    { _settingsI18nToken; return _settingsI18nMap["Temp"]    || I18n.tr("Temp") }
    readonly property string _trBg:      { _settingsI18nToken; return _settingsI18nMap["Bg"]      || I18n.tr("Bg") }
    readonly property string _trDisplay: { _settingsI18nToken; return _settingsI18nMap["Display"] || I18n.tr("Display") }
    readonly property string _trTransparency: { _settingsI18nToken; return _settingsI18nMap["Transparency"] || I18n.tr("Transparency") }
    readonly property string _trWidgetSize:   { _settingsI18nToken; return _settingsI18nMap["Widget Size"]   || I18n.tr("Widget Size") }
    readonly property string _trIconSize:     { _settingsI18nToken; return _settingsI18nMap["Icon Size"]     || I18n.tr("Icon Size") }
    readonly property string _trMusicPlayer:  { _settingsI18nToken; return _settingsI18nMap["Music Player"]  || I18n.tr("Music Player") }
    readonly property string _trParticles:    { _settingsI18nToken; return _settingsI18nMap["Particles"]     || I18n.tr("Particles") }
    readonly property string _trEnable:       { _settingsI18nToken; return _settingsI18nMap["Enable"]        || I18n.tr("Enable") }
    readonly property string _trStyle:        { _settingsI18nToken; return _settingsI18nMap["Style"]         || I18n.tr("Style") }
    readonly property string _trOpacity:      { _settingsI18nToken; return _settingsI18nMap["Opacity"]       || I18n.tr("Opacity") }
    readonly property string _trCount:        { _settingsI18nToken; return _settingsI18nMap["Count"]         || I18n.tr("Count") }
    readonly property string _trSize:         { _settingsI18nToken; return _settingsI18nMap["Size"]          || I18n.tr("Size") }
    readonly property string _trLanguage:     { _settingsI18nToken; return _settingsI18nMap["Language"]      || I18n.tr("Language") }
    readonly property string _trSystemDefault:{ _settingsI18nToken; return _settingsI18nMap["System Default"]|| I18n.tr("System Default") }
    readonly property string _trRoot:         { _settingsI18nToken; return _settingsI18nMap["Root"]          || I18n.tr("Root") }
    readonly property string _trHome:         { _settingsI18nToken; return _settingsI18nMap["Home"]          || I18n.tr("Home") }
    readonly property string _trHardWare:     { _settingsI18nToken; return _settingsI18nMap["HardWare"]      || I18n.tr("HardWare") }
    readonly property string _trGPU:          { _settingsI18nToken; return _settingsI18nMap["GPU"]           || I18n.tr("GPU") }
    readonly property string _trDown:         { _settingsI18nToken; return _settingsI18nMap["Down"]          || I18n.tr("Down") }
    readonly property string _trUp:           { _settingsI18nToken; return _settingsI18nMap["Up"]            || I18n.tr("Up") }
    readonly property string _trIcon:         { _settingsI18nToken; return _settingsI18nMap["Icon"]          || I18n.tr("Icon") }
    readonly property string _trStart:        { _settingsI18nToken; return _settingsI18nMap["Start"]         || I18n.tr("Start") }
    readonly property string _trEnd:          { _settingsI18nToken; return _settingsI18nMap["End"]           || I18n.tr("End") }
    readonly property string _trCity:         { _settingsI18nToken; return _settingsI18nMap["City"]          || I18n.tr("City") }
    readonly property string _trArtist:       { _settingsI18nToken; return _settingsI18nMap["Artist"]        || I18n.tr("Artist") }
    readonly property string _trTitle:        { _settingsI18nToken; return _settingsI18nMap["Title"]         || I18n.tr("Title") }
    readonly property string _trTime:         { _settingsI18nToken; return _settingsI18nMap["Time"]          || I18n.tr("Time") }
    readonly property string _trBorder:       { _settingsI18nToken; return _settingsI18nMap["Border"]        || I18n.tr("Border") }
    readonly property string _trWind:         { _settingsI18nToken; return _settingsI18nMap["Wind"]          || I18n.tr("Wind") }
    readonly property string _trHumidity:     { _settingsI18nToken; return _settingsI18nMap["Humidity"]      || I18n.tr("Humidity") }
    readonly property string _trAbout:        { _settingsI18nToken; return _settingsI18nMap["About"]         || I18n.tr("About") }
    readonly property string _trGitHub:       { _settingsI18nToken; return _settingsI18nMap["GitHub"]        || I18n.tr("GitHub") }
    readonly property string _trBugRequest:   { _settingsI18nToken; return _settingsI18nMap["Found a bug or have a feature request? Join us on GitHub."] || I18n.tr("Found a bug or have a feature request? Join us on GitHub.") }
    readonly property string _trGuiHint:      { _settingsI18nToken; return _settingsI18nMap["GUI: /path/to/app | Terminal: alacritty -e /path/to/app | Kitty: kitty /path/to/app | Konsole: konsole -e /path/to/app"] || I18n.tr("GUI: /path/to/app | Terminal: alacritty -e /path/to/app | Kitty: kitty /path/to/app | Konsole: konsole -e /path/to/app") }
    readonly property string _trColorSchemes:{ _settingsI18nToken; return _settingsI18nMap["Color Schemes"]  || I18n.tr("Color Schemes") }
    readonly property string _trExport:       { _settingsI18nToken; return _settingsI18nMap["Export"]         || I18n.tr("Export") }
    readonly property string _trImport:       { _settingsI18nToken; return _settingsI18nMap["Import"]         || I18n.tr("Import") }
    readonly property string _trSafe:         { _settingsI18nToken; return _settingsI18nMap["Safe"]           || I18n.tr("Safe") }
    readonly property string _trWarn:         { _settingsI18nToken; return _settingsI18nMap["Warn"]           || I18n.tr("Warn") }
    readonly property string _trDanger:       { _settingsI18nToken; return _settingsI18nMap["Danger"]         || I18n.tr("Danger") }
    readonly property string _trSaveCurrent:  { _settingsI18nToken; return _settingsI18nMap["Save Current"]  || I18n.tr("Save Current") }
    readonly property string _trDelete:       { _settingsI18nToken; return _settingsI18nMap["Delete"]        || I18n.tr("Delete") }
    readonly property string _trSchemeSaved:  { _settingsI18nToken; return _settingsI18nMap["Scheme saved!"] || I18n.tr("Scheme saved!") }

    function saveAndPersist(key, value) {
        root.saveValue(key, value)
        SettingsData.setPluginSetting(root.pluginId, key, value)
        SettingsData.savePluginSettings()
    }

    // ── Color Scheme presets ────────────────────────────────────────────────
    property var _colorKeys: [
        { key: "clockHourColor",         default: "#8B5CF6" },
        { key: "clockMinuteColor",       default: "#F97316" },
        { key: "clockSecondColor",       default: "#EC4899" },
        { key: "clockColonColor",        default: "#3B82F6" },
        { key: "dateDayColor",           default: "#06B6D4" },
        { key: "dateMonthColor",         default: "#EC4899" },
        { key: "dateWeekdayColor",       default: "#EAB308" },
        { key: "weatherCityColor",       default: "#EC4899" },
        { key: "weatherWindColor",       default: "#f0f0f0" },
        { key: "weatherHumidityColor",   default: "#f0f0f0" },
        { key: "networkIconColor",       default: "#7C3AED" },
        { key: "networkSsidColor",       default: "#f0f0f0" },
        { key: "networkDownColor",       default: "#f0f0f0" },
        { key: "networkUpColor",         default: "#f0f0f0" },
        { key: "networkGraphStartColor", default: "#7C3AED" },
        { key: "networkGraphEndColor",   default: "#EC4899" },
        { key: "cpuGaugeColor",           default: "#F97316" },
        { key: "memGaugeColor",           default: "#EAB308" },
        { key: "batteryGaugeColor",       default: "#22C55E" },
        { key: "batteryAcGaugeColor",     default: "#22C55E" },
        { key: "tempGaugeColor",          default: "#EF4444" },
        { key: "ringBgColor",             default: "#94A3B8" },
        { key: "storageLabelColor",       default: "#3B82F6" },
        { key: "storageRootColor",        default: "#0EA5E9" },
        { key: "storageHomeColor",        default: "#22C55E" },
        { key: "storageBarSafe",           default: "#22C55E" },
        { key: "storageBarWarn",           default: "#F59E0B" },
        { key: "storageBarDanger",         default: "#EF4444" },
        { key: "hardwareLabelColor",      default: "#D946EF" },
        { key: "hardwareCpuLabelColor",   default: "#14B8A6" },
        { key: "hardwareGpuLabelColor",   default: "#06B6D4" },
        { key: "musicArtistColor",        default: "#EC4899" },
        { key: "musicTitleColor",         default: "#f0f0f0" },
        { key: "musicTimeColor",          default: "#f0f0f0" },
        { key: "musicBorderColor",        default: "#7C3AED" }
    ]

    property var _colorSchemes: [
        {
            name: "Default",
            colors: {
                clockHourColor: "#8B5CF6", clockMinuteColor: "#F97316", clockSecondColor: "#EC4899", clockColonColor: "#3B82F6",
                dateDayColor: "#06B6D4", dateMonthColor: "#EC4899", dateWeekdayColor: "#EAB308",
                weatherCityColor: "#EC4899", weatherWindColor: "#f0f0f0", weatherHumidityColor: "#f0f0f0",
                networkIconColor: "#7C3AED", networkSsidColor: "#A78BFA", networkDownColor: "#f0f0f0", networkUpColor: "#f0f0f0",
                networkGraphStartColor: "#7C3AED", networkGraphEndColor: "#EC4899",
                cpuGaugeColor: "#F97316", memGaugeColor: "#EAB308", batteryGaugeColor: "#22C55E", batteryAcGaugeColor: "#22C55E",
                tempGaugeColor: "#EF4444", ringBgColor: "#94A3B8",
                storageLabelColor: "#3B82F6", storageRootColor: "#0EA5E9", storageHomeColor: "#22C55E", storageBarSafe: "#22C55E", storageBarWarn: "#F59E0B", storageBarDanger: "#EF4444",
                hardwareLabelColor: "#D946EF", hardwareCpuLabelColor: "#14B8A6", hardwareGpuLabelColor: "#06B6D4",
                musicArtistColor: "#EC4899", musicTitleColor: "#f0f0f0", musicTimeColor: "#f0f0f0", musicBorderColor: "#7C3AED"
            }
        },
        {
            name: "Midnight Blue",
            colors: {
                clockHourColor: "#60A5FA", clockMinuteColor: "#818CF8", clockSecondColor: "#A78BFA", clockColonColor: "#34D399",
                dateDayColor: "#34D399", dateMonthColor: "#A78BFA", dateWeekdayColor: "#60A5FA",
                weatherCityColor: "#60A5FA", weatherWindColor: "#94A3B8", weatherHumidityColor: "#94A3B8",
                networkIconColor: "#60A5FA", networkSsidColor: "#60A5FA", networkDownColor: "#34D399", networkUpColor: "#F87171",
                networkGraphStartColor: "#3B82F6", networkGraphEndColor: "#1D4ED8",
                cpuGaugeColor: "#60A5FA", memGaugeColor: "#818CF8", batteryGaugeColor: "#34D399", batteryAcGaugeColor: "#34D399",
                tempGaugeColor: "#F87171", ringBgColor: "#475569",
                storageLabelColor: "#60A5FA", storageRootColor: "#3B82F6", storageHomeColor: "#34D399", storageBarSafe: "#34D399", storageBarWarn: "#818CF8", storageBarDanger: "#F87171",
                hardwareLabelColor: "#A78BFA", hardwareCpuLabelColor: "#34D399", hardwareGpuLabelColor: "#60A5FA",
                musicArtistColor: "#A78BFA", musicTitleColor: "#E2E8F0", musicTimeColor: "#94A3B8", musicBorderColor: "#3B82F6"
            }
        },
        {
            name: "Sunset",
            colors: {
                clockHourColor: "#FDBA74", clockMinuteColor: "#F87171", clockSecondColor: "#F472B6", clockColonColor: "#FBBF24",
                dateDayColor: "#FBBF24", dateMonthColor: "#F472B6", dateWeekdayColor: "#FB923C",
                weatherCityColor: "#F97316", weatherWindColor: "#D1D5DB", weatherHumidityColor: "#D1D5DB",
                networkIconColor: "#F97316", networkSsidColor: "#FDBA74", networkDownColor: "#22C55E", networkUpColor: "#EF4444",
                networkGraphStartColor: "#F97316", networkGraphEndColor: "#7C3AED",
                cpuGaugeColor: "#F97316", memGaugeColor: "#EAB308", batteryGaugeColor: "#22C55E", batteryAcGaugeColor: "#22C55E",
                tempGaugeColor: "#EF4444", ringBgColor: "#A1A1AA",
                storageLabelColor: "#F97316", storageRootColor: "#EA580C", storageHomeColor: "#22C55E", storageBarSafe: "#22C55E", storageBarWarn: "#F97316", storageBarDanger: "#EF4444",
                hardwareLabelColor: "#EC4899", hardwareCpuLabelColor: "#14B8A6", hardwareGpuLabelColor: "#3B82F6",
                musicArtistColor: "#F97316", musicTitleColor: "#F3F4F6", musicTimeColor: "#A1A1AA", musicBorderColor: "#EA580C"
            }
        },
        {
            name: "Forest",
            colors: {
                clockHourColor: "#4ADE80", clockMinuteColor: "#2DD4BF", clockSecondColor: "#34D399", clockColonColor: "#A3E635",
                dateDayColor: "#34D399", dateMonthColor: "#4ADE80", dateWeekdayColor: "#A3E635",
                weatherCityColor: "#4ADE80", weatherWindColor: "#9CA3AF", weatherHumidityColor: "#9CA3AF",
                networkIconColor: "#4ADE80", networkSsidColor: "#86EFAC", networkDownColor: "#2DD4BF", networkUpColor: "#FBBF24",
                networkGraphStartColor: "#22C55E", networkGraphEndColor: "#166534",
                cpuGaugeColor: "#4ADE80", memGaugeColor: "#2DD4BF", batteryGaugeColor: "#22C55E", batteryAcGaugeColor: "#22C55E",
                tempGaugeColor: "#F87171", ringBgColor: "#4B5563",
                storageLabelColor: "#4ADE80", storageRootColor: "#22C55E", storageHomeColor: "#16A34A", storageBarSafe: "#16A34A", storageBarWarn: "#FBBF24", storageBarDanger: "#F87171",
                hardwareLabelColor: "#34D399", hardwareCpuLabelColor: "#A3E635", hardwareGpuLabelColor: "#2DD4BF",
                musicArtistColor: "#4ADE80", musicTitleColor: "#E5E7EB", musicTimeColor: "#9CA3AF", musicBorderColor: "#22C55E"
            }
        },
        {
            name: "Cyberpunk",
            colors: {
                clockHourColor: "#F472B6", clockMinuteColor: "#C084FC", clockSecondColor: "#22D3EE", clockColonColor: "#FB923C",
                dateDayColor: "#22D3EE", dateMonthColor: "#F472B6", dateWeekdayColor: "#C084FC",
                weatherCityColor: "#C084FC", weatherWindColor: "#A1A1AA", weatherHumidityColor: "#A1A1AA",
                networkIconColor: "#C084FC", networkSsidColor: "#E2C8FF", networkDownColor: "#22D3EE", networkUpColor: "#FB923C",
                networkGraphStartColor: "#C084FC", networkGraphEndColor: "#22D3EE",
                cpuGaugeColor: "#F472B6", memGaugeColor: "#C084FC", batteryGaugeColor: "#22D3EE", batteryAcGaugeColor: "#22D3EE",
                tempGaugeColor: "#FB923C", ringBgColor: "#52525B",
                storageLabelColor: "#C084FC", storageRootColor: "#A855F7", storageHomeColor: "#22D3EE", storageBarSafe: "#22D3EE", storageBarWarn: "#C084FC", storageBarDanger: "#FB923C",
                hardwareLabelColor: "#F472B6", hardwareCpuLabelColor: "#22D3EE", hardwareGpuLabelColor: "#C084FC",
                musicArtistColor: "#C084FC", musicTitleColor: "#F4F4F5", musicTimeColor: "#A1A1AA", musicBorderColor: "#C084FC"
            }
        },
        {
            name: "Monochrome",
            colors: {
                clockHourColor: "#E4E4E7", clockMinuteColor: "#D4D4D8", clockSecondColor: "#A1A1AA", clockColonColor: "#F4F4F5",
                dateDayColor: "#A1A1AA", dateMonthColor: "#D4D4D8", dateWeekdayColor: "#D4D4D8",
                weatherCityColor: "#D4D4D8", weatherWindColor: "#71717A", weatherHumidityColor: "#71717A",
                networkIconColor: "#D4D4D8", networkSsidColor: "#D4D4D8", networkDownColor: "#A1A1AA", networkUpColor: "#A1A1AA",
                networkGraphStartColor: "#A1A1AA", networkGraphEndColor: "#52525B",
                cpuGaugeColor: "#D4D4D8", memGaugeColor: "#A1A1AA", batteryGaugeColor: "#A1A1AA", batteryAcGaugeColor: "#A1A1AA",
                tempGaugeColor: "#A1A1AA", ringBgColor: "#3F3F46",
                storageLabelColor: "#D4D4D8", storageRootColor: "#A1A1AA", storageHomeColor: "#A1A1AA", storageBarSafe: "#A1A1AA", storageBarWarn: "#71717A", storageBarDanger: "#3F3F46",
                hardwareLabelColor: "#D4D4D8", hardwareCpuLabelColor: "#A1A1AA", hardwareGpuLabelColor: "#A1A1AA",
                musicArtistColor: "#D4D4D8", musicTitleColor: "#FAFAFA", musicTimeColor: "#71717A", musicBorderColor: "#A1A1AA"
            }
        },
        {
            name: "Nord",
            colors: {
                clockHourColor: "#88C0D0", clockMinuteColor: "#81A1C1", clockSecondColor: "#B48EAD", clockColonColor: "#5E81AC",
                dateDayColor: "#8FBCBB", dateMonthColor: "#B48EAD", dateWeekdayColor: "#81A1C1",
                weatherCityColor: "#88C0D0", weatherWindColor: "#D8DEE9", weatherHumidityColor: "#D8DEE9",
                networkIconColor: "#81A1C1", networkSsidColor: "#D8DEE9", networkDownColor: "#A3BE8C", networkUpColor: "#BF616A",
                networkGraphStartColor: "#5E81AC", networkGraphEndColor: "#81A1C1",
                cpuGaugeColor: "#88C0D0", memGaugeColor: "#81A1C1", batteryGaugeColor: "#A3BE8C", batteryAcGaugeColor: "#A3BE8C",
                tempGaugeColor: "#BF616A", ringBgColor: "#4C566A",
                storageLabelColor: "#88C0D0", storageRootColor: "#5E81AC", storageHomeColor: "#A3BE8C", storageBarSafe: "#A3BE8C", storageBarWarn: "#EBCB8B", storageBarDanger: "#BF616A",
                hardwareLabelColor: "#B48EAD", hardwareCpuLabelColor: "#8FBCBB", hardwareGpuLabelColor: "#88C0D0",
                musicArtistColor: "#B48EAD", musicTitleColor: "#ECEFF4", musicTimeColor: "#D8DEE9", musicBorderColor: "#5E81AC"
            }
        },
        {
            name: "Sakura",
            colors: {
                clockHourColor: "#F9A8D4", clockMinuteColor: "#F472B6", clockSecondColor: "#FB7185", clockColonColor: "#FDA4AF",
                dateDayColor: "#FB7185", dateMonthColor: "#F9A8D4", dateWeekdayColor: "#FDA4AF",
                weatherCityColor: "#F472B6", weatherWindColor: "#E5E7EB", weatherHumidityColor: "#E5E7EB",
                networkIconColor: "#F472B6", networkSsidColor: "#F9A8D4", networkDownColor: "#67E8F9", networkUpColor: "#F87171",
                networkGraphStartColor: "#F472B6", networkGraphEndColor: "#FB7185",
                cpuGaugeColor: "#F9A8D4", memGaugeColor: "#FDA4AF", batteryGaugeColor: "#67E8F9", batteryAcGaugeColor: "#67E8F9",
                tempGaugeColor: "#FB7185", ringBgColor: "#9CA3AF",
                storageLabelColor: "#F472B6", storageRootColor: "#EC4899", storageHomeColor: "#67E8F9", storageBarSafe: "#67E8F9", storageBarWarn: "#FBBF24", storageBarDanger: "#FB7185",
                hardwareLabelColor: "#F9A8D4", hardwareCpuLabelColor: "#67E8F9", hardwareGpuLabelColor: "#F472B6",
                musicArtistColor: "#F472B6", musicTitleColor: "#F9FAFB", musicTimeColor: "#D1D5DB", musicBorderColor: "#F472B6"
            }
        },
        {
            name: "Ocean",
            colors: {
                clockHourColor: "#7DD3FC", clockMinuteColor: "#38BDF8", clockSecondColor: "#0EA5E9", clockColonColor: "#BAE6FD",
                dateDayColor: "#0EA5E9", dateMonthColor: "#7DD3FC", dateWeekdayColor: "#38BDF8",
                weatherCityColor: "#38BDF8", weatherWindColor: "#CBD5E1", weatherHumidityColor: "#CBD5E1",
                networkIconColor: "#38BDF8", networkSsidColor: "#7DD3FC", networkDownColor: "#2DD4BF", networkUpColor: "#FB923C",
                networkGraphStartColor: "#0EA5E9", networkGraphEndColor: "#0369A1",
                cpuGaugeColor: "#7DD3FC", memGaugeColor: "#38BDF8", batteryGaugeColor: "#2DD4BF", batteryAcGaugeColor: "#2DD4BF",
                tempGaugeColor: "#FB923C", ringBgColor: "#64748B",
                storageLabelColor: "#38BDF8", storageRootColor: "#0EA5E9", storageHomeColor: "#2DD4BF", storageBarSafe: "#2DD4BF", storageBarWarn: "#38BDF8", storageBarDanger: "#FB923C",
                hardwareLabelColor: "#7DD3FC", hardwareCpuLabelColor: "#2DD4BF", hardwareGpuLabelColor: "#0EA5E9",
                musicArtistColor: "#38BDF8", musicTitleColor: "#F8FAFC", musicTimeColor: "#CBD5E1", musicBorderColor: "#0EA5E9"
            }
        },
        {
            name: "Dracula",
            colors: {
                clockHourColor: "#BD93F9", clockMinuteColor: "#FF79C6", clockSecondColor: "#50FA7B", clockColonColor: "#FFB86C",
                dateDayColor: "#50FA7B", dateMonthColor: "#FF79C6", dateWeekdayColor: "#BD93F9",
                weatherCityColor: "#FF79C6", weatherWindColor: "#6272A4", weatherHumidityColor: "#6272A4",
                networkIconColor: "#BD93F9", networkSsidColor: "#BD93F9", networkDownColor: "#50FA7B", networkUpColor: "#FF5555",
                networkGraphStartColor: "#BD93F9", networkGraphEndColor: "#FF79C6",
                cpuGaugeColor: "#FF79C6", memGaugeColor: "#BD93F9", batteryGaugeColor: "#50FA7B", batteryAcGaugeColor: "#50FA7B",
                tempGaugeColor: "#FF5555", ringBgColor: "#44475A",
                storageLabelColor: "#BD93F9", storageRootColor: "#FF79C6", storageHomeColor: "#50FA7B", storageBarSafe: "#50FA7B", storageBarWarn: "#FFB86C", storageBarDanger: "#FF5555",
                hardwareLabelColor: "#FF79C6", hardwareCpuLabelColor: "#50FA7B", hardwareGpuLabelColor: "#BD93F9",
                musicArtistColor: "#FF79C6", musicTitleColor: "#F8F8F2", musicTimeColor: "#6272A4", musicBorderColor: "#BD93F9"
            }
        },
        {
            name: "Autumn",
            colors: {
                clockHourColor: "#FDBA74", clockMinuteColor: "#FB923C", clockSecondColor: "#F97316", clockColonColor: "#EA580C",
                dateDayColor: "#EA580C", dateMonthColor: "#FDBA74", dateWeekdayColor: "#F97316",
                weatherCityColor: "#F97316", weatherWindColor: "#D6D3D1", weatherHumidityColor: "#D6D3D1",
                networkIconColor: "#F97316", networkSsidColor: "#FDBA74", networkDownColor: "#A3E635", networkUpColor: "#EF4444",
                networkGraphStartColor: "#EA580C", networkGraphEndColor: "#92400E",
                cpuGaugeColor: "#FB923C", memGaugeColor: "#F97316", batteryGaugeColor: "#A3E635", batteryAcGaugeColor: "#A3E635",
                tempGaugeColor: "#EF4444", ringBgColor: "#78716C",
                storageLabelColor: "#F97316", storageRootColor: "#EA580C", storageHomeColor: "#A3E635", storageBarSafe: "#A3E635", storageBarWarn: "#FBBF24", storageBarDanger: "#EF4444",
                hardwareLabelColor: "#FB923C", hardwareCpuLabelColor: "#A3E635", hardwareGpuLabelColor: "#F97316",
                musicArtistColor: "#F97316", musicTitleColor: "#FAFAF9", musicTimeColor: "#A8A29E", musicBorderColor: "#EA580C"
            }
        },
        {
            name: "Tokyo Night",
            colors: {
                clockHourColor: "#7AA2F7", clockMinuteColor: "#BB9AF7", clockSecondColor: "#F7768E", clockColonColor: "#A9B1D6",
                dateDayColor: "#7DCFFF", dateMonthColor: "#BB9AF7", dateWeekdayColor: "#9ECE6A",
                weatherCityColor: "#7AA2F7", weatherWindColor: "#A9B1D6", weatherHumidityColor: "#A9B1D6",
                networkIconColor: "#7AA2F7", networkSsidColor: "#A9B1D6", networkDownColor: "#9ECE6A", networkUpColor: "#F7768E",
                networkGraphStartColor: "#7AA2F7", networkGraphEndColor: "#BB9AF7",
                cpuGaugeColor: "#7AA2F7", memGaugeColor: "#BB9AF7", batteryGaugeColor: "#9ECE6A", batteryAcGaugeColor: "#9ECE6A",
                tempGaugeColor: "#F7768E", ringBgColor: "#565F89",
                storageLabelColor: "#7AA2F7", storageRootColor: "#7DCFFF", storageHomeColor: "#9ECE6A", storageBarSafe: "#9ECE6A", storageBarWarn: "#E0AF68", storageBarDanger: "#F7768E",
                hardwareLabelColor: "#BB9AF7", hardwareCpuLabelColor: "#9ECE6A", hardwareGpuLabelColor: "#7AA2F7",
                musicArtistColor: "#BB9AF7", musicTitleColor: "#C0CAF5", musicTimeColor: "#A9B1D6", musicBorderColor: "#7AA2F7"
            }
        },
        {
            name: "Catppuccin Mocha",
            colors: {
                clockHourColor: "#F5C2E7", clockMinuteColor: "#CBA6F7", clockSecondColor: "#F38BA8", clockColonColor: "#94E2D5",
                dateDayColor: "#89B4FA", dateMonthColor: "#F5C2E7", dateWeekdayColor: "#F9E2AF",
                weatherCityColor: "#F5C2E7", weatherWindColor: "#BAC2DE", weatherHumidityColor: "#BAC2DE",
                networkIconColor: "#CBA6F7", networkSsidColor: "#CDD6F4", networkDownColor: "#A6E3A1", networkUpColor: "#F38BA8",
                networkGraphStartColor: "#CBA6F7", networkGraphEndColor: "#F5C2E7",
                cpuGaugeColor: "#F5C2E7", memGaugeColor: "#CBA6F7", batteryGaugeColor: "#A6E3A1", batteryAcGaugeColor: "#A6E3A1",
                tempGaugeColor: "#F38BA8", ringBgColor: "#585B70",
                storageLabelColor: "#F5C2E7", storageRootColor: "#89B4FA", storageHomeColor: "#A6E3A1", storageBarSafe: "#A6E3A1", storageBarWarn: "#F9E2AF", storageBarDanger: "#F38BA8",
                hardwareLabelColor: "#CBA6F7", hardwareCpuLabelColor: "#A6E3A1", hardwareGpuLabelColor: "#89B4FA",
                musicArtistColor: "#F5C2E7", musicTitleColor: "#CDD6F4", musicTimeColor: "#BAC2DE", musicBorderColor: "#CBA6F7"
            }
        },
        {
            name: "Rose Pine",
            colors: {
                clockHourColor: "#EBBCBA", clockMinuteColor: "#C4A7E7", clockSecondColor: "#EB6F92", clockColonColor: "#9CCFD8",
                dateDayColor: "#31748F", dateMonthColor: "#C4A7E7", dateWeekdayColor: "#F6C177",
                weatherCityColor: "#EBBCBA", weatherWindColor: "#908CAA", weatherHumidityColor: "#908CAA",
                networkIconColor: "#C4A7E7", networkSsidColor: "#E0DEF4", networkDownColor: "#3E8FB0", networkUpColor: "#EB6F92",
                networkGraphStartColor: "#C4A7E7", networkGraphEndColor: "#EBBCBA",
                cpuGaugeColor: "#EBBCBA", memGaugeColor: "#C4A7E7", batteryGaugeColor: "#3E8FB0", batteryAcGaugeColor: "#3E8FB0",
                tempGaugeColor: "#EB6F92", ringBgColor: "#6E6A86",
                storageLabelColor: "#EBBCBA", storageRootColor: "#31748F", storageHomeColor: "#9CCFD8", storageBarSafe: "#9CCFD8", storageBarWarn: "#F6C177", storageBarDanger: "#EB6F92",
                hardwareLabelColor: "#C4A7E7", hardwareCpuLabelColor: "#9CCFD8", hardwareGpuLabelColor: "#EBBCBA",
                musicArtistColor: "#EBBCBA", musicTitleColor: "#E0DEF4", musicTimeColor: "#908CAA", musicBorderColor: "#C4A7E7"
            }
        },
        {
            name: "Solarized Dark",
            colors: {
                clockHourColor: "#268BD2", clockMinuteColor: "#D33682", clockSecondColor: "#DC322F", clockColonColor: "#859900",
                dateDayColor: "#2AA198", dateMonthColor: "#D33682", dateWeekdayColor: "#B58900",
                weatherCityColor: "#268BD2", weatherWindColor: "#93A1A1", weatherHumidityColor: "#93A1A1",
                networkIconColor: "#268BD2", networkSsidColor: "#839496", networkDownColor: "#859900", networkUpColor: "#DC322F",
                networkGraphStartColor: "#268BD2", networkGraphEndColor: "#D33682",
                cpuGaugeColor: "#268BD2", memGaugeColor: "#D33682", batteryGaugeColor: "#859900", batteryAcGaugeColor: "#859900",
                tempGaugeColor: "#DC322F", ringBgColor: "#586E75",
                storageLabelColor: "#268BD2", storageRootColor: "#2AA198", storageHomeColor: "#859900", storageBarSafe: "#859900", storageBarWarn: "#B58900", storageBarDanger: "#DC322F",
                hardwareLabelColor: "#D33682", hardwareCpuLabelColor: "#859900", hardwareGpuLabelColor: "#268BD2",
                musicArtistColor: "#D33682", musicTitleColor: "#93A1A1", musicTimeColor: "#657B83", musicBorderColor: "#268BD2"
            }
        },
        {
            name: "Gruvbox",
            colors: {
                clockHourColor: "#FABD2F", clockMinuteColor: "#FB4934", clockSecondColor: "#B8BB26", clockColonColor: "#83A598",
                dateDayColor: "#8EC07C", dateMonthColor: "#D3869B", dateWeekdayColor: "#FABD2F",
                weatherCityColor: "#FABD2F", weatherWindColor: "#A89984", weatherHumidityColor: "#A89984",
                networkIconColor: "#83A598", networkSsidColor: "#EBDBB2", networkDownColor: "#B8BB26", networkUpColor: "#FB4934",
                networkGraphStartColor: "#83A598", networkGraphEndColor: "#D3869B",
                cpuGaugeColor: "#FABD2F", memGaugeColor: "#FB4934", batteryGaugeColor: "#B8BB26", batteryAcGaugeColor: "#B8BB26",
                tempGaugeColor: "#FB4934", ringBgColor: "#7C6F64",
                storageLabelColor: "#FABD2F", storageRootColor: "#8EC07C", storageHomeColor: "#B8BB26", storageBarSafe: "#B8BB26", storageBarWarn: "#FABD2F", storageBarDanger: "#FB4934",
                hardwareLabelColor: "#D3869B", hardwareCpuLabelColor: "#8EC07C", hardwareGpuLabelColor: "#83A598",
                musicArtistColor: "#FABD2F", musicTitleColor: "#EBDBB2", musicTimeColor: "#A89984", musicBorderColor: "#83A598"
            }
        },
        {
            name: "One Dark",
            colors: {
                clockHourColor: "#61AFEF", clockMinuteColor: "#C678DD", clockSecondColor: "#E06C75", clockColonColor: "#56B6C2",
                dateDayColor: "#56B6C2", dateMonthColor: "#C678DD", dateWeekdayColor: "#E5C07B",
                weatherCityColor: "#61AFEF", weatherWindColor: "#ABB2BF", weatherHumidityColor: "#ABB2BF",
                networkIconColor: "#61AFEF", networkSsidColor: "#ABB2BF", networkDownColor: "#98C379", networkUpColor: "#E06C75",
                networkGraphStartColor: "#61AFEF", networkGraphEndColor: "#C678DD",
                cpuGaugeColor: "#61AFEF", memGaugeColor: "#C678DD", batteryGaugeColor: "#98C379", batteryAcGaugeColor: "#98C379",
                tempGaugeColor: "#E06C75", ringBgColor: "#5C6370",
                storageLabelColor: "#61AFEF", storageRootColor: "#56B6C2", storageHomeColor: "#98C379", storageBarSafe: "#98C379", storageBarWarn: "#E5C07B", storageBarDanger: "#E06C75",
                hardwareLabelColor: "#C678DD", hardwareCpuLabelColor: "#98C379", hardwareGpuLabelColor: "#61AFEF",
                musicArtistColor: "#C678DD", musicTitleColor: "#ABB2BF", musicTimeColor: "#828997", musicBorderColor: "#61AFEF"
            }
        },
        {
            name: "Everforest",
            colors: {
                clockHourColor: "#A7C080", clockMinuteColor: "#D3C6AA", clockSecondColor: "#E67E80", clockColonColor: "#7FBBB3",
                dateDayColor: "#7FBBB3", dateMonthColor: "#D699B6", dateWeekdayColor: "#D3C6AA",
                weatherCityColor: "#A7C080", weatherWindColor: "#9DA9A0", weatherHumidityColor: "#9DA9A0",
                networkIconColor: "#7FBBB3", networkSsidColor: "#D3C6AA", networkDownColor: "#A7C080", networkUpColor: "#E67E80",
                networkGraphStartColor: "#7FBBB3", networkGraphEndColor: "#D699B6",
                cpuGaugeColor: "#A7C080", memGaugeColor: "#D3C6AA", batteryGaugeColor: "#A7C080", batteryAcGaugeColor: "#A7C080",
                tempGaugeColor: "#E67E80", ringBgColor: "#859289",
                storageLabelColor: "#A7C080", storageRootColor: "#7FBBB3", storageHomeColor: "#A7C080", storageBarSafe: "#A7C080", storageBarWarn: "#D3C6AA", storageBarDanger: "#E67E80",
                hardwareLabelColor: "#D699B6", hardwareCpuLabelColor: "#A7C080", hardwareGpuLabelColor: "#7FBBB3",
                musicArtistColor: "#D699B6", musicTitleColor: "#D3C6AA", musicTimeColor: "#9DA9A0", musicBorderColor: "#7FBBB3"
            }
        },
        {
            name: "Sisyphus",
            colors: {
                clockHourColor: "#D4A017", clockMinuteColor: "#2B6B93", clockSecondColor: "#C84C2C", clockColonColor: "#B8A88A",
                dateDayColor: "#2B6B93", dateMonthColor: "#C84C2C", dateWeekdayColor: "#D4A017",
                weatherCityColor: "#D4A017", weatherWindColor: "#9C8E7B", weatherHumidityColor: "#9C8E7B",
                networkIconColor: "#2B6B93", networkSsidColor: "#E8E0D4", networkDownColor: "#6B8E23", networkUpColor: "#C84C2C",
                networkGraphStartColor: "#2B6B93", networkGraphEndColor: "#D4A017",
                cpuGaugeColor: "#D4A017", memGaugeColor: "#2B6B93", batteryGaugeColor: "#6B8E23", batteryAcGaugeColor: "#6B8E23",
                tempGaugeColor: "#C84C2C", ringBgColor: "#3D352A",
                storageLabelColor: "#D4A017", storageRootColor: "#C84C2C", storageHomeColor: "#6B8E23", storageBarSafe: "#6B8E23", storageBarWarn: "#D4A017", storageBarDanger: "#C84C2C",
                hardwareLabelColor: "#D4A017", hardwareCpuLabelColor: "#6B8E23", hardwareGpuLabelColor: "#2B6B93",
                musicArtistColor: "#D4A017", musicTitleColor: "#E8E0D4", musicTimeColor: "#9C8E7B", musicBorderColor: "#2B6B93"
            }
        }
    ]

    // ── Custom (user-saved) color schemes ────────────────────────────────────
    property var _customColorSchemes: (function() {
        try { return JSON.parse(root.loadValue("_customColorSchemes", "[]")) }
        catch(e) { return [] }
    })()
    property var _allColorSchemes: root._colorSchemes.concat(root._customColorSchemes)
    property bool _isSavingTheme: false
    property string _savingThemeName: ""

    function _persistCustomThemes() {
        root.saveAndPersist("_customColorSchemes", JSON.stringify(root._customColorSchemes))
    }

    function _saveCustomTheme(name) {
        if (!name || name.trim() === "") return
        var colors = root._getCurrentColors()
        var arr = root._customColorSchemes.concat([{ name: name.trim(), colors: colors, custom: true }])
        root._customColorSchemes = arr
        root._persistCustomThemes()
        root._isSavingTheme = false
        root._savingThemeName = ""
        root._schemeFeedback = root._trSchemeSaved
        feedbackTimer.start()
    }

    function _deleteCustomTheme(index) {
        var arr = root._customColorSchemes.slice()
        arr.splice(index, 1)
        root._customColorSchemes = arr
        root._persistCustomThemes()
        root._schemeFeedback = root._trSchemeSaved
        feedbackTimer.start()
    }

    function _getCurrentColors() {
        var result = {}
        for (var i = 0; i < root._colorKeys.length; i++) {
            var k = root._colorKeys[i]
            result[k.key] = root.loadValue(k.key, k.default)
        }
        return result
    }

    function _applyColorScheme(colors) {
        for (var key in colors)
            root.saveAndPersist(key, colors[key])
    }

    function _exportSchemeToFile(decodedPath) {
        var colors = root._getCurrentColors()
        var json = JSON.stringify({ name: "My Scheme", colors: colors })
        var safePath = decodedPath.replace(/"/g, '\\"')
        var safeJson = json.replace(/"/g, '\\"')
        // Use Python to write JSON to file (avoids shell escaping issues)
        var qml = "import Quickshell.Io\nProcess {\n" +
            '  command: ["python3", "-c", "import sys; open(sys.argv[1], \'w\').write(sys.argv[2])",\n' +
            '    "' + safePath + '",\n' +
            '    "' + safeJson + '"]\n' +
            "  running: true\n" +
            "}"
        Qt.createQmlObject(qml, root)
        root._schemeFeedback = "Exported!"
        feedbackTimer.start()
    }

    function _importSchemeFromFile(fileUrl) {
        var safeUrl = fileUrl.replace(/"/g, '\\"')
        // FileView reads the file and parses JSON
        Qt.createQmlObject(
            "import Quickshell.Io\nFileView {\n" +
            "  path: \"" + safeUrl + "\"\n" +
            "  onLoaded: {\n" +
            "    try {\n" +
            "      var data = JSON.parse(text())\n" +
            "      if (data.colors) {\n" +
            "        root._applyColorScheme(data.colors)\n" +
            "        root._schemeFeedback = \"Imported!\"\n" +
            "        feedbackTimer.start()\n" +
            "      }\n" +
            "    } catch(e) {\n" +
            "      console.warn(\"Import error:\", e)\n" +
            "      root._schemeFeedback = \"Import failed\"\n" +
            "    }\n" +
            "    destroy()\n" +
            "  }\n" +
            "  onLoadFailed: {\n" +
            "    console.warn(\"Import failed:\", error)\n" +
            "    root._schemeFeedback = \"Import failed\"\n" +
            "    destroy()\n" +
            "  }\n" +
            "}", root)
    }

    Column {
        width: parent.width
        spacing: 0

        StyledText {
            text: root._trModule
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: moduleCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: moduleCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankToggle {
                    width: parent.width
                    text: root._trClock
                    checked: root.loadValue("showClock", true)
                    onToggled: c => root.saveAndPersist("showClock", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trWeather
                    checked: root.loadValue("showWeather", true)
                    onToggled: c => root.saveAndPersist("showWeather", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trNetwork
                    checked: root.loadValue("showNetwork", true)
                    onToggled: c => root.saveAndPersist("showNetwork", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trMusic
                    checked: root.loadValue("showMusic", true)
                    onToggled: c => root.saveAndPersist("showMusic", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trStorage
                    checked: root.loadValue("showStorage", true)
                    onToggled: c => root.saveAndPersist("showStorage", c)
                }
                DankToggle {
                    width: parent.width
                    text: root._trRotatingAlbum
                    checked: root.loadValue("showRotatingAlbum", true)
                    onToggled: c => root.saveAndPersist("showRotatingAlbum", c)
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        StyledText {
            text: root._trDefaultView
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: defaultViewRow.implicitHeight + Theme.spacingL * 2

            Row {
                id: defaultViewRow
                spacing: 6
                anchors.centerIn: parent
                Repeater {
                    model: [
                        { label: root._trConky, value: "conky" },
                        { label: root._trApps, value: "apps" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: 70; height: 28; radius: 6
                        color: root.loadValue("defaultView", "conky") === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                        StyledText {
                            anchors.centerIn: parent; text: modelData.label; font.pixelSize: 11
                            color: root.loadValue("defaultView", "conky") === modelData.value ? Theme.onPrimary : Theme.surfaceText
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveAndPersist("defaultView", modelData.value)
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        component ColorPicker: Column {
            width: parent.width
            property string title: ""
            property string settingKey: ""
            property string defaultColor: "#7C3AED"
            property bool compact: false

            StyledText {
                text: title
                font.pixelSize: compact ? Theme.fontSizeSmall : Theme.fontSizeMedium
                font.bold: !compact
                color: compact ? Theme.surfaceVariantText : Theme.surfaceText
            }
            Item { width: 1; height: compact ? 2 : Theme.spacingS }

            Flow {
                width: parent.width
                spacing: compact ? 4 : 6
                Repeater {
                    model: ["#5105DB", "#7C3AED", "#8B5CF6", "#A855F7", "#6366F1", "#2563EB", "#3B82F6", "#0891B2", "#06B6D4", "#14B8A6", "#059669", "#10B981", "#22C55E", "#EAB308", "#F59E0B", "#D97706", "#F97316", "#DC2626", "#EF4444", "#DB2777", "#EC4899", "#D946EF", "#ffffff", "#94A3B8", "#64748B", "#334155"]
                    Rectangle {
                        required property var modelData
                        property string c: modelData
                        width: compact ? 22 : 26; height: compact ? 22 : 26; radius: compact ? 11 : 13
                        color: c
                        border.width: root.loadValue(settingKey, defaultColor) === c ? (compact ? 2 : 3) : 0
                        border.color: Theme.surfaceText
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.saveAndPersist(settingKey, parent.c)
                        }
                    }
                }
            }
        }

        // Generic color-row component: label + color picker + custom hex input (auto-wrap)
        component ColorRow: Flow {
            spacing: 2
            property string label: ""
            property string settingKey: ""
            property string defaultColor: "#f0f0f0"

            StyledText {
                text: label
                width: 48
                font.pixelSize: 11; color: Theme.surfaceVariantText
            }
            Repeater {
                model: ["#f0f0f0", "#F43F5E", "#EF4444", "#DC2626", "#F97316", "#EA580C", "#EAB308", "#84CC16", "#22C55E", "#10B981", "#14B8A6", "#06B6D4", "#0EA5E9", "#3B82F6", "#6366F1", "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#94A3B8"]
                Rectangle {
                    required property var modelData
                    property string c: modelData
                    width: 18; height: 18; radius: 9; color: c
                    border.width: root.loadValue(settingKey, defaultColor) === c ? 2 : 0
                    border.color: Theme.surfaceText
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.saveAndPersist(settingKey, parent.c)
                    }
                }
            }

            // Custom color picker button — opens native color dialog
            Rectangle {
                width: 18; height: 18; radius: 9
                border.width: 1
                border.color: Theme.surfaceVariantText
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#FF0000" }
                    GradientStop { position: 0.17; color: "#FFFF00" }
                    GradientStop { position: 0.33; color: "#00FF00" }
                    GradientStop { position: 0.5; color: "#00FFFF" }
                    GradientStop { position: 0.67; color: "#0000FF" }
                    GradientStop { position: 0.83; color: "#FF00FF" }
                    GradientStop { position: 1.0; color: "#FF0000" }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._pickerTargetKey = settingKey
                        colorDialog.selectedColor = root.loadValue(settingKey, defaultColor)
                        colorDialog.open()
                    }
                }
            }
        }

        // ---- Clock / Date Colors ----
        StyledText {
            text: root._trClockColors
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: clockCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: clockCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trHour;    settingKey: "clockHourColor";    defaultColor: "#8B5CF6" }
                ColorRow { label: root._trMinute;  settingKey: "clockMinuteColor";  defaultColor: "#F97316" }
                ColorRow { label: root._trSecond;  settingKey: "clockSecondColor";  defaultColor: "#EC4899" }
                ColorRow { label: root._trColon;   settingKey: "clockColonColor";   defaultColor: "#3B82F6" }
                ColorRow { label: root._trWeekday; settingKey: "dateWeekdayColor";  defaultColor: "#EAB308" }
                ColorRow { label: root._trDay;     settingKey: "dateDayColor";      defaultColor: "#06B6D4" }
                ColorRow { label: root._trMonth;   settingKey: "dateMonthColor";    defaultColor: "#EC4899" }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Weather Colors ----
        StyledText {
            text: root._trWeather
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: weatherCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: weatherCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trCity;      settingKey: "weatherCityColor";     defaultColor: "#EC4899" }
                ColorRow { label: root._trWind;      settingKey: "weatherWindColor";     defaultColor: "#f0f0f0" }
                ColorRow { label: root._trHumidity;  settingKey: "weatherHumidityColor"; defaultColor: "#f0f0f0" }
            }
        }

        // ---- Network Colors ----
        StyledText {
            text: root._trNetwork
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: netCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: netCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trIcon;    settingKey: "networkIconColor";  defaultColor: "#7C3AED" }
                ColorRow { label: root._trNetwork; settingKey: "networkSsidColor"; defaultColor: "#f0f0f0" }
                ColorRow { label: root._trDown;    settingKey: "networkDownColor";  defaultColor: "#f0f0f0" }
                ColorRow { label: root._trUp;      settingKey: "networkUpColor";    defaultColor: "#f0f0f0" }
                ColorRow { label: root._trStart;   settingKey: "networkGraphStartColor"; defaultColor: "#7C3AED" }
                ColorRow { label: root._trEnd;     settingKey: "networkGraphEndColor";   defaultColor: "#EC4899" }
            }
        }

        // ---- Ring Gauge Colors ----
        StyledText {
            text: root._trRingGaugeColors
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: ringCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: ringCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trCPU;     settingKey: "cpuGaugeColor";     defaultColor: "#F97316" }
                ColorRow { label: root._trMemory;  settingKey: "memGaugeColor";     defaultColor: "#EAB308" }
                ColorRow { label: root._trBattery; settingKey: "batteryGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: root._trAC;      settingKey: "batteryAcGaugeColor"; defaultColor: "#22C55E" }
                ColorRow { label: root._trTemp;    settingKey: "tempGaugeColor";    defaultColor: "#EF4444" }
                ColorRow { label: root._trBg;      settingKey: "ringBgColor";       defaultColor: "#94A3B8" }
            }
        }

        // ---- Storage Colors ----
        StyledText {
            text: root._trStorage
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: storageCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: storageCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trStorage;  settingKey: "storageLabelColor"; defaultColor: "#3B82F6" }
                ColorRow { label: root._trRoot;     settingKey: "storageRootColor";   defaultColor: "#0EA5E9" }
                ColorRow { label: root._trHome;     settingKey: "storageHomeColor";   defaultColor: "#22C55E" }
                ColorRow { label: root._trSafe;   settingKey: "storageBarSafe";   defaultColor: "#22C55E" }
                ColorRow { label: root._trWarn;   settingKey: "storageBarWarn";   defaultColor: "#F59E0B" }
                ColorRow { label: root._trDanger; settingKey: "storageBarDanger"; defaultColor: "#EF4444" }
            }
        }

        // ---- Hardware Colors ----
        StyledText {
            text: root._trHardWare
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: hwCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: hwCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trHardWare; settingKey: "hardwareLabelColor";    defaultColor: "#D946EF" }
                ColorRow { label: root._trCPU;       settingKey: "hardwareCpuLabelColor"; defaultColor: "#14B8A6" }
                ColorRow { label: root._trGPU;       settingKey: "hardwareGpuLabelColor"; defaultColor: "#06B6D4" }
            }
        }

        // ---- Music Colors ----
        StyledText {
            text: root._trMusic
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: musicCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: musicCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 2

                ColorRow { label: root._trArtist; settingKey: "musicArtistColor"; defaultColor: "#EC4899" }
                ColorRow { label: root._trTitle;  settingKey: "musicTitleColor";  defaultColor: "#f0f0f0" }
                ColorRow { label: root._trTime;   settingKey: "musicTimeColor";   defaultColor: "#f0f0f0" }
                ColorRow { label: root._trBorder; settingKey: "musicBorderColor"; defaultColor: "#7C3AED" }
            }
        }

        // ---- Color Schemes ----
        StyledText {
            text: root._trColorSchemes
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: schemeCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: schemeCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: 6

                // Preset buttons in a wrapping flow
                Flow {
                    id: presetFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root._allColorSchemes

                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: (schemeCol.width - 12) / 3
                            height: 56

                            Rectangle {
                                id: cardBg
                                width: parent.width
                                height: parent.height
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHigh
                                border.width: 1
                                border.color: Theme.surfaceVariantText

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    // Mini color preview strip
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        Repeater {
                                            model: [
                                                modelData.colors.clockHourColor,
                                                modelData.colors.networkIconColor,
                                                modelData.colors.cpuGaugeColor,
                                                modelData.colors.musicArtistColor
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 10; height: 10; radius: 2
                                                color: modelData
                                            }
                                        }
                                    }

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.name
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root._applyColorScheme(modelData.colors)
                                }
                            }

                            // Delete button for custom themes
                            Rectangle {
                                visible: modelData.custom === true
                                width: 16; height: 16; radius: 8
                                anchors.right: cardBg.right
                                anchors.top: cardBg.top
                                anchors.margins: -4
                                color: "#EF4444"
                                z: 1

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 10
                                    color: "white"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var customIndex = index - root._colorSchemes.length
                                        if (customIndex >= 0)
                                            root._deleteCustomTheme(customIndex)
                                    }
                                }
                            }
                        }
                    }
                }

                // Inline name input for saving a new theme
                Row {
                    width: parent.width
                    spacing: 6
                    visible: root._isSavingTheme

                    Rectangle {
                        width: parent.width - 68
                        height: 28
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.primary
                        clip: true

                        TextInput {
                            id: saveNameField
                            width: parent.width - 8
                            height: parent.height
                            anchors.centerIn: parent
                            text: root._savingThemeName
                            font.pixelSize: 11
                            color: Theme.surfaceText
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: root._savingThemeName = text
                            Keys.onReturnPressed: root._saveCustomTheme(saveNameField.text)
                            Keys.onEscapePressed: { root._isSavingTheme = false; root._savingThemeName = "" }
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: Theme.cornerRadius
                        color: Theme.primary
                        StyledText {
                            anchors.centerIn: parent
                            text: "✓"
                            font.pixelSize: 12
                            font.bold: true
                            color: "white"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._saveCustomTheme(saveNameField.text)
                        }
                    }

                    Rectangle {
                        width: 28; height: 28; radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 12
                            color: Theme.surfaceText
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root._isSavingTheme = false; root._savingThemeName = "" }
                        }
                    }
                }

                // Save Current / Export / Import buttons
                Row {
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 32
                        radius: Theme.cornerRadius
                        color: Theme.primary
                        StyledText {
                            anchors.centerIn: parent
                            text: root._trSaveCurrent
                            font.pixelSize: 11
                            font.bold: true
                            color: "white"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root._isSavingTheme = true
                                root._savingThemeName = ""
                                Qt.callLater(function() { saveNameField.forceActiveFocus() })
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 32
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: root._trExport
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: exportFileDialog.open()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 12) / 3
                        height: 32
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        StyledText {
                            anchors.centerIn: parent
                            text: root._trImport
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: importFileDialog.open()
                        }
                    }
                }

                // Feedback message
                StyledText {
                    text: root._schemeFeedback
                    font.pixelSize: 10
                    color: Theme.primary
                    visible: root._schemeFeedback !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Timer {
                    id: feedbackTimer
                    interval: 3000
                    onTriggered: root._schemeFeedback = ""
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Display ----
        StyledText {
            text: root._trDisplay
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: displayCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: displayCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                StyledText {
                    text: root._trTransparency + ": " + Math.round(root.loadValue("bgOpacity", 0.0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.0; to: 1.0; stepSize: 0.01
                    value: root.loadValue("bgOpacity", 0.0)
                    onValueChanged: root.saveAndPersist("bgOpacity", value)
                }

                StyledText {
                    text: root._trWidgetSize + ": " + root.loadValue("widgetWidth", 298) + " × " + root.loadValue("widgetHeight", 522)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 280; to: 600; stepSize: 10
                    value: root.loadValue("widgetWidth", 298)
                    onValueChanged: root.saveAndPersist("widgetWidth", value)
                }
                Slider {
                    width: parent.width
                    from: 500; to: 1200; stepSize: 10
                    value: root.loadValue("widgetHeight", 522)
                    onValueChanged: root.saveAndPersist("widgetHeight", value)
                }

                StyledText {
                    text: root._trIconSize + ": " + root.loadValue("appSize", 80) + "px"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 48; to: 128; stepSize: 4
                    value: root.loadValue("appSize", 80)
                    onValueChanged: root.saveAndPersist("appSize", value)
                }

                Item { width: 1; height: 4 }

                StyledText {
                    text: root._trMusicPlayer
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                StyledRect {
                    width: parent.width; height: 28; radius: 6
                    color: Theme.withAlpha(Theme.surfaceText, 0.04)
                    border.color: musicPathField.activeFocus ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
                    border.width: 1
                    TextInput {
                        id: musicPathField
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                        text: root.loadValue("musicPlayerPath", "/usr/local/bin/splayer")
                        selectByMouse: true
                        onTextChanged: root.saveAndPersist("musicPlayerPath", text)
                    }
                }
                StyledText {
                    text: root._trGuiHint
                    font.pixelSize: Theme.fontSizeSmall; color: "#3B82F6"
                    wrapMode: Text.Wrap; width: parent.width
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ---- Particles ----
        StyledText {
            text: root._trParticles
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: particleCol.implicitHeight + Theme.spacingL * 2

            Column {
                id: particleCol
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingS

                DankToggle {
                    width: parent.width
                    text: root._trEnable
                    checked: root.loadValue("showLauncherParticles", true)
                    onToggled: c => root.saveAndPersist("showLauncherParticles", c)
                }

                StyledText {
                    text: root._trStyle
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            { label: "●", value: "circles" },
                            { label: "■", value: "squares" },
                            { label: "▲", value: "triangles" },
                            { label: "✦", value: "stars" },
                            { label: "━", value: "lines" }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 36; height: 28; radius: 6
                            color: root.loadValue("particleStyle", "stars") === modelData.value ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.08)
                            StyledText {
                                anchors.centerIn: parent; text: modelData.label; font.pixelSize: 14
                                color: root.loadValue("particleStyle", "stars") === modelData.value ? Theme.onPrimary : Theme.surfaceText
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.saveAndPersist("particleStyle", modelData.value)
                            }
                        }
                    }
                }

                StyledText {
                    text: root._trOpacity + ": " + Math.round(root.loadValue("particleOpacity", 1.0) * 100) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.0; to: 1.0; stepSize: 0.01
                    value: root.loadValue("particleOpacity", 1.0)
                    onValueChanged: root.saveAndPersist("particleOpacity", value)
                }

                StyledText {
                    text: root._trCount + ": " + root.loadValue("particleCount", 150)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 10; to: 300; stepSize: 10
                    value: root.loadValue("particleCount", 150)
                    onValueChanged: root.saveAndPersist("particleCount", value)
                }

                StyledText {
                    text: root._trSize + ": " + root.loadValue("particleSize", 8.0).toFixed(1)
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
                Slider {
                    width: parent.width
                    from: 0.5; to: 8.0; stepSize: 0.5
                    value: root.loadValue("particleSize", 8.0)
                    onValueChanged: root.saveAndPersist("particleSize", value)
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ── Language ──────────────────────────────────────────────────────────
        StyledText {
            text: root._trLanguage
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer
            height: langBtn.height + Theme.spacingL * 2 + 4

            Rectangle {
                id: langBtn
                width: parent.width - Theme.spacingL * 2
                height: 28; radius: 6
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingL
                color: langBtnArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.15) : Theme.withAlpha(Theme.surfaceText, 0.06)
                border.color: langBtnArea.containsMouse ? Theme.primary : Theme.withAlpha(Theme.outline, 0.2); border.width: 1
                property bool langListOpen: false

                Row {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 4
                    StyledText {
                        text: {
                            var cur = root._settingsLang;
                            var m = {"system": root._trSystemDefault, "zh_CN": "中文", "en": "English",
                                "de": "Deutsch", "es": "Español", "fr": "Français",
                                "ja": "日本語", "ko": "한국어", "ru": "Русский", "vi": "Tiếng Việt"};
                            return m[cur] || cur;
                        }
                        font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24; elide: Text.ElideRight
                    }
                    DankIcon {
                        name: langBtn.langListOpen ? "expand_less" : "expand_more"
                        size: 16; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: langBtnArea
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: langBtn.langListOpen = !langBtn.langListOpen
                }
            }

            Rectangle {
                visible: langBtn.langListOpen
                height: Math.min(160, langListView.implicitHeight + 4)
                anchors.bottom: langBtn.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.spacingL * 2
                radius: 6; clip: true
                color: Theme.withAlpha(Theme.surfaceContainer, 0.98)
                border.color: Theme.withAlpha(Theme.outline, 0.15); border.width: 1

                Flickable {
                    anchors.fill: parent; anchors.margins: 2
                    contentHeight: langListView.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    clip: false
                    Column {
                        id: langListView
                        width: parent.width
                        Repeater {
                            model: [
                                { label: root._trSystemDefault, code: "system" },
                                { label: "中文", code: "zh_CN" },
                                { label: "English", code: "en" },
                                { label: "Deutsch", code: "de" },
                                { label: "Español", code: "es" },
                                { label: "Français", code: "fr" },
                                { label: "日本語", code: "ja" },
                                { label: "한국어", code: "ko" },
                                { label: "Русский", code: "ru" },
                                { label: "Tiếng Việt", code: "vi" }
                            ]
                            delegate: Rectangle {
                                width: parent.width; height: 26; radius: 4
                                color: root.loadValue("pluginLanguage", "en") === modelData.code ? Theme.withAlpha(Theme.primary, 0.15) : langItemMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                                }
                                MouseArea {
                                    id: langItemMouse
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.saveAndPersist("pluginLanguage", modelData.code);
                                        root._settingsLang = modelData.code;
                                        langBtn.langListOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spacingM }

        // ── About / GitHub ────────────────────────────────────────────────────
        StyledText {
            text: root._trAbout
            font.pixelSize: Theme.fontSizeMedium
            font.bold: true
            color: Theme.surfaceText
        }
        Item { width: 1; height: Theme.spacingS }

        StyledRect {
            width: parent.width
            height: githubRow.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainer

            Row {
                id: githubRow
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingM

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - githubBtn.width - parent.spacing
                    spacing: 2

                    StyledText {
                        text: "dms-conky"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    StyledText {
                        width: parent.width
                        text: root._trBugRequest
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.Wrap
                    }
                }

                DankButton {
                    id: githubBtn
                    anchors.verticalCenter: parent.verticalCenter
                    text: root._trGitHub
                    iconName: "code"
                    backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                    textColor: Theme.primary
                    onClicked: Qt.openUrlExternally("https://github.com/suruibin/dms-conky")
                }
            }
        }

    }

    ColorDialog {
        id: colorDialog
        title: I18n.tr("Pick a custom color")
        onAccepted: {
            root.saveAndPersist(root._pickerTargetKey, colorDialog.selectedColor)
        }
    }

    // File dialog for export — saves JSON to file
    FileDialog {
        id: exportFileDialog
        title: root._trExport
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: ["Color Scheme (*.json)"]
        onAccepted: {
            var path = decodeURIComponent(selectedFile.toString())
            if (path.startsWith("file://")) path = path.substring(7)
            root._exportSchemeToFile(path)
        }
    }

    // File dialog for import — reads JSON from file (FileView needs file:// URL)
    FileDialog {
        id: importFileDialog
        title: root._trImport
        fileMode: FileDialog.OpenFile
        nameFilters: ["Color Scheme (*.json)"]
        onAccepted: {
            var path = decodeURIComponent(selectedFile.toString())
            root._importSchemeFromFile(path)
        }
    }

    Component.onCompleted: {
        _applySettingsI18n(_settingsLang)
    }
}
