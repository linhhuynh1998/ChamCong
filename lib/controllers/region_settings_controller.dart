import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/region_item.dart';
import '../services/region_service.dart';

class RegionSettingsController extends ChangeNotifier {
  RegionSettingsController({
    RegionService? regionService,
    this.regionId,
  })  : _regionService = regionService ?? RegionService(),
        nameController = TextEditingController(),
        noteController = TextEditingController() {
    if (regionId != null && regionId!.isNotEmpty) {
      loadDetail();
    }
  }

  final RegionService _regionService;
  final String? regionId;
  final TextEditingController nameController;
  final TextEditingController noteController;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _lastActionSucceeded = true;
  String _statusMessage = '';

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get lastActionSucceeded => _lastActionSucceeded;
  bool get isEditing => regionId != null && regionId!.isNotEmpty;
  String get statusMessage => _statusMessage;

  Future<void> loadDetail() async {
    final id = regionId;
    if (id == null || id.isEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final region = await _regionService.getRegionDetail(id);
      nameController.text = region.name;
      noteController.text = region.note;
      _lastActionSucceeded = true;
      _statusMessage = 'T?i chi ti?t vùng thành công.';
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
    } catch (_) {
      _lastActionSucceeded = false;
      _statusMessage = 'Không t?i du?c chi ti?t vùng.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> submit() async {
    final name = nameController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty) {
      const message = 'Vui lòng nh?p tên.';
      _lastActionSucceeded = false;
      _statusMessage = message;
      notifyListeners();
      return message;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final message = isEditing
          ? await _regionService.updateRegion(
              id: regionId!,
              name: name,
              note: note,
            )
          : await _regionService.createRegion(
              name: name,
              note: note,
            );
      _lastActionSucceeded = true;
      _statusMessage = message;
      return message;
    } on ApiException catch (error) {
      _lastActionSucceeded = false;
      _statusMessage = error.message;
      return error.message;
    } catch (_) {
      const message = 'Không th? luu vùng. Vui lòng th? l?i.';
      _lastActionSucceeded = false;
      _statusMessage = message;
      return message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
