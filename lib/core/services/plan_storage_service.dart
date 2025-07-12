import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';

class PlanStorageService {
  static const String _keyCurrentPlan = 'current_plan';
  static const String _keySavedPlans = 'saved_plans';
  static const String _keyPlanUuid = 'plan_uuid';

  // Lưu plan hiện tại (auto-save khi vào Plan View), có thể truyền kèm planUuid
  Future<void> saveCurrentPlan(List<ItineraryDayModel> itinerary,
      {String? planUuid}) async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = jsonEncode({
      'itinerary': itinerary.map((e) => _itineraryDayModelToJson(e)).toList(),
      'saved': false,
      'timestamp': DateTime.now().toIso8601String(),
      'plan_uuid': planUuid,
    });
    await prefs.setString(_keyCurrentPlan, planJson);
    if (planUuid != null) {
      await prefs.setString(_keyPlanUuid, planUuid);
    }
  }

  // Lấy plan hiện tại
  Future<List<ItineraryDayModel>?> getCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson == null) return null;
    final data = jsonDecode(planJson);
    if (data['itinerary'] == null) return null;
    return (data['itinerary'] as List)
        .map((e) => _itineraryDayModelFromJson(e))
        .toList();
  }

  // Đánh dấu plan đã lưu vào DB (khi user click Save Plan)
  Future<void> markPlanAsSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson == null) return;
    final data = jsonDecode(planJson);
    data['saved'] = true;
    await prefs.setString(_keyCurrentPlan, jsonEncode(data));
  }

  // Kiểm tra plan đã lưu vào DB chưa
  Future<bool> isPlanSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson == null) return false;
    final data = jsonDecode(planJson);
    return data['saved'] == true;
  }

  // Xóa plan hiện tại (dùng khi logout hoặc đã lưu DB)
  Future<void> clearCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentPlan);
  }

  // Lấy plan_uuid hiện tại
  Future<String?> getPlanUuid() async {
    final prefs = await SharedPreferences.getInstance();
    // Ưu tiên lấy từ key riêng, nếu không có thì lấy từ current_plan
    final planUuid = prefs.getString(_keyPlanUuid);
    if (planUuid != null && planUuid.isNotEmpty) return planUuid;
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson == null) return null;
    final data = jsonDecode(planJson);
    return data['plan_uuid'] as String?;
  }

  // Lưu plan_uuid
  Future<void> setPlanUuid(String planUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlanUuid, planUuid);
    // Cập nhật luôn vào current_plan nếu có
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson != null) {
      final data = jsonDecode(planJson);
      data['plan_uuid'] = planUuid;
      await prefs.setString(_keyCurrentPlan, jsonEncode(data));
    }
  }

  // Xóa plan_uuid
  Future<void> clearPlanUuid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPlanUuid);
    // Xóa luôn trong current_plan nếu có
    final planJson = prefs.getString(_keyCurrentPlan);
    if (planJson != null) {
      final data = jsonDecode(planJson);
      data.remove('plan_uuid');
      await prefs.setString(_keyCurrentPlan, jsonEncode(data));
    }
  }

  // Helper: Convert ItineraryDayModel to JSON
  Map<String, dynamic> _itineraryDayModelToJson(ItineraryDayModel day) {
    return {
      'dayNumber': day.dayNumber,
      'date': day.date.toIso8601String(),
      'displayDate': day.displayDate,
      'activities':
          day.activities.map((a) => _itineraryActivityModelToJson(a)).toList(),
    };
  }

  // Helper: Convert JSON to ItineraryDayModel
  ItineraryDayModel _itineraryDayModelFromJson(Map<String, dynamic> json) {
    return ItineraryDayModel(
      dayNumber: json['dayNumber'],
      date: DateTime.parse(json['date']),
      displayDate: json['displayDate'],
      activities: (json['activities'] as List)
          .map((a) => _itineraryActivityModelFromJson(a))
          .toList(),
    );
  }

  // Helper: Convert ItineraryActivityModel to JSON
  Map<String, dynamic> _itineraryActivityModelToJson(ItineraryActivityModel a) {
    return {
      'timeSlot': a.timeSlot,
      'title': a.title,
      'description': a.description,
      'weatherIcon': a.weatherIcon,
      'isActive': a.isActive,
    };
  }

  // Helper: Convert JSON to ItineraryActivityModel
  ItineraryActivityModel _itineraryActivityModelFromJson(
      Map<String, dynamic> json) {
    return ItineraryActivityModel(
      timeSlot: json['timeSlot'],
      title: json['title'],
      description: json['description'],
      weatherIcon: json['weatherIcon'],
      isActive: json['isActive'] ?? false,
    );
  }
}
