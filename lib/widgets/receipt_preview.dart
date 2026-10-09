import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ocr_service.dart';

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    super.key,
    required this.path,
    this.ocr,
    this.showBoxes = true,
  });
  final String path;
  final OcrResult? ocr;
  final bool showBoxes;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 320,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) =>
                  const Center(child: Text('Ảnh hóa đơn không còn tồn tại.')),
            ),
            if (ocr != null && showBoxes)
              IgnorePointer(
                child: CustomPaint(painter: OcrBoundsPainter(ocr!)),
              ),
          ],
        ),
      ),
    ),
  );
}

class OcrBoundsPainter extends CustomPainter {
  OcrBoundsPainter(this.ocr);
  final OcrResult ocr;
  @override
  void paint(Canvas canvas, Size size) {
    final fit = applyBoxFit(BoxFit.contain, ocr.size, size);
    final destination = Alignment.center.inscribe(
      fit.destination,
      Offset.zero & size,
    );
    final scaleX = destination.width / ocr.size.width;
    final scaleY = destination.height / ocr.size.height;
    for (final line in ocr.lines) {
      final r = Rect.fromLTRB(
        destination.left + line.bounds.left * scaleX,
        destination.top + line.bounds.top * scaleY,
        destination.left + line.bounds.right * scaleX,
        destination.top + line.bounds.bottom * scaleY,
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = const Color(0xff159d82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OcrBoundsPainter old) => old.ocr != ocr;
}
