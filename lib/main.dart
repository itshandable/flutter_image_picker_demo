import 'package:flutter/material.dart';

import 'pages/image_picker_home_page.dart';
import 'pages/large_image_list_page.dart';
import 'widgets/fps_overlay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Picker Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      builder: (BuildContext context, Widget? child) {
        return FpsOverlay(child: child ?? const SizedBox.shrink());
      },
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 学习 Demo'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Text(
                '选择一个学习入口',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _DemoEntryCard(
                title: '图片选择器 Demo',
                subtitle: '拉起系统相册，选择图片并展示到 Flutter 页面。',
                icon: Icons.photo_library_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImagePickerHomePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _DemoEntryCard(
                title: '十万级图片列表 Demo',
                subtitle: '本地服务分页加载图片，观察 ListView.builder 的虚拟滚动。',
                icon: Icons.view_list_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LargeImageListPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const _UiUpdateSummary(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoEntryCard extends StatelessWidget {
  const _DemoEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _UiUpdateSummary extends StatelessWidget {
  const _UiUpdateSummary();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UI 更新机制速记', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'setState 不是直接重绘屏幕，而是告诉框架：这个 State 对应的 Element 脏了。'
              '下一帧 Flutter 会重新执行 build，生成新的 Widget 配置，再复用或更新 Element，最后把变化传递到 RenderObject 完成布局和绘制。',
            ),
            const SizedBox(height: 8),
            const Text(
              'Widget 是不可变配置，Element 是树上位置和生命周期，RenderObject 负责真正的 layout/paint。'
              'ListView.builder 利用这个分层，只构建视口附近的行，所以十万条数据不会一次性进入内存。',
            ),
          ],
        ),
      ),
    );
  }
}
