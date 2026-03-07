import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../models/classification_result_model.dart';
import '../services/classification_service.dart';

enum ClassificationStatus { idle, loading, success, error }

class ClassificationProvider extends ChangeNotifier {
  final _service = ClassificationService();

  XFile?                  _selectedImage;
  ClassificationResult?  _result;
  ClassificationStatus   _status   = ClassificationStatus.idle;
  String?                _errorKey;

  XFile?                 get selectedImage => _selectedImage;
  ClassificationResult? get result        => _result;
  ClassificationStatus  get status        => _status;
  String?               get errorKey      => _errorKey;
  bool                  get isLoading     => _status == ClassificationStatus.loading;
  bool                  get hasResult     => _result != null;

  /// Stores the image file chosen by the user from the camera or gallery.
  /// Clears any previous result so the UI resets cleanly for a new classification.
  void setImage(XFile image) {
    _selectedImage = image;
    _result        = null;
    _status        = ClassificationStatus.idle;
    _errorKey      = null;
    notifyListeners();
  }

  /// Sends the currently selected image to [ClassificationService] for
  /// analysis and updates the provider state based on the response.
  ///
  /// Sets status to [ClassificationStatus.loading] while the request is
  /// in flight, then transitions to [success] or [error] accordingly.
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

  /// Resets the provider back to its initial state.
  /// Called when the user taps "Classify Another" on the result screen.
  void reset() {
    _selectedImage = null;
    _result        = null;
    _status        = ClassificationStatus.idle;
    _errorKey      = null;
    notifyListeners();
  }

  /// Clears only the error state, keeping the selected image intact
  /// so the user can retry without re-picking the image.
  void clearError() {
    _errorKey = null;
    _status   = ClassificationStatus.idle;
    notifyListeners();
  }

  /// Convenience method to set status to loading and clear stale errors
  /// before each new classification request.
  void _setLoading() {
    _status   = ClassificationStatus.loading;
    _errorKey = null;
    notifyListeners();
  }
}