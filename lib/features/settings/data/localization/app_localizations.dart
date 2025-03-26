import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'translations.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? 
           AppLocalizations(const Locale('en', 'US'));
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      // First try to load from static translations which is guaranteed to work
      _localizedStrings = {};
      
      // Load translations from JSON file if available
      try {
        String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        
        _localizedStrings = jsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
        
        print('Loaded JSON translations for ${locale.languageCode}');
      } catch (e) {
        print('Could not load JSON translations, using static translations: $e');
      }
    } catch (e) {
      print('Error in localization: $e');
    }

    return true;
  }

  // This method will be called from every widget that needs a localized text
  String translate(String key) {
    // First check if we have the key in our loaded translations
    if (_localizedStrings.containsKey(key)) {
      return _localizedStrings[key]!;
    }
    
    // If not found in loaded translations, use the static class
    return Translations.get(key, locale);
  }

  Map<String, String> _loadZhTranslations() {
    return {
      'dashboard': '仪表盘',
      'restaurants': '餐厅',
      'reservations': '预订',
      'users': '用户',
      'analytics': '分析',
      'settings': '设置',
      'language': '语言',
      'dark_mode': '深色模式',
      'notifications': '通知',
      'account': '账户',
      'logout': '退出登录',
      'english': '英语',
      'chinese': '中文',
      'search_restaurants': '搜索餐厅',
      'filter': '筛选',
      'all': '全部',
      'active': '营业中',
      'inactive': '未营业',
      'show_all': '显示全部',
      'show_active_only': '只显示营业中的',
      'add_restaurant': '添加餐厅',
      'edit_restaurant': '编辑餐厅',
      'restaurant_name': '餐厅名称',
      'cuisine': '菜系',
      'address': '地址',
      'phone_number': '电话号码',
      'email': '电子邮件',
      'capacity': '容量',
      'is_active': '是否营业',
      'opening_hours': '营业时间',
      'cancel': '取消',
      'save': '保存',
      'required_field': '必填项',
      'invalid_email': '无效的电子邮件',
      'invalid_number': '无效的数字',
      'overview': '概览',
      'total_reservations': '总预订数',
      'current_occupancy': '当前入住率',
      'today_revenue': '今日收入',
      'active_restaurants': '营业中的餐厅',
      'no_restaurants_found': '未找到餐厅',
      'set_active': '设为营业',
      'set_inactive': '设为未营业',
      'restaurant_status_changed': '餐厅状态已更改',
      'error_updating_restaurant': '更新餐厅时出错',
      'restaurant_availability_system': '餐厅可用性系统',
      'error': '错误',
      'vip_profile': 'VIP 档案',
      'status': '状态',
      'loyalty_points': '忠诚度积分',
      'last_visit': '上次访问',
      'for_you': '为您推荐',
      'preferences': '偏好',
      'favorites': '收藏',
      'no_favorite_restaurants': '暂无收藏餐厅',
      'set_preferences': '设置您的偏好以获取个性化推荐',
      'your_favorites': '您的收藏',
      'based_on_cuisine': '基于您的菜系偏好',
      'highly_rated': '高评分',
      'new_places': '新餐厅',
      'dietary_preferences': '饮食偏好',
      'favorite_cuisines': '喜欢的菜系',
      'seating_preferences': '座位偏好',
      'notification_preferences': '通知偏好',
      'enable_notifications': '启用通知',
      'notification_alerts': '接收通知提醒',
      'low_occupancy_alerts': '低入住率提醒',
      'get_notified_availability': '当餐厅有空位时收到通知',
      'low_occupancy_threshold': '低入住率阈值',
      'proximity_alerts': '邻近提醒',
      'proximity_radius': '邻近半径',
      'reservation_reminders': '预订提醒',
      'on': '开启',
      'off': '关闭',
      'profile_saved': '档案已保存',
      'error_saving_profile': '保存档案时出错',
      'discard_changes': '放弃更改？',
      'unsaved_changes': '您有未保存的更改。确定要放弃它们吗？',
      'discard': '放弃',
      'test_vacancy_notification': '测试空位通知',
      'restaurant_now_available': '餐厅现在可用！',
      'current_wait_time': '当前等待时间',
      'distance': '距离',
      'special': '特价',
      'dismiss': '关闭',
      'reserve_now': '立即预订',
      'error_updating_notification': '更新通知设置时出错',
      'monday': '星期一',
      'tuesday': '星期二',
      'wednesday': '星期三',
      'thursday': '星期四',
      'friday': '星期五',
      'saturday': '星期六',
      'sunday': '星期日',
      'open': '开始',
      'close': '结束',
      'closed': '关闭',
      'vegetarian': '素食主义者',
      'vegan': '严格素食主义者',
      'gluten_free': '无麸质',
      'dairy_free': '无乳制品',
      'nut_free': '无坚果',
      'halal': '清真',
      'kosher': '犹太洁食',
      'pescatarian': '鱼素食主义者',
      'keto': '生酮饮食',
      'paleo': '古饮食',
      'italian': '意大利菜',
      'chinese': '中餐',
      'japanese': '日本料理',
      'mexican': '墨西哥菜',
      'indian': '印度菜',
      'thai': '泰国菜',
      'french': '法国菜',
      'american': '美国菜',
      'mediterranean': '地中海菜',
      'other': '其他',
      'inside': '室内',
      'outside': '室外',
      'bar': '酒吧',
      'private_room': '包间',
      'preferred_location': '偏好位置',
      'preferred_noise_level': '偏好噪音水平',
      'quiet': '安静',
      'moderate': '适中',
      'lively': '热闹',
      'save_notification_settings': '保存通知设置',
      'save_profile': '保存档案',
      'language_changed': '语言已更改为',
      'back': '返回',
      'edit': '编辑',
      'view_details': '查看详情',
      'view_all': '查看全部',
      'new_reservation': '新预订',
      'reservation_number': '预订编号',
      'guests': '客人',
      'pending': '待处理',
      'confirmed': '已确认',
      'cancelled': '已取消',
      'completed': '已完成',
      'no_show': '未到场',
    };
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
// In this case, the localized strings will be gotten in an AppLocalizations object
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Provider for app localizations
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  // This would normally be initialized by the MaterialApp using Localizations.of
  // but since that requires a BuildContext, we're using a default (en)
  return AppLocalizations(const Locale('en', 'US'));
});

// Extension to add the translate method to String
extension TranslateX on String {
  String tr(BuildContext context) {
    return AppLocalizations.of(context).translate(this);
  }
} 