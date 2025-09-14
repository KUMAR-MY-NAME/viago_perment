import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadVoiceNote(String filePath, String parcelId) async {
    final file = File(filePath);
    final fileName = '${_uuid.v4()}.aac'; // flutter_sound records in aac
    final ref = _storage.ref('voice_notes/$parcelId/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => null);
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }
}
