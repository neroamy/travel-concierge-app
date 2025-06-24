/// Message payload structure
class MessagePayload {
  final String sessionId;
  final String appName;
  final String userId;
  final UserMessage newMessage;

  MessagePayload({
    required this.sessionId,
    required this.appName,
    required this.userId,
    required this.newMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'app_name': appName,
      'user_id': userId,
      'new_message': newMessage.toJson(),
    };
  }
}

/// User message structure
class UserMessage {
  final String role;
  final List<MessagePart> parts;

  UserMessage({
    this.role = 'user',
    required this.parts,
  });

  UserMessage.text(String text)
      : role = 'user',
        parts = [MessagePart.text(text)];

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': parts.map((part) => part.toJson()).toList(),
    };
  }
}

/// Message part structure
class MessagePart {
  final String? text;
  final Map<String, dynamic>? functionCall;
  final Map<String, dynamic>? functionResponse;

  MessagePart({this.text, this.functionCall, this.functionResponse});

  MessagePart.text(String text)
      : text = text,
        functionCall = null,
        functionResponse = null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (text != null) json['text'] = text;
    if (functionCall != null) json['functionCall'] = functionCall;
    if (functionResponse != null) json['functionResponse'] = functionResponse;
    return json;
  }
}

/// API Response Event structure
class ApiEvent {
  final String? author;
  final EventContent? content;
  final String? error;

  ApiEvent({this.author, this.content, this.error});

  factory ApiEvent.fromJson(Map<String, dynamic> json) {
    return ApiEvent(
      author: json['author'],
      content: json['content'] != null
          ? EventContent.fromJson(json['content'])
          : null,
      error: json['error'],
    );
  }

  bool get hasError => error != null;
  bool get hasContent => content != null;
}

/// Event content structure
class EventContent {
  final List<MessagePart> parts;

  EventContent({required this.parts});

  factory EventContent.fromJson(Map<String, dynamic> json) {
    final List<dynamic> partsJson = json['parts'] ?? [];
    final List<MessagePart> parts = partsJson.map((partJson) {
      return MessagePart(
        text: partJson['text'],
        functionCall: partJson['functionCall'],
        functionResponse: partJson['functionResponse'],
      );
    }).toList();

    return EventContent(parts: parts);
  }

  /// Get all text parts from content
  List<String> getTextParts() {
    return parts
        .where((part) => part.text != null && part.text!.trim().isNotEmpty)
        .map((part) => part.text!)
        .toList();
  }

  /// Get all function calls
  List<Map<String, dynamic>> getFunctionCalls() {
    return parts
        .where((part) => part.functionCall != null)
        .map((part) => part.functionCall!)
        .toList();
  }

  /// Get all function responses
  List<Map<String, dynamic>> getFunctionResponses() {
    return parts
        .where((part) => part.functionResponse != null)
        .map((part) => part.functionResponse!)
        .toList();
  }
}

/// Search result model for UI
class SearchResult {
  final String text;
  final String author;
  final DateTime timestamp;
  final List<Map<String, dynamic>> functionResponses;

  SearchResult({
    required this.text,
    required this.author,
    required this.timestamp,
    this.functionResponses = const [],
  });
}

/// Itinerary models for AI agent integration
class ItineraryRequest {
  final String destination;
  final String category;
  final int days;
  final Map<String, dynamic>? preferences;

  ItineraryRequest({
    required this.destination,
    required this.category,
    required this.days,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'category': category,
      'days': days,
      'preferences': preferences ?? {},
    };
  }
}

class ItineraryResponse {
  final List<ItineraryDay> days;
  final String destination;
  final Map<String, dynamic> metadata;

  ItineraryResponse({
    required this.days,
    required this.destination,
    required this.metadata,
  });

  factory ItineraryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> daysJson = json['days'] ?? [];
    final List<ItineraryDay> days =
        daysJson.map((dayJson) => ItineraryDay.fromJson(dayJson)).toList();

    return ItineraryResponse(
      days: days,
      destination: json['destination'] ?? '',
      metadata: json['metadata'] ?? {},
    );
  }
}

class ItineraryDay {
  final int day;
  final String date;
  final List<ItineraryActivity> activities;

  ItineraryDay({
    required this.day,
    required this.date,
    required this.activities,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    final List<dynamic> activitiesJson = json['activities'] ?? [];
    final List<ItineraryActivity> activities = activitiesJson
        .map((activityJson) => ItineraryActivity.fromJson(activityJson))
        .toList();

    return ItineraryDay(
      day: json['day'] ?? 0,
      date: json['date'] ?? '',
      activities: activities,
    );
  }
}

class ItineraryActivity {
  final String time;
  final String title;
  final String description;
  final String location;
  final WeatherInfo? weather;
  final ActivityType type;

  ItineraryActivity({
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    this.weather,
    required this.type,
  });

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) {
    return ItineraryActivity(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      weather: json['weather'] != null
          ? WeatherInfo.fromJson(json['weather'])
          : null,
      type: ActivityType.fromString(json['type'] ?? 'activity'),
    );
  }
}

class WeatherInfo {
  final String condition;
  final String icon;
  final double temperature;
  final String description;

  WeatherInfo({
    required this.condition,
    required this.icon,
    required this.temperature,
    required this.description,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      condition: json['condition'] ?? '',
      icon: json['icon'] ?? '☀️',
      temperature: (json['temperature'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }
}

enum ActivityType {
  sightseeing,
  dining,
  adventure,
  relaxation,
  cultural,
  nightlife,
  transportation;

  static ActivityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sightseeing':
        return ActivityType.sightseeing;
      case 'dining':
        return ActivityType.dining;
      case 'adventure':
        return ActivityType.adventure;
      case 'relaxation':
        return ActivityType.relaxation;
      case 'cultural':
        return ActivityType.cultural;
      case 'nightlife':
        return ActivityType.nightlife;
      case 'transportation':
        return ActivityType.transportation;
      default:
        return ActivityType.sightseeing;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityType.sightseeing:
        return 'Sightseeing';
      case ActivityType.dining:
        return 'Dining';
      case ActivityType.adventure:
        return 'Adventure';
      case ActivityType.relaxation:
        return 'Relaxation';
      case ActivityType.cultural:
        return 'Cultural';
      case ActivityType.nightlife:
        return 'Nightlife';
      case ActivityType.transportation:
        return 'Transportation';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.sightseeing:
        return '🏛️';
      case ActivityType.dining:
        return '🍽️';
      case ActivityType.adventure:
        return '⛰️';
      case ActivityType.relaxation:
        return '🧘';
      case ActivityType.cultural:
        return '🎭';
      case ActivityType.nightlife:
        return '🌃';
      case ActivityType.transportation:
        return '🚗';
    }
  }
}

/// Model for place search results from AI API
class PlaceSearchResult {
  final String title;
  final String address;
  final String highlights;
  final double rating;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;
  final String? placeId;

  PlaceSearchResult({
    required this.title,
    required this.address,
    required this.highlights,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    this.placeId,
  });
}

/// Parser for AI response text
class ResponseParser {
  /// Parse AI response text and extract place information
  static List<PlaceSearchResult> parseAIResponse(String responseText) {
    final List<PlaceSearchResult> places = [];

    print('🔄 Starting to parse AI response...');
    print('📝 Response text length: ${responseText.length}');
    print(
        '📝 Response preview: ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}...');

    try {
      // Split response into sections based on numbered items
      final patterns = RegExp(r'\d+\.\s*\*\*([^*]+)\*\*');
      final matches = patterns.allMatches(responseText);

      print('🔍 Found ${matches.length} potential place matches with pattern');

      for (final match in matches) {
        try {
          print('🎯 Processing match: ${match.group(0)}');
          final placeInfo = _extractPlaceInfo(responseText, match);
          if (placeInfo != null) {
            places.add(placeInfo);
            print('✅ Successfully parsed place: ${placeInfo.title}');
          } else {
            print('❌ Failed to extract place info from match');
          }
        } catch (e) {
          print('Error parsing place info: $e');
          // Skip this place if parsing fails
          continue;
        }
      }

      print('🏁 Parsing completed. Total places found: ${places.length}');
    } catch (e) {
      print('Error parsing AI response: $e');
    }

    return places;
  }

  /// Extract individual place information from text
  static PlaceSearchResult? _extractPlaceInfo(
      String text, RegExpMatch titleMatch) {
    try {
      final title = titleMatch.group(1)?.trim() ?? '';
      print('📋 Extracting info for title: "$title"');

      if (title.isEmpty) {
        print('❌ Empty title, skipping');
        return null;
      }

      // Find the section for this place
      final startIndex = titleMatch.start;
      final nextMatch =
          RegExp(r'\d+\.\s*\*\*').firstMatch(text.substring(titleMatch.end));
      final endIndex =
          nextMatch != null ? titleMatch.end + nextMatch.start : text.length;

      final section = text.substring(startIndex, endIndex);
      print('📄 Section text: "$section"');

      // Extract address (handle both formats: "Address:" and "*   Address:")
      final addressMatch =
          RegExp(r'[*\s]*Address:\s*([^\n]+)').firstMatch(section);
      final address = addressMatch?.group(1)?.trim() ?? '';
      print('🏠 Address: "$address" (match: ${addressMatch?.group(0)})');

      // Extract highlights (handle both formats: "Highlights:" and "*   Highlights:")
      final highlightsMatch =
          RegExp(r'[*\s]*Highlights:\s*([^\n]+)').firstMatch(section);
      final highlights = highlightsMatch?.group(1)?.trim() ?? '';
      print(
          '✨ Highlights: "$highlights" (match: ${highlightsMatch?.group(0)})');

      // Extract rating (handle both formats: "Rating:" and "*   Rating:")
      final ratingMatch =
          RegExp(r'[*\s]*Rating:\s*([\d.]+)').firstMatch(section);
      final rating = double.tryParse(ratingMatch?.group(1) ?? '') ?? 0.0;
      print('⭐ Rating: $rating (match: ${ratingMatch?.group(0)})');

      // Extract Google Maps URL and coordinates (optional in current format)
      final urlMatch = RegExp(r'[*\s]*Google Maps URL:\s*(https://[^\n]+)')
          .firstMatch(section);
      final googleMapsUrl = urlMatch?.group(1)?.trim() ?? '';
      print('🗺️ Google Maps URL: "$googleMapsUrl"');

      // Extract lat/lng from URL if available
      double latitude = 0.0;
      double longitude = 0.0;

      if (googleMapsUrl.isNotEmpty) {
        final coordMatch =
            RegExp(r'query=([\d.-]+),([\d.-]+)').firstMatch(googleMapsUrl);
        latitude = double.tryParse(coordMatch?.group(1) ?? '') ?? 0.0;
        longitude = double.tryParse(coordMatch?.group(2) ?? '') ?? 0.0;
        print('📍 Coordinates from URL: $latitude, $longitude');
      } else {
        // TODO: Use geocoding service to get coordinates from address
        // For now, generate approximate coordinates for Japan region
        latitude = 35.6762 + (title.hashCode % 100) * 0.001; // Tokyo area base
        longitude = 139.6503 + (address.hashCode % 100) * 0.001;
        print('📍 Generated approximate coordinates: $latitude, $longitude');
      }

      // Extract place ID if available
      final placeIdMatch =
          RegExp(r'[*\s]*query_place_id=([^&\n\s]+)').firstMatch(section);
      final placeId = placeIdMatch?.group(1)?.trim();
      print('🆔 Place ID: "$placeId"');

      // Validate required fields (coordinates are now optional)
      if (title.isEmpty || address.isEmpty) {
        print('❌ Missing required fields for place: $title');
        print('   Title empty: ${title.isEmpty}');
        print('   Address empty: ${address.isEmpty}');
        return null;
      }

      print('✅ Successfully extracted place info for: $title');

      return PlaceSearchResult(
        title: title,
        address: address,
        highlights: highlights,
        rating: rating,
        latitude: latitude,
        longitude: longitude,
        googleMapsUrl: googleMapsUrl,
        placeId: placeId?.isNotEmpty == true ? placeId : null,
      );
    } catch (e) {
      print('Error extracting place info: $e');
      return null;
    }
  }
}

/// Enum for AI response types
enum AIResponseType {
  locationList, // Contains place suggestions
  question, // AI asking for clarification
  information, // General info/explanation
  unknown // Fallback
}

/// Model for chat messages
class ChatMessage {
  final String id;
  final String text;
  final String author;
  final DateTime timestamp;
  final bool isFromUser;

  ChatMessage({
    required this.id,
    required this.text,
    required this.author,
    required this.timestamp,
    required this.isFromUser,
  });

  factory ChatMessage.fromApiResponse(String text, String author) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      author: author,
      timestamp: DateTime.now(),
      isFromUser: false,
    );
  }

  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      author: 'user',
      timestamp: DateTime.now(),
      isFromUser: true,
    );
  }
}

/// Analyzer for AI response types and content
class AIResponseAnalyzer {
  /// Analyze response type to determine handling
  static AIResponseType analyzeResponse(String response) {
    // Check for location list patterns
    if (hasLocationListPattern(response)) {
      return AIResponseType.locationList;
    }

    // Check for question patterns
    if (hasQuestionPattern(response)) {
      return AIResponseType.question;
    }

    return AIResponseType.information;
  }

  /// Check if response contains location list format
  static bool hasLocationListPattern(String text) {
    // Multiple indicators for location list
    final hasNumberedList = text.contains(RegExp(r'\d+\.\s*\*\*[^*]+\*\*'));
    final hasAddress = text.toLowerCase().contains('address:');
    final hasRating = text.toLowerCase().contains('rating:');
    final hasMultipleEntries =
        RegExp(r'\d+\.\s*\*\*[^*]+\*\*').allMatches(text).length >= 2;

    return hasNumberedList && hasAddress && hasRating && hasMultipleEntries;
  }

  /// Check if response contains question patterns
  static bool hasQuestionPattern(String text) {
    final lowerText = text.toLowerCase();

    // Check for question marks
    if (text.contains('?')) return true;

    // Check for common question phrases
    final questionPhrases = [
      'bạn muốn',
      'bạn cần',
      'do you want',
      'do you need',
      'which area',
      'what type',
      'how many',
      'when would',
      'có thể cho biết',
      'bạn có thể',
      'would you like',
      'could you specify',
      'more specific',
      'clarify',
    ];

    return questionPhrases.any((phrase) => lowerText.contains(phrase));
  }

  /// Extract location results from response
  static List<PlaceSearchResult> extractLocationResults(String response) {
    if (hasLocationListPattern(response)) {
      return ResponseParser.parseAIResponse(response);
    }
    return [];
  }

  /// Get response summary for UI display
  static String getResponseSummary(String response) {
    if (response.length <= 100) return response;
    return '${response.substring(0, 97)}...';
  }
}
