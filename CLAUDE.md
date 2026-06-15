# CLAUDE.md

DMS Conky 桌面插件 — 系统监控 + 应用启动器，鼠标悬停切换视图。

## 路径

- 源码: `~/.config/DankMaterialShell/plugins/conky/`
- DMS 系统: `/usr/share/quickshell/dms/`

## 命令

```bash
dms restart    # 重启加载
```

## Token 节省规则（严格执行）

### 搜索

- grep/搜索限定在当前目录，禁止全局搜系统目录
- QML 加 `--include='*.qml'`，JS 加 `--include='*.js'`
- 先 glob 定位文件，再搜内容

### 读取

- 先 grep 定位行号，用 `read offset` 按需读，**不要 read 整个大文件**
- 读目录结构用 `read`（默认），不要 `ls -la`（输出多 3 倍）

### 命令

- 高输出命令必须加 `head -n 30` 截断：`ps aux`、`find`、系统遍历类
- 避免无输出限制的 `ls -la`、`ps aux`、`find /` 等
- 目录列表用 `ls` 不用 `ls -la`（省掉权限/大小/时间列）

### 工具优先级

```
glob 查路径（0 输出） > grep 限目录搜内容 > read offset 按需读 > edit 精确改
```

## 架构

`ConkyWidget.qml` 入口 → 两组视图：
- 鼠标在外 → `ConkyContent.qml`（系统监控）
- 鼠标悬停 → `AppLauncherContent.qml`（应用启动器）

`ConkyWidget` 持有所有共享状态，子组件通过 `property Item host` 接收引用。

### 文件职责

| 文件 | 职责 |
|------|------|
| `ConkyWidget.qml` | 入口：属性、Timer、服务生命周期 |
| `ConkyContent.qml` | 监控：时钟/天气/网络/仪表/存储/音乐 |
| `AppLauncherContent.qml` | 启动器：Grid/List/Compact 三视图 + 管理/设置/拖拽 |
| `AppRowDelegate.qml` | List/Compact 共用行（图标+名称，点击动画） |
| `AppIcon.qml` | 图标 + 错误回退 |
| `RingGauge.qml` | Canvas 环形进度（CPU/内存/电池/温度） |
| `NetworkGraph.qml` | Canvas 面积图（网络上下行） |
| `ConkySettings.qml` | 设置面板 |

### 关键约定

`AppRowDelegate` 用 `property Item widget` 而非 `host`。`host: host` 会解析到自身的 `host`（null）。

### 数据流

- **持久化数据**: `pluginService.savePluginData(id, key, val)` / `getData(key, default)`
- **设置面板**: `root.loadValue(key, default)` / `root.saveValue(key, val)`
- **服务**: `DgopService`(CPU/内存/网络/磁盘/温度)、`WeatherService`、`MprisController`、`BatteryService`

### 服务生命周期

```qml
Component.onCompleted:
  DgopService.addRef(["cpu","memory","network","disk","diskmounts","system"])
  WeatherService.addRef()
Component.onDestruction:
  DgopService.removeRef(activeModules)
  WeatherService.removeRef()
```

### 已知问题

- 多处英文硬编码未走 I18n（Storage/HardWare/Playing/Root/Home/CPU/GPU/Down/Up/Wind/Humidity/Offline/Network/Detecting...）
- `Math.max.apply(null, rx)` → 可用 `Math.max(...rx)`
