import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload File to Firebase Storage
  Future<String?> uploadFile(File file, String userId) async {
    try {
      String filePath = "uploads/$userId/${DateTime.now().millisecondsSinceEpoch}.pdf";
      TaskSnapshot snapshot = await _storage.ref(filePath).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("File Upload Error: $e");
      return null;
    }
  }

  // Delete File from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (e) {
      print("File Delete Error: $e");
    }
  }
}
