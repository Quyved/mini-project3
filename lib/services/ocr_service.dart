import 'dart:io';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLine {
  const OcrLine(this.text, this.bounds);
  final String text;
  final ui.Rect bounds;
}

class OcrResult {
  const OcrResult({
    required this.text,
    required this.lines,
    required this.size,
    required this.elapsed,
  });
  final String text;
  final List<OcrLine> lines;
  final ui.Size size;
  final Duration elapsed;
}

class OcrService {
  Future<OcrResult> recognize(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      final size = ui.Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      final clock = Stopwatch()..start();
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      clock.stop();
      return OcrResult(
        text: result.text,
        size: size,
        elapsed: clock.elapsed,
        lines: [
          for (final b in result.blocks)
            for (final l in b.lines) OcrLine(l.text, l.boundingBox),
        ],
      );
    } finally {
      await recognizer.close();
    }
  }
}
