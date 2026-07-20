import 'dart:io';
import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'Forya_unsigned';
  
  // Create cloudinary instance for potential future use (transformations, etc.)
  late final Cloudinary cloudinary;

  CloudinaryService() {
    cloudinary = CloudinaryObject.fromCloudName(cloudName: _cloudName);
  }

  /// Uploads a single cover photo to Cloudinary
  Future<String?> uploadCyberPhoto(String cyberId, XFile imageFile) async {
    return _uploadImage(imageFile, 'Forya/cybers/$cyberId/cover');
  }

  /// Uploads a single gallery photo to Cloudinary
  Future<String?> uploadGalleryPhoto(String cyberId, XFile imageFile) async {
    return _uploadImage(imageFile, 'Forya/cybers/$cyberId/gallery');
  }

  /// Uploads a room photo to Cloudinary
  Future<String?> uploadRoomPhoto(String roomId, XFile imageFile) async {
    return _uploadImage(imageFile, 'Forya/rooms/$roomId');
  }

  /// Uploads multiple room photos to Cloudinary
  Future<List<String>> uploadRoomPhotos(String roomId, List<XFile> imageFiles) async {
    final List<String> urls = [];
    for (final file in imageFiles) {
      final url = await uploadRoomPhoto(roomId, file);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Uploads multiple gallery photos
  Future<List<String>> uploadGalleryPhotos(String cyberId, List<XFile> imageFiles) async {
    List<String> urls = [];
    for (var file in imageFiles) {
      final url = await uploadGalleryPhoto(cyberId, file);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  Future<String?> _uploadImage(XFile file, String folder) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      
      if (response.statusCode == 200) {
        final jsonMap = json.decode(responseString);
        return jsonMap['secure_url']; // Returns HTTPS URL
      } else {
        debugPrint('Cloudinary Upload Failed: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Exception: $e');
      return null;
    }
  }
}
