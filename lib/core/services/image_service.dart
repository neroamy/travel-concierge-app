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
    debugPrint('🖼️ Starting image picker for multiple images...');

    try {
      // First attempt - let image_picker handle permissions naturally
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      debugPrint('📱 Image picker returned ${pickedFiles.length} files');

      if (pickedFiles.isEmpty) {
        debugPrint('👤 No files selected by user');
        return [];
      }

      // Convert XFiles to Files and process them
      List<File> processedImages = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        debugPrint(
            '🔄 Processing image ${i + 1}/${pickedFiles.length}: ${pickedFiles[i].path}');
        final File originalFile = File(pickedFiles[i].path);
        final File processedFile = await _processImage(originalFile);
        processedImages.add(processedFile);
      }

      debugPrint('✅ Successfully processed ${processedImages.length} images');
      return processedImages;
    } catch (e) {
      debugPrint('❌ Error picking images: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');

      // Return empty list instead of retrying to avoid infinite loops
      return [];
    }
  }

  /// Pick single image from gallery
  static Future<File?> pickImageFromGallery() async {
    debugPrint('🖼️ Starting single image picker...');

    try {
      // Pick single image - let image_picker handle permissions
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('👤 No file selected by user');
        return null;
      }

      debugPrint('🔄 Processing single image: ${pickedFile.path}');

      // Process the image
      final File originalFile = File(pickedFile.path);
      final File processedFile = await _processImage(originalFile);

      debugPrint('✅ Successfully processed single image');
      return processedFile;
    } catch (e) {
      debugPrint('❌ Error picking single image: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
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
        debugPrint('Requesting Android gallery permissions...');

        // Check photos permission first (Android 13+)
        final photosStatus = await Permission.photos.status;
        debugPrint('Photos permission status: $photosStatus');

        if (photosStatus.isDenied) {
          final photosResult = await Permission.photos.request();
          debugPrint('Photos permission request result: $photosResult');
          if (photosResult.isGranted) {
            return true;
          }
        } else if (photosStatus.isGranted) {
          return true;
        }

        // Check storage permission (older Android)
        final storageStatus = await Permission.storage.status;
        debugPrint('Storage permission status: $storageStatus');

        if (storageStatus.isDenied) {
          final storageResult = await Permission.storage.request();
          debugPrint('Storage permission request result: $storageResult');
          return storageResult.isGranted;
        }

        return storageStatus.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return true; // For other platforms
    } catch (e) {
      debugPrint('Error requesting gallery permission: $e');
      // If permission_handler fails, assume permission is granted
      // image_picker will handle the actual permission check
      return true;
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

  /// Debug permission status
  static Future<void> debugPermissionStatus() async {
    try {
      debugPrint('🔍 === PERMISSION DEBUG INFO ===');
      debugPrint('📱 Platform: ${Platform.operatingSystem}');

      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;

        debugPrint('📸 Photos permission: $photosStatus');
        debugPrint('💾 Storage permission: $storageStatus');

        // Check if permission is permanently denied
        final isPhotosRestricted = await Permission.photos.isPermanentlyDenied;
        final isStorageRestricted =
            await Permission.storage.isPermanentlyDenied;
        debugPrint('🚫 Photos permanently denied: $isPhotosRestricted');
        debugPrint('🚫 Storage permanently denied: $isStorageRestricted');
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        debugPrint('📸 Photos permission: $photosStatus');
      }

      debugPrint('🔍 === END PERMISSION DEBUG ===');
    } catch (e) {
      debugPrint('❌ Error debugging permissions: $e');
    }
  }

  /// Simple image picker without explicit permission handling
  static Future<List<File>> pickImagesFromGallerySimple() async {
    debugPrint('🖼️ Starting SIMPLE image picker for multiple images...');

    try {
      // Use the most basic approach - no custom permission handling
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      debugPrint('📱 Simple picker returned ${pickedFiles.length} files');

      if (pickedFiles.isEmpty) {
        debugPrint('👤 No files selected by user');
        return [];
      }

      // Just convert without processing for now to test basic functionality
      List<File> imageFiles = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        debugPrint(
            '📄 Converting file ${i + 1}/${pickedFiles.length}: ${pickedFiles[i].path}');
        imageFiles.add(File(pickedFiles[i].path));
      }

      debugPrint(
          '✅ Simple picker successfully returned ${imageFiles.length} files');
      return imageFiles;
    } catch (e) {
      debugPrint('❌ Simple picker error: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');

      // Print the full stack trace for debugging
      debugPrint('📚 Stack trace: ${StackTrace.current}');

      return [];
    }
  }
}
