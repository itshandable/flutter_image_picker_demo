# UI 更新机制与十万级列表学习笔记

## Flutter UI 更新机制

`setState` 不会直接重绘屏幕。它会同步执行传入的回调，然后把当前 `State` 对应的 `Element` 标记为 dirty。下一帧到来时，Flutter 重新执行这一段子树的 `build` 方法，得到新的 `Widget` 配置。

Flutter 会把新的 `Widget` 配置和已有 `Element` 树做匹配：类型和 key 能匹配时复用原来的 `Element`，只更新配置；匹配不上时才创建或销毁节点。真正负责布局和绘制的是 `RenderObject`，它由 `Element` 维护并在需要时更新。

可以把它记成：

```text
State 变化
 -> setState
 -> Element 标脏
 -> 下一帧 build 生成新 Widget
 -> Element 复用/更新
 -> RenderObject layout/paint
 -> 屏幕更新
```

因此 Flutter 鼓励频繁创建轻量的 `Widget`。`Widget` 只是不可变配置，真正的生命周期和复用主要发生在 `Element` 层。

## ListView.builder 为什么适合大列表

`ListView.builder` 的 `itemBuilder` 只会为当前视口附近的 index 创建行。十万条数据不会一次性变成十万个 Widget/Element/RenderObject，也不会一次性加载十万张图片。

这个 Demo 里做了几件事来保持列表可滚动：

- `itemCount: 100000` 告诉列表总长度，滚动条和最大滚动范围可以正确估算。
- `itemExtent: 92` 固定行高，滚动系统不需要先测量每一行高度。
- 分页接口每次只拉 50 条，`Map<int, FeedItem>` 只缓存已请求的数据。
- 未加载数据先显示骨架屏，占住固定高度，图片延迟返回时不会造成列表跳动。
- 图片使用 `cacheWidth/cacheHeight` 请求缩略图尺寸，避免解码过大的位图。

## 性能观察

快速滑动时建议用 profile 模式观察：

```powershell
E:\env\flutter\bin\flutter.bat run --profile --show-performance-overlay
```

Performance Overlay 里重点看 UI 线程和 Raster 线程。如果柱状图大多低于 16ms，说明接近 60fps；如果长期超过 16ms，就需要检查 build 太重、图片解码太大、同步计算过多或一次性加载数据太多。

也可以打开 DevTools 的 Performance 页面，看每帧耗时、build/layout/paint 事件和内存曲线。

## 本地服务地址

- Web、Windows、macOS、iOS 模拟器：通常使用 `http://localhost:8080`。
- Android 模拟器：使用 `http://10.0.2.2:8080` 访问电脑宿主机。
- Android 真机或 iPhone 真机：手机和电脑需在同一局域网，使用电脑局域网 IP，例如 `http://192.168.1.10:8080`。
