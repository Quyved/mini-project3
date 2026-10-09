import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import 'review_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _error;
  bool _busy = false, _flash = false;
  int _generation = 0;
  Offset? _focus;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Không tìm thấy camera. Có thể chọn ảnh từ thư viện.');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _error = null;
        _flash = false;
      });
    } catch (e) {
      await controller?.dispose();
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'Không mở được camera: $e\nCho phép quyền camera trong Cài đặt hoặc chọn ảnh.',
        );
      }
    }
  }

  Future<void> _release() async {
    ++_generation;
    final c = _camera;
    _camera = null;
    if (mounted) {
      setState(() {});
    }
    await c?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _release();
    }
    if (state == AppLifecycleState.resumed && !_busy) {
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _process({bool gallery = false}) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    String? source, croppedPath;
    try {
      if (gallery) {
        await _release();
        source = (await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 2400,
        ))?.path;
      } else {
        final camera = _camera;
        if (camera == null || !camera.value.isInitialized) {
          return;
        }
        source = (await camera.takePicture()).path;
        await _release();
      }
      if (source == null) {
        return;
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: source,
        maxWidth: 2400,
        maxHeight: 3200,
        compressQuality: 94,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt vùng hóa đơn',
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Cắt vùng hóa đơn'),
        ],
      );
      if (cropped == null || !mounted) {
        return;
      }
      croppedPath = cropped.path;
      final result = await OcrService().recognize(cropped.path);
      if (!mounted) {
        return;
      }
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(imagePath: cropped.path, ocr: result),
        ),
      );
      if (saved == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xử lý ảnh: $e')));
      }
    } finally {
      // Originals are private picker/camera cache copies; persisted files are separate.
      for (final path in {source, croppedPath}.whereType<String>()) {
        try {
          final f = File(path);
          if (await f.exists()) {
            await f.delete();
          }
        } on FileSystemException {
          /* Cache cleanup. */
        }
      }
      if (mounted) {
        setState(() => _busy = false);
        if (_camera == null) {
          _initialize();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: const Color(0xff101c21),
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Bật/tắt flash',
            onPressed: _busy || camera == null
                ? null
                : () async {
                    try {
                      await camera.setFlashMode(
                        _flash ? FlashMode.off : FlashMode.torch,
                      );
                      if (mounted) {
                        setState(() => _flash = !_flash);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Flash không khả dụng: $e')),
                        );
                      }
                    }
                  },
            icon: Icon(
              _flash ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Đặt hóa đơn trong khung • Chạm để lấy nét',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(
              child: _error != null && !_busy
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _initialize,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : camera == null || !camera.value.isInitialized
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _busy
                                ? 'Đang xử lý hóa đơn...'
                                : 'Đang mở camera...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: AspectRatio(
                        aspectRatio: 1 / camera.value.aspectRatio,
                        child: LayoutBuilder(
                          builder: (context, box) => GestureDetector(
                            onTapDown: _busy
                                ? null
                                : (event) async {
                                    final point = Offset(
                                      (event.localPosition.dx / box.maxWidth)
                                          .clamp(0, 1),
                                      (event.localPosition.dy / box.maxHeight)
                                          .clamp(0, 1),
                                    );
                                    try {
                                      await camera.setFocusPoint(point);
                                      await camera.setExposurePoint(point);
                                      if (mounted) {
                                        setState(
                                          () => _focus = event.localPosition,
                                        );
                                      }
                                    } catch (_) {
                                      /* Some devices do not support focus points. */
                                    }
                                  },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(camera),
                                IgnorePointer(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 40,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xff68e0ba),
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_focus != null)
                                  Positioned(
                                    left: _focus!.dx - 20,
                                    top: _focus!.dy - 20,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.amber,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Chọn ảnh',
                    onPressed: _busy ? null : () => _process(gallery: true),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || camera == null
                        ? null
                        : () => _process(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.camera_alt, size: 36),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
