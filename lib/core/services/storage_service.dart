import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<String> _upload(Uint8List bytes, String folder, String ext) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '${DateTime.now().millisecondsSinceEpoch}.$ext',
      ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Upload failed with status ${response.statusCode}');
    }
    final body = json.decode(await response.stream.bytesToString());
    return body['secure_url'] as String;
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes) {
    return _upload(bytes, 'users/$uid', 'jpg');
  }

  Future<String> uploadPostImage(String postId, Uint8List bytes) {
    return _upload(bytes, 'posts/$postId', 'jpg');
  }

  Future<String> uploadArScreenshotBytes(String uid, Uint8List bytes) {
    return _upload(bytes, 'users/$uid/ar_screenshots', 'png');
  }
}
