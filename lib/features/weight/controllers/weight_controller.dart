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

      debugPrint('Loading weight entries...');
      _weightEntries = await _weightService.getWeightEntries();
      debugPrint('Loaded ${_weightEntries.length} weight entries');
      
      for (var entry in _weightEntries) {
        debugPrint('Entry: ${entry.weight} kg on ${entry.date}');
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error loading weight entries: $e';
      debugPrint('Error loading weight entries: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToWeightEntries() {
    _weightService.getWeightEntriesStream().listen(
      (entries) {
        debugPrint('Stream update: ${entries.length} weight entries');
        _weightEntries = entries;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Stream error: $error');
        _errorMessage = 'Error listening to weight entries: $error';
        notifyListeners();
      },
    );
  }

  Future<bool> addWeightEntry(double weight) async {
    try {
      _errorMessage = '';
      notifyListeners();

      debugPrint('Adding weight entry: $weight kg');
      final entry = await _weightService.addWeightEntry(weight);
      if (entry != null) {
        debugPrint('Successfully added weight entry: ${entry.id}');
        // Add to the local list immediately for instant UI feedback
        _weightEntries.insert(0, entry); // Add to the beginning since we want newest first
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to add weight entry';
        debugPrint('Failed to add weight entry');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error adding weight entry: $e';
      debugPrint('Error adding weight entry: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWeightEntry(String id, double weight) async {
    try {
      _errorMessage = '';
      notifyListeners();

      debugPrint('Updating weight entry with id: $id, new weight: $weight');
      final entry = await _weightService.updateWeightEntry(id, weight);
      if (entry != null) {
        debugPrint('Successfully updated weight entry');
        // Update the local list immediately
        final index = _weightEntries.indexWhere((e) => e.id == id);
        if (index != -1) {
          _weightEntries[index] = entry;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Failed to update weight entry';
        debugPrint('Failed to update weight entry');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating weight entry: $e';
      debugPrint('Error updating weight entry: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWeightEntry(String id) async {
    try {
      _errorMessage = '';
      notifyListeners();

      debugPrint('Deleting weight entry with id: $id');
      final success = await _weightService.deleteWeightEntry(id);
      if (success) {
        debugPrint('Successfully deleted weight entry');
        // The stream will automatically update the UI, but we can also remove from local list immediately
        _weightEntries.removeWhere((entry) => entry.id == id);
        notifyListeners();
      } else {
        _errorMessage = 'Failed to delete weight entry';
        debugPrint('Failed to delete weight entry');
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error deleting weight entry: $e';
      debugPrint('Error deleting weight entry: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
