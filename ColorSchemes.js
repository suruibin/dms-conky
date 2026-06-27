// Shared color scheme presets used by both ConkySettings and ConkyWidget
// Single source of truth — edit here to add/update presets

.pragma library

var presets = [
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
