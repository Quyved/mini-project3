import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StoredReceipt {
  const StoredReceipt(this.image, this.thumbnail);
  final String image, thumbnail;
}

List<int> _thumbnail(List<int> bytes) {
  final image = img.decodeImage(Uint8List.fromList(bytes));
  if (image == null) {
    throw const FormatException('Ảnh không hợp lệ.');
  }
  final oriented = img.bakeOrientation(image);
  return img.encodeJpg(img.copyResize(oriented, width: 240), quality: 75);
}

class ReceiptStorage {
  Future<StoredReceipt> persist(String source) async {
    final root = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
    );
    await root.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch;
    final image = p.join(
      root.path,
      '$id${p.extension(source).isEmpty ? '.jpg' : p.extension(source)}',
    );
    final thumb = p.join(root.path, '${id}_thumb.jpg');
    try {
      final bytes = await File(source).readAsBytes();
      final small = await compute(_thumbnail, bytes.toList());
      await File(image).writeAsBytes(bytes, flush: true);
      await File(thumb).writeAsBytes(small, flush: true);
      return StoredReceipt(image, thumb);
    } catch (_) {
      await cleanup(StoredReceipt(image, thumb));
      rethrow;
    }
  }

  Future<void> cleanup(StoredReceipt files) async {
    for (final path in [files.image, files.thumbnail]) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } on FileSystemException {
        /* Cache cleanup only. */
      }
    }
  }
}
