import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHomePage extends StatefulWidget {
  const ImagePickerHomePage({super.key});

  @override
  State<ImagePickerHomePage> createState() => _ImagePickerHomePageState();
}

class _ImagePickerHomePageState extends State<ImagePickerHomePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  String? _errorMessage;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  Future<void> _recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final LostDataResponse response = await _picker.retrieveLostData();
    if (!mounted || response.isEmpty) {
      return;
    }

    final XFile? recoveredImage = response.files?.firstOrNull;
    setState(() {
      _selectedImage = recoveredImage;
      _errorMessage = response.exception?.message;
    });
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = image;
        _errorMessage = image == null ? '未选择图片。' : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '选择图片失败：$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 图片选择器'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '选择一张系统相册图片，并展示到 Flutter 页面中。',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _ImagePreview(image: _selectedImage),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _isPicking ? null : _pickImage,
                icon: _isPicking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(_isPicking ? '正在打开相册...' : '从相册选择图片'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectedImage == null ? null : _clearImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('清除图片'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final XFile? image;

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 72),
            SizedBox(height: 12),
            Text('还没有选择图片'),
          ],
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: image!.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('图片加载失败'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      },
    );
  }
}
