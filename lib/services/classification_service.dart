import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/constants/api_constants.dart';
import '../core/utils/token_storage.dart';
import '../models/classification_result_model.dart';

class ClassificationService {
  /// Sends the selected palm frond image to the Django classification
  /// endpoint as a multipart/form-data POST request.
  ///
  /// Attaches the stored JWT access token in the Authorization header.
  /// Returns a [ClassificationResult] containing the predicted palm type
  /// and confidence score on success.
  /// Throws a localization key [String] on failure.
  Future<ClassificationResult> classify(XFile imageFile) async {
    // ── OLD MOCK (removed since backend is ready) ──────────────────────
    // await Future.delayed(const Duration(seconds: 2));
    // return ClassificationResult.mock();
    // ── END MOCK ─────────────────────────────────────────────────────────

    // ── REAL implementation ─────────────
    try {
      /// You don't need the access token for this local pyTorch backend
      /// so we can omit adding it to the headers.
      
      /// Build a multipart POST request and attach the image file
      /// under the field name 'image', as expected by the Django endpoint.
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.classify),
      );
      
      final byteData = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        byteData,
        filename: imageFile.name,
      );
      req.files.add(multipartFile);
    
      /// Send the request and stream the response back.
      final streamed = await req.send();
      final res      = await http.Response.fromStream(streamed);
      
      print("===== HTTP Response Code: ${res.statusCode} =====");
      print("===== HTTP Response Body: ${res.body} =====");
      
      final body = jsonDecode(res.body) as Map<String, dynamic>;
    
      /// Parse and return the result if the server responds with HTTP 200.
      if (res.statusCode == 200) {
        return ClassificationResult.fromJson(body);
      }
      
      print("===== Error: Status Code not 200 =====");
      throw 'errorGeneric';
    } catch (e) {
      print("===== Exception in classify(): $e =====");
      if (e is SocketException) {
        throw 'errorNetwork';
      }
      throw 'errorGeneric';
    }
  }
}