import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'api_config.dart';

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
}
