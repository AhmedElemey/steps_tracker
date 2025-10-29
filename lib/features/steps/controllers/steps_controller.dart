import 'package:flutter/foundation.dart';
import '../services/steps_service.dart';
import '../models/steps_entry.dart';

class StepsController extends ChangeNotifier {
  final StepsService _stepsService = StepsService();

  List<StepsEntry> _stepsEntries = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<StepsEntry> get stepsEntries => _stepsEntries;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  StepsController() {
    _initialize();
  }

  void _initialize() {
    _loadStepsEntries();
    _listenToStepsEntries();
  }

  Future<void> _loadStepsEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      _stepsEntries = await _stepsService.getStepsEntries();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading steps entries: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToStepsEntries() {
    _stepsService.getStepsEntriesStream().listen((entries) {
      _stepsEntries = entries;
      notifyListeners();
    });
  }

  Future<bool> addStepsEntry(int steps) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final entry = await _stepsService.addStepsEntry(steps);
      if (entry != null) {
        return true;
      } else {
        _errorMessage = 'Failed to add steps entry';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding steps entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStepsEntry(String id, int steps) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final entry = await _stepsService.updateStepsEntry(id, steps);
      if (entry != null) {
        return true;
      } else {
        _errorMessage = 'Failed to update steps entry';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating steps entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStepsEntry(String id) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final success = await _stepsService.deleteStepsEntry(id);
      if (!success) {
        _errorMessage = 'Failed to delete steps entry';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error deleting steps entry: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
