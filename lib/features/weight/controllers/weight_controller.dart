import 'package:flutter/foundation.dart';
import '../services/weight_service.dart';
import '../models/weight_entry.dart';

class WeightController extends ChangeNotifier {
  final WeightService _weightService = WeightService();

  List<WeightEntry> _weightEntries = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<WeightEntry> get weightEntries => _weightEntries;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  WeightController() {
    _initialize();
  }

  void _initialize() {
    _loadWeightEntries();
    _listenToWeightEntries();
  }

  Future<void> _loadWeightEntries() async {
    try {
      _isLoading = true;
      notifyListeners();

      _weightEntries = await _weightService.getWeightEntries();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading weight entries: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToWeightEntries() {
    _weightService.getWeightEntriesStream().listen((entries) {
      _weightEntries = entries;
      notifyListeners();
    });
  }

  Future<bool> addWeightEntry(double weight) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final entry = await _weightService.addWeightEntry(weight);
      if (entry != null) {
        return true;
      } else {
        _errorMessage = 'Failed to add weight entry';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding weight entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWeightEntry(String id, double weight) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final entry = await _weightService.updateWeightEntry(id, weight);
      if (entry != null) {
        return true;
      } else {
        _errorMessage = 'Failed to update weight entry';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating weight entry: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWeightEntry(String id) async {
    try {
      _errorMessage = '';
      notifyListeners();

      final success = await _weightService.deleteWeightEntry(id);
      if (!success) {
        _errorMessage = 'Failed to delete weight entry';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error deleting weight entry: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
