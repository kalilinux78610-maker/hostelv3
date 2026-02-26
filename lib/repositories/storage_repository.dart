import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:http/http.dart' as http;

class StorageRepository {
  // TODO: Replace 'YOUR_CLOUD_NAME' with your actual Cloudinary Cloud Name
  // You can find this on your Cloudinary Dashboard
  final String cloudName = 'ddvpybjyu';

  // The preset you created in the Cloudinary settings
  final String uploadPreset = 'RNGPIT';

  Future<String?> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      var bytes = await imageFile.readAsBytes();

      // Compress image before uploading
      try {
        final img = img_pkg.decodeImage(bytes);
        if (img != null) {
          if (img.width > 800 || img.height > 800) {
            final resized = img_pkg.copyResize(img, width: 800);
            bytes = img_pkg.encodeJpg(resized, quality: 70);
          } else {
            bytes = img_pkg.encodeJpg(img, quality: 70);
          }
        }
      } catch (e) {
        debugPrint("Image compression failed (falling back to original): $e");
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] =
            'profile_images' // Optional: puts images in a folder
        ..fields['public_id'] = uid; // Names the file with the user ID

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: '$uid.jpg'),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['secure_url']; // This is the public HTTPS URL
      } else {
        debugPrint('Cloudinary Upload Failed: ${response.statusCode}');
        debugPrint('Response: $responseBody');
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      debugPrint("Storage Upload Error: $e");
      rethrow;
    }
  }
}
