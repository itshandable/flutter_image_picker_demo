# Flutter 图片选择器与十万级列表 Demo

这个项目用于学习 Flutter 的跨端运行、图片选择、UI 更新机制，以及大列表的按需加载和虚拟滚动。

当前 App 包含两个页面：

- 图片选择器 Demo：调用系统相册，选择图片后展示到 Flutter 页面。
- 十万级图片列表 Demo：从本地图片服务器分页拉取数据，用 `ListView.builder` 组成类似聊天列表的图片 + 文本列表。

## 本地图片服务器

服务入口：

```powershell
E:\env\flutter\bin\dart.bat run tool/image_server.dart
```

默认监听：

```text
http://localhost:8080
```

Android 模拟器访问宿主机需要使用：

```text
http://10.0.2.2:8080
```

### 接口定义

分页数据接口：

```text
GET /items?offset=0&limit=50
```

返回示例：

```json
{
  "total": 100000,
  "offset": 0,
  "limit": 50,
  "items": [
    {
      "id": 0,
      "title": "聊天对象 #0",
      "subtitle": "这是一条按需加载的列表消息，图片有随机延迟。",
      "imageUrl": "http://localhost:8080/images/0.png"
    }
  ]
}
```

图片接口：

```text
GET /images/<id>.png
```

图片由服务端动态生成，并模拟 `500-1000ms` 随机返回延迟，用来观察弱网/慢图场景下列表的用户体验。

## 列表实现

十万级列表页面使用 Flutter 官方的 `ListView.builder`：

- `itemCount` 设置为服务端返回的 `total`，当前为 `100000`。
- `itemExtent` 固定每行高度，降低滚动时的布局计算成本。
- `itemBuilder` 只在某一行进入视口附近时才构建该行，不会一次性创建十万行。
- 列表数据按页加载，每页只请求一小批 item。
- 已加载数据放在 `Map<int, FeedItem>` 中，key 是 item id/index。
- 页面最多保留最近若干页数据，避免长时间滑动后内存持续增长。

## 懒加载与 Loading 位

当某一行进入视口但数据还没有返回时，页面不会空白或卡住，而是显示 loading/skeleton 占位：

- 文本区域显示灰色骨架线。
- 图片区域显示固定大小的 loading 占位。
- 如果分页请求失败，该行会显示重试入口。
- 图片接口有随机延迟时，文本行可以先稳定展示，图片位置保持固定，避免布局跳动。

这种方式保证了列表即使在慢图或网络延迟下仍然可用。

## 快速滑动优化

当前已经做的优化：

- 使用 `ListView.builder` 实现虚拟滚动，只构建视口附近行。
- 使用固定 `itemExtent`，减少每帧 layout 成本。
- 使用 `cacheExtent` 预构建屏幕外少量行，让快速滑动更平滑。
- 使用 `ScrollController` 监听滚动位置，提前预取即将进入视口的数据页。
- 使用分页缓存，不一次性拉取十万条数据。
- 限制缓存页数，避免内存随着滑动无限增长。
- 图片使用固定展示尺寸和 `cacheWidth/cacheHeight`，避免列表缩略图解码过大位图。
- 行内图片加载失败时显示错误占位，不影响列表继续滚动。
- App 右上角显示 FPS、UI 耗时、Raster 耗时和 Jank 统计，便于观察快速滑动时是否接近满帧。

## 当前写死参数

列表侧：

```text
pageSize = 50
itemExtent = 92
fallbackTotal = 100000
maxCachedPages = 24
cacheExtent = itemExtent * 12
image cacheWidth/cacheHeight = 128
```

服务端：

```text
port = 8080
totalItems = 100000
maxPageSize = 100
imageSize = 128x128
imageDelay = 500-1000ms
```

FPS 浮层：

```text
sampleWindow = 1s
jankThreshold = 17ms
```

这些参数目前为了学习和观察写死在代码里，后续可以改成配置项或根据设备性能动态调整。

## 运行与观察

启动本地服务：

```powershell
E:\env\flutter\bin\dart.bat run tool/image_server.dart
```

运行 Flutter App：

```powershell
E:\env\flutter\bin\flutter.bat run
```

性能观察建议使用 profile 模式：

```powershell
E:\env\flutter\bin\flutter.bat run --profile --show-performance-overlay
```

也可以使用 Flutter DevTools 的 Performance 页面查看每帧耗时、build/layout/paint 情况和内存曲线。

## 阶段性总结

当前阶段已经完成 Flutter 图片选择器、本地图片服务器、十万级图片列表、按需分页加载、慢图占位展示和应用内 FPS 观察。通过这个 Demo，可以初步理解 Flutter 的 UI 更新机制、`ListView.builder` 的虚拟滚动原理，以及大列表中数据分页、图片加载和性能观察的基本方法。
