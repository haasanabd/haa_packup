import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/database_helper.dart';
import '../services/file_service.dart';
import '../widgets/video_player_widget.dart';

class MediaListScreen extends StatefulWidget {
  final String type; // 'image' or 'video'
  const MediaListScreen({super.key, required this.type});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  List<Map<String, dynamic>> _mediaList = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    // جلب البيانات من قاعدة البيانات (مسارات فقط)
    final data = await DatabaseHelper.instance.queryAllMedia(widget.type);
    setState(() {
      _mediaList = data;
      _isLoading = false;
    });
  }

  Future<void> _pickMedia() async {
    final XFile? pickedFile = widget.type == 'image' 
      ? await _picker.pickImage(source: ImageSource.gallery)
      : await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      // إظهار مؤشر تحميل أثناء النسخ والضغط
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // الحفظ في المجلد الخاص بالتطبيق (استخدام Isolate وضغط الصور داخلياً)
        final savedFile = await FileService.saveFile(File(pickedFile.path), widget.type);
        
        // حفظ المسار فقط في قاعدة البيانات
        await DatabaseHelper.instance.insertMedia({
          'file_path': savedFile.path,
          'type': widget.type,
          'created_at': DateTime.now().toIso8601String(),
        });
        
        if (mounted) Navigator.pop(context); // إغلاق مؤشر التحميل
        _loadMedia();
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.type == 'image' ? 'الصور المحفوظة' : 'الفيديوهات المحفوظة')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _mediaList.isEmpty 
          ? const Center(child: Text('لا يوجد ملفات حالياً'))
          : ListView.builder(
              itemCount: _mediaList.length,
              padding: const EdgeInsets.all(8),
              // استخدام التحميل الكسول لضمان عدم تحميل كل شيء في الذاكرة دفعة واحدة
              itemBuilder: (context, index) {
                final item = _mediaList[index];
                final filePath = item['file_path'];
                final file = File(filePath);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (widget.type == 'image')
                        // استخدام ResizeImage لتقليل استهلاك الذاكرة (RAM) عند العرض
                        Image.file(
                          file,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth: 800, // تصغير الصورة في الذاكرة لتقليل استهلاك RAM
                          errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.broken_image, size: 50)),
                        )
                      else
                        // مشغل الفيديو المحسن
                        SizedBox(
                          height: 250,
                          child: VideoPlayerWidget(file: file),
                        ),
                      ListTile(
                        title: Text('تاريخ الحفظ: ${item['created_at'].toString().split('T')[0]}'),
                        subtitle: Text(p.basename(filePath), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FileService.deleteFile(filePath);
                            await DatabaseHelper.instance.deleteMedia(item['id']);
                            _loadMedia();
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickMedia,
        child: const Icon(Icons.add),
      ),
    );
  }
}
