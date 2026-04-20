import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static Future<String> createBackup() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'haa_backup'));
    final dbPath = await getDatabasesPath();
    final dbFile = File(p.join(dbPath, 'haa_backup.db'));

    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final encoder = ZipFileEncoder();
    final backupFileName = 'haa_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    
    // حفظ في مجلد التحميلات أو المستندات المتاح خارجياً (للتبسيط سنضعه في المجلد المؤقت ثم يطلب من المستخدم حفظه)
    final tempDir = await getTemporaryDirectory();
    final backupPath = p.join(tempDir.path, backupFileName);
    
    encoder.create(backupPath);
    
    // إضافة قاعدة البيانات
    if (await dbFile.exists()) {
      encoder.addFile(dbFile);
    }
    
    // إضافة مجلد الوسائط
    if (await mediaDir.exists()) {
      encoder.addDirectory(mediaDir);
    }
    
    encoder.close();
    return backupPath;
  }

  static Future<bool> restoreBackup(String zipPath) async {
    try {
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          
          if (filename.endsWith('.db')) {
            // استعادة قاعدة البيانات
            File(p.join(dbPath, 'haa_backup.db'))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            // استعادة ملفات الوسائط (الحفاظ على هيكل المجلد)
            File(p.join(appDir.path, filename))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        } else {
          Directory(p.join(appDir.path, filename)).createSync(recursive: true);
        }
      }
      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
}
