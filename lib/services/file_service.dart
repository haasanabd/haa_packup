import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileService {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'haa_backup');
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// حفظ الملفات باستخدام Isolates والتعامل مع ضغط الصور
  static Future<File> saveFile(File sourceFile, String type) async {
    final folderPath = await _localPath;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = p.basename(sourceFile.path);
    final fileName = '${timestamp}_$originalName';
    final targetPath = p.join(folderPath, fileName);

    if (type == 'image') {
      // ضغط الصور قبل الحفظ (اختياري لكنه يحسن الأداء جداً)
      final compressedFile = await _compressImage(sourceFile.path, targetPath);
      return compressedFile ?? await _copyFileWithIsolate(sourceFile.path, targetPath);
    } else {
      // الفيديوهات الكبيرة يتم نسخها باستخدام Isolate لضمان عدم تعليق الواجهة
      return await _copyFileWithIsolate(sourceFile.path, targetPath);
    }
  }

  /// ضغط الصور لتحسين استهلاك الذاكرة
  static Future<File?> _compressImage(String sourcePath, String targetPath) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 85, // توازن ممتاز بين الجودة والحجم
        format: CompressFormat.jpeg,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Compression error: $e');
      return null;
    }
  }

  /// نسخ الملف في Isolate منفصل
  static Future<File> _copyFileWithIsolate(String source, String destination) async {
    return await compute(_copyFileTask, _CopyParams(source, destination));
  }

  static Future<File> _copyFileTask(_CopyParams params) async {
    final source = File(params.source);
    // استخدام Stream للتعامل مع الملفات الكبيرة جداً لتقليل استهلاك الذاكرة المؤقتة (RAM)
    final raf = await File(params.destination).open(mode: FileMode.write);
    await source.openRead().forEach((chunk) async {
      await raf.writeFrom(chunk);
    });
    await raf.close();
    return File(params.destination);
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class _CopyParams {
  final String source;
  final String destination;
  _CopyParams(this.source, this.destination);
}
