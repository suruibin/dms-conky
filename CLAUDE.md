# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

DMS (DankMaterialShell) 桌面 Conky 插件 — 经典 Conky 风格的系统监控 + 应用启动器，鼠标悬停切换视图。

**路径**: `~/.config/DankMaterialShell/plugins/conky/`
**DMS 系统目录**: `/usr/share/quickshell/dms/`

## 开发命令

```bash
dms restart          # 重启 DMS Shell 加载插件
```

验证流程：删除旧 widget → Settings → Plugins → Scan → Enable Conky → Settings → Desktop Widgets → Add → Conky

## 架构

### 入口与视图切换

`ConkyWidget.qml` 是唯一入口（`plugin.json` 中 `"component": "./ConkyWidget.qml"`），继承 `DesktopPluginComponent`。通过全局 `MouseArea` 的 `containsMouse` 控制两套视图：

- **鼠标在外** → `ConkyContent.qml`（系统监控）
- **鼠标悬停** → `AppLauncherContent.qml`（应用启动器）

`ConkyWidget` 持有所有共享状态（颜色、开关、应用列表、磁盘缓存、音乐状态），子组件通过 `property Item host`（或 `property Item widget`）接收引用。

### 文件职责

| 文件 | 职责 |
|------|------|
| `ConkyWidget.qml` | 主入口：属性、Timer、服务生命周期、工具函数、视图切换 |
| `ConkyContent.qml` | 系统监控：时钟、天气、网络图、环形仪表、存储条、音乐播放器 |
| `AppLauncherContent.qml` | 应用启动器：搜索、Grid/List/Compact 三视图、添加/管理对话框、设置面板、拖拽排序 |
| `AppRowDelegate.qml` | List/Compact 共用行组件（图标 + 名称，点击启动动画） |
| `AppIcon.qml` | 图标 + 错误回退（`imageError` 属性驱动，非命令式赋值） |
| `RingGauge.qml` | Canvas 环形进度（CPU/内存/电池/温度） |
| `NetworkGraph.qml` | Canvas 面积图（网络上下行速率） |
| `ConkySettings.qml` | 插件设置面板：显示开关、颜色选择、背景/尺寸/启动器配置 |

### 关键命名约定

**`widget` 非 `host`**：`AppRowDelegate.qml` 中使用 `property Item widget` 而非 `host`。原因是 `host: host` 会导致 QML 引擎将右侧解析为自身的 `host`（null），所有 `host.xxx` 调用失败。`widget: host` 无歧义。

### 数据流

- **插件持久化数据**: `pluginService.savePluginData(pluginId, key, value)` 写入，`getData(key, default)` / `pluginData.xxx ?? default` 读取
- **设置面板数据**: `root.loadValue(key, default)` / `root.saveValue(key, value)`（PluginSettings 基类方法）
- **应用列表**: `addedApps` 数组，通过 `saveAddedApps()` → `pluginService.savePluginData()` 持久化
- **系统服务**: `DgopService`（CPU/内存/网络/磁盘/温度）、`WeatherService`、`MprisController`（音乐）、`BatteryService`、`DMSNetworkService`

### 服务生命周期

```qml
// ConkyWidget.qml Component.onCompleted
DgopService.addRef(activeModules)   // ["cpu","memory","network","disk","diskmounts","system"]
WeatherService.addRef()
// Component.onDestruction
DgopService.removeRef(activeModules)
WeatherService.removeRef()
```

### 磁盘缓存

磁盘信息每 60 秒刷新一次（`refreshDiskCache()` 遍历 `DgopService.diskMounts`），避免每次渲染都遍历挂载列表。首次加载 1.5 秒后触发初始刷新。

### 鼠标悬停位置

`hoverMouseX/Y` 通过 80ms 节流 Timer 更新（~12Hz），用于计算 Grid/List/Compact 中当前悬停的应用索引（`gridHoveredIndex()` / `listHoveredIndex()` / `compactHoveredIndex()`），驱动高亮卡片。

### 搜索防抖

`AppLauncherContent.qml` 中搜索输入变化触发 150ms 防抖后再更新 `filteredModel`。

## 已知问题

- **List 视图拖拽不工作**：`listWrapper` 上的 Drag 无反应，需排查 `ParentChange` 和事件竞争
- **Compact 视图拖拽未开始**：等 List 成功后同样模式实现
- `dms-common/` 下的 `PluginAbout.qml`、`SectionTitle.qml`、`SettingsCard.qml` 定义了但当前未被任何文件引用
- `feather.ttf` 字体文件存在但未被使用
- `restore.sh` / `restore_backup.sh` 指向空备份，未实际使用

## 管理页拖拽参考

`AppLauncherContent.qml` 中 `manageListView` 的 delegate（`delegateContent` + `gripMouse`）实现了可工作的管理页拖拽排序，可作为修复 List/Compact 视图拖拽的参考。
