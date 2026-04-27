import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'ccws_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(directory.path, 'ccws_photos', fileName);

      // Create directory if it doesn't exist
      await Directory(path.dirname(filePath)).create(recursive: true);

      // Save the image
      final File savedImage = await File(photo.path).copy(filePath);
      return savedImage.path;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  Future<String?> pickPhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'ccws_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(directory.path, 'ccws_photos', fileName);

      // Create directory if it doesn't exist
      await Directory(path.dirname(filePath)).create(recursive: true);

      // Save the image
      final File savedImage = await File(photo.path).copy(filePath);
      return savedImage.path;
    } catch (e) {
      print('Error picking photo: $e');
      return null;
    }
  }

  Future<List<File>> getCCWSPhotos() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final photoDir = Directory(path.join(directory.path, 'ccws_photos'));

      if (!photoDir.existsSync()) {
        return [];
      }

      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.jpg'))
          .toList();

      // Sort by date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      print('Error getting CCWS photos: $e');
      return [];
    }
  }

  Future<bool> deletePhoto(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }
}
