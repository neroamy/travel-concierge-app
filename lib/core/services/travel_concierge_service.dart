import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'api_config.dart';
import 'auth_service.dart';

class PlanSummaryModel {
  final String planUuid;
  final String title;
  final String destination;
  final DateTime createdAt;
  final String? imageUrl;
  final Map<String, dynamic> rawData;

  PlanSummaryModel({
    required this.planUuid,
    required this.title,
    required this.destination,
    required this.createdAt,
    this.imageUrl,
    required this.rawData,
  });

  factory PlanSummaryModel.fromJson(Map<String, dynamic> json) {
    return PlanSummaryModel(
      planUuid: json['plan_uuid'],
      title: json['title'] ?? '',
      destination: json['destination'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      imageUrl: json['url_image'], // có thể null
      rawData: json,
    );
  }
}

class TravelConciergeService {
  static final TravelConciergeService _instance =
      TravelConciergeService._internal();
  factory TravelConciergeService() => _instance;
  TravelConciergeService._internal();

  String? _sessionId;
  String? _userId;

  /// Initialize session
  Future<bool> initializeSession() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _userId = 'user_$timestamp';
      _sessionId = 'session_$timestamp';

      final url = ApiConfig.getSessionUrl(_userId!, _sessionId!);
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Session created successfully: $_sessionId');
        return true;
      } else {
        print('Failed to create session: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating session: $e');
      return false;
    }
  }

  /// Send search query to Travel Concierge API
  Stream<SearchResult> searchTravel(String query) async* {
    if (_sessionId == null || _userId == null) {
      yield SearchResult(
        text: 'Session not initialized. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      final payload = MessagePayload(
        sessionId: _sessionId!,
        appName: ApiConfig.appName,
        userId: _userId!,
        newMessage: UserMessage.text(query),
      );

      final url = ApiConfig.getMessageUrl();
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(ApiConfig.sseHeaders);
      request.body = jsonEncode(payload.toJson());

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        yield* _handleSSEResponse(streamedResponse);
      } else {
        yield SearchResult(
          text: 'Server error: ${streamedResponse.statusCode}',
          author: 'system',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      yield SearchResult(
        text: 'Network error: $e',
        author: 'system',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Generate itinerary from AI agent
  Stream<SearchResult> generateItinerary({
    required String destination,
    required String category,
    required int days,
    Map<String, dynamic>? preferences,
  }) async* {
    if (_sessionId == null || _userId == null) {
      yield SearchResult(
        text: 'Session not initialized. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      // Create itinerary request
      final itineraryRequest = ItineraryRequest(
        destination: destination,
        category: category,
        days: days,
        preferences: preferences,
      );

      // Create query message for AI agent
      final query = '''
Please create a detailed ${days}-day itinerary for ${destination} with focus on ${category} activities.
Request details: ${jsonEncode(itineraryRequest.toJson())}
Include specific times, activities, locations, and weather information for each day.
''';

      yield* searchTravel(query);
    } catch (e) {
      yield SearchResult(
        text: 'Error generating itinerary: $e',
        author: 'system',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get activity details from AI agent
  Stream<SearchResult> getActivityDetails({
    required String activityTitle,
    required String location,
    required String time,
  }) async* {
    if (_sessionId == null || _userId == null) {
      yield SearchResult(
        text: 'Session not initialized. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      final query = '''
Please provide detailed information about the activity: ${activityTitle}
Location: ${location}
Scheduled time: ${time}
Include: description, requirements, duration, cost, weather recommendations, and nearby attractions.
''';

      yield* searchTravel(query);
    } catch (e) {
      yield SearchResult(
        text: 'Error getting activity details: $e',
        author: 'system',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get weather information for specific location and time
  Stream<SearchResult> getWeatherInfo({
    required String location,
    required String date,
    required String time,
  }) async* {
    if (_sessionId == null || _userId == null) {
      yield SearchResult(
        text: 'Session not initialized. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      final query = '''
Please provide weather information for:
Location: ${location}
Date: ${date}
Time: ${time}
Include: temperature, conditions, rainfall probability, clothing recommendations, and activity suitability.
''';

      yield* searchTravel(query);
    } catch (e) {
      yield SearchResult(
        text: 'Error getting weather information: $e',
        author: 'system',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Save itinerary to user preferences
  Future<bool> saveItinerary({
    required ItineraryResponse itinerary,
    Map<String, dynamic>? userPreferences,
  }) async {
    if (_sessionId == null || _userId == null) {
      return false;
    }

    try {
      // TODO: Implement actual save to backend
      // For now, we'll simulate a successful save
      print('Saving itinerary for ${itinerary.destination}');
      print('Days: ${itinerary.days.length}');

      // In a real implementation, this would:
      // 1. Send POST request to save endpoint
      // 2. Include user ID, session ID, and itinerary data
      // 3. Handle response and return success/failure

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('Error saving itinerary: $e');
      return false;
    }
  }

  /// Gọi API tạo plan mới cho user
  Future<(bool, String)> createPlan(List<ItineraryDayModel> itinerary) async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || user.id.isEmpty) {
        print(
            '[TravelConciergeService] User not logged in or missing user_uuid');
        return (false, 'User not logged in');
      }
      // Tự động lấy destination từ activity đầu tiên
      String destination = '';
      if (itinerary.isNotEmpty && itinerary[0].activities.isNotEmpty) {
        destination = itinerary[0].activities[0].title;
      }
      final title = 'Trip to $destination';
      final url = '${ApiConfig.baseUrl}/user_manager/plan/${user.id}/create/';
      final planData = {
        'title': title,
        'destination': destination,
        'itinerary': itinerary
            .map((day) => {
                  'day_number': day.dayNumber,
                  'date': day.date.toIso8601String(),
                  'display_date': day.displayDate,
                  'activities': day.activities
                      .map((activity) => {
                            'time_slot': activity.timeSlot,
                            'title': activity.title,
                            'description': activity.description,
                            'weather_icon': activity.weatherIcon,
                            'is_active': activity.isActive,
                          })
                      .toList(),
                })
            .toList(),
        'metadata': {
          'created_at': DateTime.now().toIso8601String(),
          'days_count': itinerary.length,
        },
      };
      print('[TravelConciergeService] Create Plan API call:');
      print('  URL: $url');
      print('  Payload: ${planData.toString()}');
      final response = await http.post(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(planData),
      );
      print('  Status code: ${response.statusCode}');
      print('  Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Unknown error';
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return (true, message);
      } else {
        return (false, message);
      }
    } catch (e) {
      print('[TravelConciergeService] Error creating plan: $e');
      return (false, 'Error: $e');
    }
  }

  /// Gọi API update plan
  Future<(bool, String)> updatePlan(
      String planUuid, List<ItineraryDayModel> itinerary) async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || planUuid.isEmpty) {
        print(
            '[TravelConciergeService] User not logged in hoặc thiếu planUuid');
        return (false, 'User not logged in hoặc thiếu planUuid');
      }
      String destination = '';
      if (itinerary.isNotEmpty && itinerary[0].activities.isNotEmpty) {
        destination = itinerary[0].activities[0].title;
      }
      final title = 'Trip to $destination';
      final url = '${ApiConfig.baseUrl}/user_manager/plan/$planUuid/update/';
      final planData = {
        'title': title,
        'destination': destination,
        'itinerary': itinerary
            .map((day) => {
                  'day_number': day.dayNumber,
                  'date': day.date.toIso8601String(),
                  'display_date': day.displayDate,
                  'activities': day.activities
                      .map((activity) => {
                            'time_slot': activity.timeSlot,
                            'title': activity.title,
                            'description': activity.description,
                            'weather_icon': activity.weatherIcon,
                            'is_active': activity.isActive,
                          })
                      .toList(),
                })
            .toList(),
        'metadata': {
          'created_at': DateTime.now().toIso8601String(),
          'days_count': itinerary.length,
        },
      };
      print('[TravelConciergeService] Update Plan API call:');
      print('  URL: $url');
      print('  Payload: ${planData.toString()}');
      final response = await http.put(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(planData),
      );
      print('  Status code: ${response.statusCode}');
      print('  Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Unknown error';
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return (true, message);
      } else {
        return (false, message);
      }
    } catch (e) {
      print('[TravelConciergeService] Error updating plan: $e');
      return (false, 'Error: $e');
    }
  }

  /// Xóa plan theo planUuid
  Future<bool> deletePlan(String planUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/plan/$planUuid/delete/';
      print('[TravelConciergeService] Delete plan: $url');
      final response =
          await http.delete(Uri.parse(url), headers: ApiConfig.jsonHeaders);
      print('  Status code: ${response.statusCode}');
      print('  Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      print('[TravelConciergeService] Error deletePlan: $e');
      return false;
    }
  }

  /// Handle Server-Sent Events response
  Stream<SearchResult> _handleSSEResponse(
      http.StreamedResponse response) async* {
    final stream = response.stream.transform(utf8.decoder);

    await for (String chunk in stream) {
      final lines = chunk.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        try {
          final jsonString = line.substring(6); // Remove "data: " prefix
          final eventData = jsonDecode(jsonString);
          final event = ApiEvent.fromJson(eventData);

          if (event.hasError) {
            yield SearchResult(
              text: 'Agent Error: ${event.error}',
              author: 'system',
              timestamp: DateTime.now(),
            );
            continue;
          }

          if (event.hasContent) {
            final content = event.content!;
            final textParts = content.getTextParts();
            final functionResponses = content.getFunctionResponses();

            // Debug: Log function responses
            if (functionResponses.isNotEmpty) {
              print('🔧 Found ${functionResponses.length} function responses:');
              for (int i = 0; i < functionResponses.length; i++) {
                final fr = functionResponses[i];
                print('   [$i] Name: ${fr['name']}');
                print('       Response type: ${fr['response'].runtimeType}');
                if (fr['response'] is Map) {
                  print(
                      '       Response keys: ${(fr['response'] as Map).keys.toList()}');
                }
              }
            }

            // Yield text parts as separate results
            for (String text in textParts) {
              if (text.trim().isNotEmpty) {
                yield SearchResult(
                  text: text,
                  author: event.author ?? 'agent',
                  timestamp: DateTime.now(),
                  functionResponses: functionResponses,
                );
              }
            }

            // Handle function responses for rich UI indicators
            for (var functionResponse in functionResponses) {
              final functionName = functionResponse['name'];
              final indicator = _getFunctionIndicator(functionName);
              if (indicator != null) {
                yield SearchResult(
                  text: indicator,
                  author: 'system',
                  timestamp: DateTime.now(),
                  functionResponses: [functionResponse],
                );
              }
            }
          }
        } catch (e) {
          print('Error parsing SSE data: $e');
        }
      }
    }
  }

  /// Get indicator text for function responses
  String? _getFunctionIndicator(String? functionName) {
    switch (functionName) {
      case 'place_agent':
        return '🏝️ Found destination suggestions';
      case 'poi_agent':
        return '📍 Found activities and points of interest';
      case 'flight_search_agent':
        return '✈️ Found flight options';
      case 'hotel_search_agent':
        return '🏨 Found hotel options';
      case 'itinerary_agent':
        return '📅 Generated itinerary';
      case 'weather_agent':
        return '🌤️ Weather information updated';
      default:
        return null;
    }
  }

  /// Get current session info
  Map<String, String?> get sessionInfo => {
        'sessionId': _sessionId,
        'userId': _userId,
      };

  /// Lấy danh sách plan của user
  Future<List<PlanSummaryModel>> getUserPlans(String userUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/plan/$userUuid/list/';
      print('[TravelConciergeService] Get user plans: $url');
      final response =
          await http.get(Uri.parse(url), headers: ApiConfig.jsonHeaders);
      print('  Status code: ${response.statusCode}');
      print('  Response body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((e) => PlanSummaryModel.fromJson(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[TravelConciergeService] Error getUserPlans: $e');
      return [];
    }
  }
}
