import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick multiple images from gallery
  static Future<List<File>> pickImagesFromGallery() async {
    try {
      // Check and request permission
      final permission = await _requestGalleryPermission();
      if (!permission) {
        throw Exception('Gallery permission denied');
      }

      // Pick multiple images
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia(
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) {
        return [];
      }

      // Convert XFiles to Files and process them
      List<File> processedImages = [];
      for (XFile xFile in pickedFiles) {
        final File originalFile = File(xFile.path);
        final File processedFile = await _processImage(originalFile);
        processedImages.add(processedFile);
      }

      return processedImages;
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// Pick single image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      // Check and request permission
      final permission = await _requestGalleryPermission();
      if (!permission) {
        throw Exception('Gallery permission denied');
      }

      // Pick single image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      // Process the image
      final File originalFile = File(pickedFile.path);
      final File processedFile = await _processImage(originalFile);

      return processedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Take photo from camera
  static Future<File?> takePhotoFromCamera() async {
    try {
      // Check and request permission
      final permission = await _requestCameraPermission();
      if (!permission) {
        throw Exception('Camera permission denied');
      }

      // Take photo
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      // Process the image
      final File originalFile = File(pickedFile.path);
      final File processedFile = await _processImage(originalFile);

      return processedFile;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Process image: resize and compress
  static Future<File> _processImage(File originalFile) async {
    try {
      // Read original image
      final Uint8List originalBytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image if it's too large (max width/height: 1024px)
      const int maxSize = 1024;
      if (image.width > maxSize || image.height > maxSize) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxSize);
        } else {
          image = img.copyResize(image, height: maxSize);
        }
      }

      // Compress image
      Uint8List compressedBytes;
      final String extension = originalFile.path.toLowerCase();

      if (extension.endsWith('.png')) {
        compressedBytes = Uint8List.fromList(img.encodePng(image, level: 6));
      } else {
        // Default to JPEG compression
        compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 85));
      }

      // Save compressed image to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}';
      final String fileExtension = extension.endsWith('.png') ? '.png' : '.jpg';
      final File compressedFile =
          File('${tempDir.path}/$fileName$fileExtension');

      await compressedFile.writeAsBytes(compressedBytes);

      debugPrint(
          'Image processed: ${originalFile.lengthSync()} bytes -> ${compressedFile.lengthSync()} bytes');

      return compressedFile;
    } catch (e) {
      debugPrint('Error processing image: $e');
      // If processing fails, return original file
      return originalFile;
    }
  }

  /// Request gallery permission
  static Future<bool> _requestGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), use READ_MEDIA_IMAGES
        // For older versions, use READ_EXTERNAL_STORAGE
        final androidInfo = await _getAndroidInfo();
        if (androidInfo >= 33) {
          final status = await Permission.photos.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return true; // For other platforms
    } catch (e) {
      debugPrint('Error requesting gallery permission: $e');
      return false;
    }
  }

  /// Request camera permission
  static Future<bool> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Get Android API level
  static Future<int> _getAndroidInfo() async {
    if (Platform.isAndroid) {
      // This is a simplified version. In a real app, you might want to use
      // device_info_plus package for more accurate version detection
      return 33; // Assume API 33+ for now
    }
    return 0;
  }

  /// Delete temporary image file
  static Future<void> deleteImageFile(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('Deleted image file: ${imageFile.path}');
      }
    } catch (e) {
      debugPrint('Error deleting image file: $e');
    }
  }

  /// Get image file size in MB
  static double getImageSizeInMB(File imageFile) {
    try {
      final int bytes = imageFile.lengthSync();
      return bytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return 0.0;
    }
  }

  /// Check if file is a valid image
  static bool isValidImageFile(File file) {
    final String extension = file.path.toLowerCase();
    return extension.endsWith('.jpg') ||
        extension.endsWith('.jpeg') ||
        extension.endsWith('.png');
  }
}
