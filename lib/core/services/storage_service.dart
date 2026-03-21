import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref('users/$uid/avatar.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadPostImage(String postId, Uint8List bytes) async {
    final ref = _storage.ref('posts/$postId/image.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<String> uploadArScreenshotBytes(String uid, Uint8List bytes) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('users/$uid/ar_screenshots/$ts.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    return ref.getDownloadURL();
  }
}
