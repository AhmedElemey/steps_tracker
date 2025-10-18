import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  
  Locale _locale = const Locale('en', 'US');
  bool _isRTL = false;

  // Getters
  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  LocalizationService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
      _isRTL = languageCode == 'ar';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      _locale = Locale(languageCode);
      _isRTL = languageCode == 'ar';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'en') {
      setLanguage('ar');
    } else {
      setLanguage('en');
    }
  }

  String getText(String key) {
    final texts = {
      'en': {
        'app_title': 'Steps Tracker',
        'welcome': 'Welcome to Steps Tracker!',
        'get_started': 'Get Started',
        'complete_profile': 'Complete Your Profile',
        'full_name': 'Full Name',
        'weight_kg': 'Weight (kg)',
        'complete_profile_btn': 'Complete Profile',
        'home': 'Home',
        'weight': 'Weight',
        'steps': 'Steps',
        'settings': 'Settings',
        'weight_entries': 'Weight Entries',
        'steps_entries': 'Steps Entries',
        'add_weight_entry': 'Add Weight Entry',
        'edit_weight_entry': 'Edit Weight Entry',
        'delete_weight_entry': 'Delete Weight Entry',
        'no_weight_entries': 'No weight entries yet',
        'no_steps_entries': 'No steps entries yet',
        'daily_goal': 'Daily Goal',
        'target_steps': 'Target Steps',
        'update': 'Update',
        'dark_mode': 'Dark Mode',
        'appearance': 'Appearance',
        'account': 'Account',
        'sign_out': 'Sign Out',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'edit': 'Edit',
        'add': 'Add',
        'name': 'Name',
        'weight_label': 'Weight',
        'steps_count': 'steps',
        'kg': 'kg',
        'enter_name': 'Enter your full name',
        'enter_weight': 'Enter your weight in kilograms',
        'enter_daily_goal': 'Enter daily step goal',
        'please_enter_name': 'Please enter your name',
        'please_enter_weight': 'Please enter your weight',
        'please_enter_valid_weight': 'Please enter a valid weight',
        'goal_updated': 'Goal updated to {steps} steps',
        'weight_entry_added': 'Weight entry added successfully',
        'weight_entry_updated': 'Weight entry updated successfully',
        'weight_entry_deleted': 'Weight entry deleted successfully',
        'profile_created': 'Profile created successfully',
        'sign_out_confirmation': 'Are you sure you want to sign out?',
        'delete_confirmation': 'Are you sure you want to delete this weight entry of {weight} kg?',
        'just_now': 'Just now',
        'minutes_ago': '{minutes}m ago',
        'hours_ago': '{hours}h ago',
        'days_ago': '{days}d ago',
      },
      'ar': {
        'app_title': 'متتبع الخطوات',
        'welcome': 'مرحباً بك في متتبع الخطوات!',
        'get_started': 'ابدأ الآن',
        'complete_profile': 'أكمل ملفك الشخصي',
        'full_name': 'الاسم الكامل',
        'weight_kg': 'الوزن (كيلو)',
        'complete_profile_btn': 'أكمل الملف الشخصي',
        'home': 'الرئيسية',
        'weight': 'الوزن',
        'steps': 'الخطوات',
        'settings': 'الإعدادات',
        'weight_entries': 'سجلات الوزن',
        'steps_entries': 'سجلات الخطوات',
        'add_weight_entry': 'إضافة سجل وزن',
        'edit_weight_entry': 'تعديل سجل الوزن',
        'delete_weight_entry': 'حذف سجل الوزن',
        'no_weight_entries': 'لا توجد سجلات وزن بعد',
        'no_steps_entries': 'لا توجد سجلات خطوات بعد',
        'daily_goal': 'الهدف اليومي',
        'target_steps': 'الخطوات المستهدفة',
        'update': 'تحديث',
        'dark_mode': 'الوضع المظلم',
        'appearance': 'المظهر',
        'account': 'الحساب',
        'sign_out': 'تسجيل الخروج',
        'cancel': 'إلغاء',
        'delete': 'حذف',
        'edit': 'تعديل',
        'add': 'إضافة',
        'name': 'الاسم',
        'weight_label': 'الوزن',
        'steps_count': 'خطوة',
        'kg': 'كيلو',
        'enter_name': 'أدخل اسمك الكامل',
        'enter_weight': 'أدخل وزنك بالكيلو',
        'enter_daily_goal': 'أدخل الهدف اليومي للخطوات',
        'please_enter_name': 'يرجى إدخال اسمك',
        'please_enter_weight': 'يرجى إدخال وزنك',
        'please_enter_valid_weight': 'يرجى إدخال وزن صحيح',
        'goal_updated': 'تم تحديث الهدف إلى {steps} خطوة',
        'weight_entry_added': 'تم إضافة سجل الوزن بنجاح',
        'weight_entry_updated': 'تم تحديث سجل الوزن بنجاح',
        'weight_entry_deleted': 'تم حذف سجل الوزن بنجاح',
        'profile_created': 'تم إنشاء الملف الشخصي بنجاح',
        'sign_out_confirmation': 'هل أنت متأكد من تسجيل الخروج؟',
        'delete_confirmation': 'هل أنت متأكد من حذف سجل الوزن {weight} كيلو؟',
        'just_now': 'الآن',
        'minutes_ago': 'منذ {minutes} دقيقة',
        'hours_ago': 'منذ {hours} ساعة',
        'days_ago': 'منذ {days} يوم',
      },
    };

    return texts[_locale.languageCode]?[key] ?? key;
  }
}
