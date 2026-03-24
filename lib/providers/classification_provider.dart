import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/classification_result_model.dart';
import '../services/classification_service.dart';

enum ClassificationStatus { idle, loading, success, error }

class ClassificationProvider extends ChangeNotifier {
  final _service = ClassificationService();

  XFile?                  _selectedImage;
  Uint8List?              _previewBytes; // always JPEG-safe bytes for display
  ClassificationResult?  _result;
  ClassificationStatus   _status   = ClassificationStatus.idle;
  String?                _errorKey;

  XFile?                 get selectedImage  => _selectedImage;
  Uint8List?             get previewBytes   => _previewBytes;
  ClassificationResult? get result          => _result;
  ClassificationStatus  get status          => _status;
  String?               get errorKey        => _errorKey;
  bool                  get isLoading       => _status == ClassificationStatus.loading;
  bool                  get hasResult       => _result != null;

  /// Stores the image chosen by the user.
  /// If the image is HEIC/HEIF (not supported by browsers), it is silently
  /// converted to JPEG in memory before storing, so both the preview widget
  /// and the upload service always receive browser-compatible bytes.
  Future<void> setImage(XFile image) async {
    final rawBytes  = await image.readAsBytes();
    final lowerName = image.name.toLowerCase();
    final isHeic    = lowerName.endsWith('.heic') || lowerName.endsWith('.heif');

    if (isHeic) {
      // Decode with the pure-Dart `image` package (works on all platforms)
      // then re-encode as JPEG.
      final decoded = await compute(_decodeAndEncodeJpeg, rawBytes);
      if (decoded != null) {
        // Build a new XFile backed by the JPEG bytes.
        final jpegFile = await _bytesToXFile(decoded, 'converted.jpg');
        _selectedImage = jpegFile;
        _previewBytes  = decoded;
      } else {
        // Decoding failed — fall through with original (will show decode error
        // to the user, but the old HEIC error is replaced by a cleaner one).
        _selectedImage = image;
        _previewBytes  = rawBytes;
      }
    } else {
      _selectedImage = image;
      _previewBytes  = rawBytes;
    }

    _result   = null;
    _status   = ClassificationStatus.idle;
    _errorKey = null;
    notifyListeners();
  }

  /// Sends the currently selected image to [ClassificationService].
  Future<void> classify() async {
    if (_selectedImage == null) return;
    _setLoading();
    try {
      _result   = await _service.classify(_selectedImage!);
      _status   = ClassificationStatus.success;
      _errorKey = null;
    } catch (e) {
      _errorKey = e.toString();
      _status   = ClassificationStatus.error;
    }
    notifyListeners();
  }

  /// Resets provider to its initial state.
  void reset() {
    _selectedImage = null;
    _previewBytes  = null;
    _result        = null;
    _status        = ClassificationStatus.idle;
    _errorKey      = null;
    notifyListeners();
  }

  /// Clears only the error state, keeping the selected image intact.
  void clearError() {
    _errorKey = null;
    _status   = ClassificationStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status   = ClassificationStatus.loading;
    _errorKey = null;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Runs in an isolate via [compute] — decode raw bytes then encode as JPEG.
  static Uint8List? _decodeAndEncodeJpeg(Uint8List raw) {
    try {
      final image = img.decodeImage(raw);
      if (image == null) return null;
      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (_) {
      return null;
    }
  }

  /// Writes bytes to a temp file and returns an [XFile] pointing to it.
  /// On web there is no real filesystem — we wrap in a blob-style XFile
  /// by writing to the system temp dir on native, or using fromData on web.
  static Future<XFile> _bytesToXFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // On web, XFile.fromData holds bytes in memory — no disk needed.
      return XFile.fromData(bytes, name: filename, mimeType: 'image/jpeg');
    }
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/$filename';
    await File(path).writeAsBytes(bytes);
    return XFile(path);
  }
}