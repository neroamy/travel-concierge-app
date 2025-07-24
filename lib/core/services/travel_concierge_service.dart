import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'api_config.dart';
import 'auth_service.dart';
import '../utils/logger.dart';

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
        await Logger.log('Session created successfully: $_sessionId');
        return true;
      } else {
        await Logger.log('Failed to create session: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      await Logger.log('Error creating session: $e');
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
      await Logger.log('Saving itinerary for ${itinerary.destination}');
      await Logger.log('Days: ${itinerary.days.length}');

      // In a real implementation, this would:
      // 1. Send POST request to save endpoint
      // 2. Include user ID, session ID, and itinerary data
      // 3. Handle response and return success/failure

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      await Logger.log('Error saving itinerary: $e');
      return false;
    }
  }

  /// Gọi API tạo plan mới cho user
  Future<(bool, String)> createPlan(List<ItineraryDayModel> itinerary) async {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user == null || user.id.isEmpty) {
        await Logger.log(
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
      await Logger.log('[TravelConciergeService] Create Plan API call:');
      await Logger.log('  URL: $url');
      await Logger.log('  Payload: ${planData.toString()}');
      final response = await http.post(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(planData),
      );
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Unknown error';
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return (true, message);
      } else {
        return (false, message);
      }
    } catch (e) {
      await Logger.log('[TravelConciergeService] Error creating plan: $e');
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
        await Logger.log(
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
      await Logger.log('[TravelConciergeService] Update Plan API call:');
      await Logger.log('  URL: $url');
      await Logger.log('  Payload: ${planData.toString()}');
      final response = await http.put(
        Uri.parse(url),
        headers: authService.getAuthHeaders(),
        body: jsonEncode(planData),
      );
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Unknown error';
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return (true, message);
      } else {
        return (false, message);
      }
    } catch (e) {
      await Logger.log('[TravelConciergeService] Error updating plan: $e');
      return (false, 'Error: $e');
    }
  }

  /// Xóa plan theo planUuid
  Future<bool> deletePlan(String planUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/plan/$planUuid/delete/';
      await Logger.log('[TravelConciergeService] Delete plan: $url');
      final response =
          await http.delete(Uri.parse(url), headers: ApiConfig.jsonHeaders);
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      return false;
    } catch (e) {
      await Logger.log('[TravelConciergeService] Error deletePlan: $e');
      return false;
    }
  }

  /// Handle Server-Sent Events response
  Stream<SearchResult> _handleSSEResponse(
      http.StreamedResponse response) async* {
    await Logger.log('🔄 Starting to handle SSE response...');
    final stream = response.stream.transform(utf8.decoder);

    // Buffer to accumulate partial chunks
    String buffer = '';
    bool hasReceivedResponse = false;

    await for (String chunk in stream) {
      await Logger.log('📡 Raw SSE chunk received:');
      await Logger.log('   Chunk length: ${chunk.length}');
      await Logger.log(
          '   Chunk content: ${chunk.substring(0, chunk.length > 500 ? 500 : chunk.length)}${chunk.length > 500 ? "..." : ""}');

      // Accumulate chunk in buffer
      buffer += chunk;

      // Split buffer into lines and process complete lines
      final lines = buffer.split('\n');

      // Keep the last line in buffer if it's incomplete
      if (!buffer.endsWith('\n')) {
        buffer = lines.last;
        lines.removeLast();
      } else {
        buffer = '';
      }

      await Logger.log('   Split into ${lines.length} lines');
      await Logger.log('   Buffer remaining: ${buffer.length} chars');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        try {
          final jsonString = line.substring(6); // Remove "data: " prefix
          await Logger.log('📤 Processing SSE data line:');
          await Logger.log('   JSON string: $jsonString');

          final eventData = jsonDecode(jsonString);
          await Logger.log('✅ Successfully parsed JSON:');
          await Logger.log('   Event data keys: ${eventData.keys.toList()}');
          await Logger.log('   Full event data: $eventData');

          final event = ApiEvent.fromJson(eventData);
          await Logger.log('🎯 Created ApiEvent:');
          await Logger.log('   Author: ${event.author}');
          await Logger.log('   Has error: ${event.hasError}');
          await Logger.log('   Has content: ${event.hasContent}');
          if (event.hasError) {
            await Logger.log('   Error: ${event.error}');
          }

          if (event.hasError) {
            yield SearchResult(
              text: 'Agent Error: ${event.error}',
              author: 'system',
              timestamp: DateTime.now(),
            );
            continue;
          }

          if (event.hasContent) {
            hasReceivedResponse = true;
            final content = event.content!;
            await Logger.log('📋 Processing event content:');
            await Logger.log('   Content type: ${content.runtimeType}');

            final textParts = content.getTextParts();
            final functionResponses = content.getFunctionResponses();

            await Logger.log('📝 Extracted data:');
            await Logger.log('   Text parts count: ${textParts.length}');
            for (int i = 0; i < textParts.length; i++) {
              await Logger.log(
                  '   Text part [$i]: ${textParts[i].substring(0, textParts[i].length > 200 ? 200 : textParts[i].length)}${textParts[i].length > 200 ? "..." : ""}');
            }

            // Debug: Log function responses
            if (functionResponses.isNotEmpty) {
              await Logger.log(
                  '🔧 Found ${functionResponses.length} function responses:');
              for (int i = 0; i < functionResponses.length; i++) {
                final fr = functionResponses[i];
                await Logger.log('   [$i] Name: ${fr['name']}');
                await Logger.log(
                    '       Response type: ${fr['response'].runtimeType}');
                await Logger.log('       Full function response: $fr');
                if (fr['response'] is Map) {
                  await Logger.log(
                      '       Response keys: ${(fr['response'] as Map).keys.toList()}');
                  await Logger.log('       Response data: ${fr['response']}');
                }
              }
            } else {
              await Logger.log('🔧 No function responses found in this event');
            }

            // Yield text parts as separate results
            for (String text in textParts) {
              if (text.trim().isNotEmpty) {
                await Logger.log('🚀 Yielding SearchResult:');
                await Logger.log(
                    '   Text: ${text.substring(0, text.length > 200 ? 200 : text.length)}${text.length > 200 ? "..." : ""}');
                await Logger.log('   Author: ${event.author ?? 'agent'}');
                await Logger.log(
                    '   Function responses attached: ${functionResponses.length}');

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
              await Logger.log(
                  '🎨 Function indicator for "$functionName": $indicator');
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
          await Logger.log('❌ Error parsing SSE data: $e');
          await Logger.log('❌ Problematic line: $line');
          // Don't break the stream, continue processing other lines
        }
      }
    }

    // Check if we received any response
    if (!hasReceivedResponse) {
      await Logger.log('❌ No AI response received from stream');
    }

    await Logger.log('✅ Finished handling SSE response');
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
      await Logger.log('[TravelConciergeService] Get user plans: $url');
      final response =
          await http.get(Uri.parse(url), headers: ApiConfig.jsonHeaders);
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
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
      await Logger.log('[TravelConciergeService] Error getUserPlans: $e');
      return [];
    }
  }

  /// Lấy chi tiết plan theo planUuid
  Future<Map<String, dynamic>?> getPlanDetail(String planUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/plan/$planUuid/';
      await Logger.log('[TravelConciergeService] Get plan detail: $url');
      final response =
          await http.get(Uri.parse(url), headers: ApiConfig.jsonHeaders);
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      await Logger.log('[TravelConciergeService] Error getPlanDetail: $e');
      return null;
    }
  }

  /// Extract itinerary JSON from free-form text using extractor API
  static Future<String?> extractItineraryFromText(String text) async {
    try {
      await Logger.log('🛠️ Calling extractor API for itinerary text...');
      // Ví dụ endpoint extractor, cần chỉnh lại cho đúng API thực tế
      final url = ApiConfig.getExtractorUrl();
      final payload = {
        'task': 'extract_itinerary',
        'text': text,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      await Logger.log('🛠️ Extractor API status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['json'] != null) {
          await Logger.log('🛠️ Extractor API returned JSON itinerary.');
          return data['json'] as String;
        } else if (data is String) {
          await Logger.log('🛠️ Extractor API returned raw string.');
          return data;
        }
      } else {
        await Logger.log('❌ Extractor API error: ${response.body}');
      }
    } catch (e) {
      await Logger.log('❌ Exception in extractor API: $e');
    }
    return null;
  }

  /// Save a place for the user
  Future<(bool, String)> savePlace(
      String userUuid, Map<String, dynamic> place) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/place/$userUuid/create/';
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      final payload = jsonEncode(place); // Send as flat object
      await Logger.log('[TravelConciergeService] Saving place: $payload');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: payload,
      );
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      final body = jsonDecode(response.body);
      final message = body['message']?.toString() ?? 'Unknown error';
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return (true, message);
      } else {
        return (false, message);
      }
    } catch (e) {
      await Logger.log('[TravelConciergeService] Error saving place: $e');
      return (false, 'Error: $e');
    }
  }

  /// Get user's saved places
  Future<List<Map<String, dynamic>>> getUserPlaces(String userUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/place/$userUuid/list/';
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      await Logger.log('[TravelConciergeService] Fetching user places: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      await Logger.log(
          '[TravelConciergeService] Error fetching user places: $e');
      return [];
    }
  }

  /// Get detailed place information by place_uuid
  Future<Map<String, dynamic>?> getPlaceDetails(String placeUuid) async {
    try {
      final url = '${ApiConfig.baseUrl}/user_manager/place/$placeUuid';
      final authService = AuthService();
      final headers = authService.getAuthHeaders();
      await Logger.log('[TravelConciergeService] Fetching place details: $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      await Logger.log('  Status code: ${response.statusCode}');
      await Logger.log('  Response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
      return null;
    } catch (e) {
      await Logger.log(
          '[TravelConciergeService] Error fetching place details: $e');
      return null;
    }
  }
}
