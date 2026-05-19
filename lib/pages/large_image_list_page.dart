import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import '../services/feed_api.dart';

class LargeImageListPage extends StatefulWidget {
  const LargeImageListPage({super.key});

  @override
  State<LargeImageListPage> createState() => _LargeImageListPageState();
}

class _LargeImageListPageState extends State<LargeImageListPage> {
  static const int _pageSize = 50;
  static const double _itemExtent = 92;
  static const int _fallbackTotal = 100000;
  static const int _maxCachedPages = 24;

  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _serverController;

  final Map<int, FeedItem> _items = <int, FeedItem>{};
  final Queue<int> _pageAccessOrder = Queue<int>();
  final Set<int> _loadedPages = <int>{};
  final Set<int> _loadingPages = <int>{};
  final Set<int> _failedPages = <int>{};

  late FeedApi _api;
  int _total = _fallbackTotal;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: _defaultServerUrl());
    _api = FeedApi(baseUrl: _serverController.text);
    _scrollController.addListener(_prefetchNearViewport);
    _loadPage(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  String _defaultServerUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  void _applyServerUrl() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _api = FeedApi(baseUrl: _serverController.text.trim());
      _items.clear();
      _pageAccessOrder.clear();
      _loadedPages.clear();
      _loadingPages.clear();
      _failedPages.clear();
      _total = _fallbackTotal;
    });
    _loadPage(0);
  }

  int _pageForIndex(int index) => index ~/ _pageSize;

  void _prefetchNearViewport() {
    if (!_scrollController.hasClients) {
      return;
    }

    final int firstVisible = (_scrollController.offset / _itemExtent)
        .floor()
        .clamp(0, _total - 1);
    final int visibleCount =
        (_scrollController.position.viewportDimension / _itemExtent).ceil();
    final int targetIndex = (firstVisible + visibleCount + _pageSize).clamp(
      0,
      _total - 1,
    );

    _ensurePageForIndex(targetIndex);
  }

  void _ensurePageForIndex(int index) {
    final int page = _pageForIndex(index);
    if (_loadedPages.contains(page) ||
        _loadingPages.contains(page) ||
        _failedPages.contains(page)) {
      return;
    }

    _loadPage(page);
  }

  Future<void> _loadPage(int page) async {
    if (_loadingPages.contains(page)) {
      return;
    }

    setState(() {
      _loadingPages.add(page);
      _failedPages.remove(page);
    });

    try {
      final FeedPage response = await _api.fetchItems(
        offset: page * _pageSize,
        limit: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _total = response.total;
        for (final FeedItem item in response.items) {
          _items[item.id] = item;
        }
        _rememberLoadedPage(page);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _failedPages.add(page);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPages.remove(page);
        });
      }
    }
  }

  void _rememberLoadedPage(int page) {
    _loadedPages.add(page);
    _pageAccessOrder.remove(page);
    _pageAccessOrder.addLast(page);

    while (_pageAccessOrder.length > _maxCachedPages) {
      final int evictedPage = _pageAccessOrder.removeFirst();
      _loadedPages.remove(evictedPage);
      final int start = evictedPage * _pageSize;
      final int end = start + _pageSize;
      _items.removeWhere((int id, FeedItem _) => id >= start && id < end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('十万级图片列表'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _ServerConfigBar(
            controller: _serverController,
            onApply: _applyServerUrl,
          ),
          const _LearningSummaryCard(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _total,
              itemExtent: _itemExtent,
              cacheExtent: _itemExtent * 12,
              itemBuilder: (BuildContext context, int index) {
                final FeedItem? item = _items[index];
                if (item == null) {
                  _ensurePageForIndex(index);
                  return _LoadingFeedRow(
                    index: index,
                    hasFailed: _failedPages.contains(_pageForIndex(index)),
                    onRetry: () => _loadPage(_pageForIndex(index)),
                  );
                }

                return _FeedRow(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerConfigBar extends StatelessWidget {
  const _ServerConfigBar({required this.controller, required this.onApply});

  final TextEditingController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                labelText: '图片服务器地址',
                helperText: 'Android 模拟器默认使用 10.0.2.2 访问电脑本机',
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => onApply(),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onApply, child: const Text('连接')),
        ],
      ),
    );
  }
}

class _LearningSummaryCard extends StatelessWidget {
  const _LearningSummaryCard();

  @override
  Widget build(BuildContext context) {
    final TextStyle? bodySmall = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'UI 更新：setState 标记 Element 为 dirty，下一帧重建 Widget 配置，再复用/更新 Element 和 RenderObject。'
            '列表：ListView.builder 只构建视口附近行，配合 itemExtent、分页缓存和图片占位实现虚拟滚动。'
            '帧率：用 flutter run --profile --show-performance-overlay 或 DevTools Performance 观察快速滑动。',
            style: bodySmall,
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                cacheWidth: 128,
                cacheHeight: 128,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 180),
                      child: child,
                    );
                  }
                  return const _ImagePlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const _ImagePlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const _ImageErrorPlaceholder();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingFeedRow extends StatelessWidget {
  const _LoadingFeedRow({
    required this.index,
    required this.hasFailed,
    required this.onRetry,
  });

  final int index;
  final bool hasFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          hasFailed
              ? const _ImageErrorPlaceholder()
              : const _ImagePlaceholder(),
          const SizedBox(width: 12),
          Expanded(
            child: hasFailed
                ? TextButton(
                    onPressed: onRetry,
                    child: Text('第 $index 行加载失败，点击重试'),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(widthFactor: 0.48, color: colorScheme),
                      const SizedBox(height: 10),
                      _SkeletonLine(widthFactor: 0.78, color: colorScheme),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 64,
        height: 64,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, required this.color});

  final double widthFactor;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const SizedBox(height: 14),
      ),
    );
  }
}
