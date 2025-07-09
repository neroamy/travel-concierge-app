import 'dart:math';

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
        functionCall: partJson['functionCall'] ?? partJson['function_call'],
        functionResponse:
            partJson['functionResponse'] ?? partJson['function_response'],
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
  final String? imageUrl;

  PlaceSearchResult({
    required this.title,
    required this.address,
    required this.highlights,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    this.placeId,
    this.imageUrl,
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
        imageUrl: null,
      );
    } catch (e) {
      print('Error extracting place info: $e');
      return null;
    }
  }

  /// Extract location results from response
  static List<PlaceSearchResult> extractLocationResults(String response) {
    if (AIResponseAnalyzer.hasLocationListPattern(response)) {
      return ResponseParser.parseAIResponse(response);
    }
    return [];
  }

  /// Extract location results from function responses (new API format)
  static List<PlaceSearchResult> extractLocationResultsFromFunctions(
      List<Map<String, dynamic>> functionResponses) {
    final List<PlaceSearchResult> places = [];

    print('🔍 Processing ${functionResponses.length} function responses...');

    for (final functionResponse in functionResponses) {
      try {
        final String? functionName = functionResponse['name'];
        print('🔧 Processing function: $functionName');

        if (functionName == 'map_tool' || functionName == 'poi_agent') {
          final dynamic response = functionResponse['response'];
          if (response is Map<String, dynamic>) {
            final dynamic placesData = response['places'];
            if (placesData is List) {
              print(
                  '📍 Found ${placesData.length} places in $functionName response');

              for (final placeData in placesData) {
                if (placeData is Map<String, dynamic>) {
                  final place = _parseMapToolPlace(placeData);
                  if (place != null) {
                    places.add(place);
                    print('✅ Parsed place: ${place.title}');
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error processing function response: $e');
      }
    }

    print('🏁 Total places extracted from functions: ${places.length}');
    return places;
  }

  /// Parse individual place from map_tool response
  static PlaceSearchResult? _parseMapToolPlace(Map<String, dynamic> placeData) {
    try {
      final String placeName = placeData['place_name'] ?? '';
      final String address = placeData['address'] ?? '';
      final String highlights = placeData['highlights'] ?? '';
      final String ratingStr = placeData['review_ratings'] ?? '0.0';
      final String latStr = placeData['lat'] ?? '0.0';
      final String longStr = placeData['long'] ?? '0.0';
      final String imageUrl = placeData['image_url'] ?? '';
      final String mapUrl = placeData['map_url'] ?? '';
      final String placeId = placeData['place_id'] ?? '';

      // Parse numeric values
      final double rating = double.tryParse(ratingStr) ?? 0.0;
      final double latitude = double.tryParse(latStr) ?? 0.0;
      final double longitude = double.tryParse(longStr) ?? 0.0;

      print('📋 Parsing place:');
      print('   - Name: $placeName');
      print('   - Address: $address');
      print('   - Rating: $rating');
      print('   - Coordinates: $latitude, $longitude');
      print('   - Image URL: ${imageUrl.isNotEmpty ? "✅" : "❌"}');
      print('   - Map URL: ${mapUrl.isNotEmpty ? "✅" : "❌"}');

      // Generate Google Maps URL only if not provided
      String finalMapUrl = mapUrl;
      if (finalMapUrl.isEmpty && latitude != 0.0 && longitude != 0.0) {
        finalMapUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
        print('🔗 Generated Google Maps URL: $finalMapUrl');
      }

      // Validate required fields
      if (placeName.isEmpty || address.isEmpty) {
        print('❌ Missing required fields for place');
        return null;
      }

      return PlaceSearchResult(
        title: placeName,
        address: address,
        highlights: highlights,
        rating: rating,
        latitude: latitude,
        longitude: longitude,
        googleMapsUrl: finalMapUrl,
        placeId: placeId.isNotEmpty ? placeId : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );
    } catch (e) {
      print('❌ Error parsing map tool place: $e');
      return null;
    }
  }

  /// Parse individual place from poi_agent response
  static PlaceSearchResult? _parsePoiAgentPlace(
      Map<String, dynamic> placeData) {
    try {
      final String placeName = placeData['place_name'] ?? '';
      final String address = placeData['address'] ?? '';
      final String highlights = placeData['highlights'] ?? '';
      final String ratingStr = placeData['review_ratings'] ?? '0.0';
      final String latStr = placeData['lat'] ?? '0.0';
      final String longStr = placeData['long'] ?? '0.0';
      final String imageUrl = placeData['image_url'] ?? '';
      final String mapUrl = placeData['map_url'] ?? '';
      final String placeId = placeData['place_id'] ?? '';

      // Parse numeric values
      final double rating = double.tryParse(ratingStr) ?? 0.0;
      final double latitude = double.tryParse(latStr) ?? 0.0;
      final double longitude = double.tryParse(longStr) ?? 0.0;

      print('📋 Parsing poi_agent place:');
      print('   - Name: $placeName');
      print('   - Address: $address');
      print('   - Rating: $rating');
      print('   - Coordinates: $latitude, $longitude');
      print('   - Image URL: ${imageUrl.isNotEmpty ? "✅" : "❌"}');
      print('   - Map URL: ${mapUrl.isNotEmpty ? "✅" : "❌"}');

      // Validate required fields
      if (placeName.isEmpty || address.isEmpty) {
        print('❌ Missing required fields for place');
        return null;
      }

      return PlaceSearchResult(
        title: placeName,
        address: address,
        highlights: highlights,
        rating: rating,
        latitude: latitude,
        longitude: longitude,
        googleMapsUrl: mapUrl.isNotEmpty
            ? mapUrl
            : _generateGoogleMapsUrl(latitude, longitude, placeName),
        placeId: placeId.isNotEmpty ? placeId : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );
    } catch (e) {
      print('❌ Error parsing poi_agent place: $e');
      return null;
    }
  }

  /// Generate Google Maps URL from coordinates and place name
  static String _generateGoogleMapsUrl(
      double lat, double lng, String placeName) {
    final encodedPlaceName = Uri.encodeComponent(placeName);
    return 'https://maps.google.com/maps?q=$lat,$lng&query=$encodedPlaceName';
  }
}

/// Enum for AI response types
enum AIResponseType {
  locationList, // Contains place suggestions
  itinerary, // Contains travel itinerary
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
    // Check for itinerary patterns
    if (hasItineraryPattern(response)) {
      return AIResponseType.itinerary;
    }

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

  /// Analyze response with function responses included
  static AIResponseType analyzeResponseWithFunctions(
      String response, List<Map<String, dynamic>> functionResponses) {
    // Check if function responses contain location data
    if (functionResponses.any((fr) => fr['name'] == 'map_tool')) {
      return AIResponseType.locationList;
    }

    // Check for itinerary in text response
    if (hasItineraryPattern(response)) {
      return AIResponseType.itinerary;
    }

    // Fallback to text analysis
    return analyzeResponse(response);
  }

  /// Check if response contains itinerary format
  static bool hasItineraryPattern(String text) {
    print('🔍 Checking itinerary pattern in text...');

    // Multiple indicators for itinerary
    final hasDayPattern = text.contains(RegExp(r'\*\*Day \d+[^:]*:\*\*')) ||
        text.contains(RegExp(r'\*\*Day \d+ \([\d-]+\):\*\*')) ||
        text.contains(RegExp(r'\*\*Day \d+:[^*]*\*\*'));
    print('   - Has day pattern: $hasDayPattern');

    final hasTimeSlots = text.toLowerCase().contains('morning:') ||
        text.toLowerCase().contains('afternoon:') ||
        text.toLowerCase().contains('evening:') ||
        text.toLowerCase().contains('sáng:') ||
        text.toLowerCase().contains('chiều:') ||
        text.toLowerCase().contains('tối:') ||
        text.toLowerCase().contains('am:') ||
        text.toLowerCase().contains('pm:');
    print('   - Has time slots: $hasTimeSlots');

    final hasMultipleDays = RegExp(r'\*\*Day \d+').allMatches(text).length >= 2;
    print('   - Has multiple days: $hasMultipleDays');

    // Alternative patterns for itinerary
    final hasAlternativeDayPattern = text.contains(RegExp(r'Day \d+')) &&
        (text.contains('morning') ||
            text.contains('afternoon') ||
            text.contains('evening') ||
            text.contains('am') ||
            text.contains('pm'));
    print('   - Has alternative day pattern: $hasAlternativeDayPattern');

    final result = (hasDayPattern && hasTimeSlots && hasMultipleDays) ||
        hasAlternativeDayPattern;
    print('   - Final itinerary pattern result: $result');

    return result;
  }

  /// Check if response contains location list format
  static bool hasLocationListPattern(String text) {
    print('🔍 Checking location list pattern in text...');

    // Multiple indicators for location list
    final hasNumberedList = text.contains(RegExp(r'\d+\.\s*\*\*[^*]+\*\*'));
    print('   - Has numbered list: $hasNumberedList');

    final hasAddress = text.toLowerCase().contains('address:') ||
        text.toLowerCase().contains('địa chỉ:');
    print('   - Has address: $hasAddress');

    final hasRating = text.toLowerCase().contains('rating:') ||
        text.toLowerCase().contains('đánh giá:');
    print('   - Has rating: $hasRating');

    final hasMultipleEntries =
        RegExp(r'\d+\.\s*\*\*[^*]+\*\*').allMatches(text).length >= 2;
    print('   - Has multiple entries: $hasMultipleEntries');

    // Alternative patterns for location list
    final hasAlternativePattern = text.contains(RegExp(r'\d+\.\s*[A-Za-z]')) &&
        (text.contains('address') ||
            text.contains('rating') ||
            text.contains('địa chỉ'));
    print('   - Has alternative pattern: $hasAlternativePattern');

    final result =
        (hasNumberedList && hasAddress && hasRating && hasMultipleEntries) ||
            hasAlternativePattern;
    print('   - Final location list pattern result: $result');

    return result;
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

  /// Extract itinerary from response
  static List<ItineraryDayModel> extractItinerary(String response) {
    final List<ItineraryDayModel> days = [];

    print('📅 Starting to parse itinerary from response...');
    print('📝 Response text length: ${response.length}');

    try {
      // Try multiple patterns for day detection
      List<RegExpMatch> dayMatches = [];

      // Pattern 1: **Day X (YYYY-MM-DD):**
      final dayPattern1 = RegExp(r'\*\*Day (\d+) \(([\d-]+)\):\*\*');
      dayMatches = dayPattern1.allMatches(response).toList();
      print('🔍 Pattern 1 found ${dayMatches.length} matches');

      // Pattern 2: Day X: or **Day X:** or **Day X: July 15, 2025**
      if (dayMatches.isEmpty) {
        final dayPattern2 = RegExp(r'\*\*?Day (\d+):[^*]*\*\*?');
        dayMatches = dayPattern2.allMatches(response).toList();
        print('🔍 Pattern 2 found ${dayMatches.length} matches');
      }

      // Pattern 3: Ngày X: (Vietnamese)
      if (dayMatches.isEmpty) {
        final dayPattern3 = RegExp(r'\*\*?Ngày (\d+):?\*\*?');
        dayMatches = dayPattern3.allMatches(response).toList();
        print('🔍 Pattern 3 found ${dayMatches.length} matches');
      }

      print('🔍 Total day matches found: ${dayMatches.length}');

      for (final match in dayMatches) {
        try {
          final dayNumber = int.parse(match.group(1)!);

          // Try to extract date from the match or generate one
          String dateString = '';
          DateTime date;

          if (match.groupCount >= 2 && match.group(2) != null) {
            dateString = match.group(2)!;
            date = DateTime.parse(dateString);
          } else {
            // Generate a date based on day number (starting from today)
            date = DateTime.now().add(Duration(days: dayNumber - 1));
            dateString = date.toIso8601String().split('T')[0];
          }

          print('📅 Processing Day $dayNumber with date: $dateString');

          final displayDate = _formatDisplayDate(date);

          // Extract activities for this day
          final activities = _extractActivitiesForDay(response, match);

          if (activities.isNotEmpty) {
            days.add(ItineraryDayModel(
              dayNumber: dayNumber,
              date: date,
              displayDate: displayDate,
              activities: activities,
            ));
            print(
                '✅ Successfully parsed Day $dayNumber with ${activities.length} activities');
          }
        } catch (e) {
          print('❌ Error parsing day: $e');
          continue;
        }
      }

      print('🏁 Itinerary parsing completed. Total days: ${days.length}');
    } catch (e) {
      print('❌ Error parsing itinerary: $e');
    }

    return days;
  }

  /// Extract activities for a specific day
  static List<ItineraryActivityModel> _extractActivitiesForDay(
      String text, RegExpMatch dayMatch) {
    final List<ItineraryActivityModel> activities = [];

    try {
      // Find the section for this day
      final startIndex = dayMatch.start;
      final nextDayMatch =
          RegExp(r'\*\*?Day \d+').firstMatch(text.substring(dayMatch.end));
      final endIndex = nextDayMatch != null
          ? dayMatch.end + nextDayMatch.start
          : text.length;

      final daySection = text.substring(startIndex, endIndex);
      print(
          '📄 Day section: ${daySection.substring(0, daySection.length > 200 ? 200 : daySection.length)}...');

      // Try multiple patterns for activities
      List<RegExpMatch> activityMatches = [];

      // Pattern 1: * Time: Description
      final activityPattern1 = RegExp(r'\*\s*([^:]+):\s*([^\n]+)');
      activityMatches = activityPattern1.allMatches(daySection).toList();
      print('🔍 Pattern 1 found ${activityMatches.length} activities');

      // Pattern 2: - Time: Description
      if (activityMatches.isEmpty) {
        final activityPattern2 = RegExp(r'-\s*([^:]+):\s*([^\n]+)');
        activityMatches = activityPattern2.allMatches(daySection).toList();
        print('🔍 Pattern 2 found ${activityMatches.length} activities');
      }

      // Pattern 3: Time: Description (without bullet)
      if (activityMatches.isEmpty) {
        final activityPattern3 = RegExp(r'([^:]+):\s*([^\n]+)');
        activityMatches = activityPattern3.allMatches(daySection).toList();
        print('🔍 Pattern 3 found ${activityMatches.length} activities');
      }

      for (final match in activityMatches) {
        final timeSlot = match.group(1)?.trim() ?? '';
        final description = match.group(2)?.trim() ?? '';

        // Filter out non-activity entries
        if (timeSlot.isNotEmpty && description.isNotEmpty) {
          // Skip if it's just a header or section title
          if (timeSlot.toLowerCase().contains('day') ||
              timeSlot.toLowerCase().contains('ngày') ||
              timeSlot.length > 20) {
            continue;
          }

          // Determine weather icon based on activity type
          final weatherIcon = _getWeatherIconForActivity(description);

          // Extract title from description (first part before comma or period)
          final title = _extractTitleFromDescription(description);

          activities.add(ItineraryActivityModel(
            timeSlot: timeSlot,
            title: title,
            description: description,
            weatherIcon: weatherIcon,
            isActive: activities.isEmpty, // First activity is active
          ));

          print('   - $timeSlot: $title');
        }
      }
    } catch (e) {
      print('❌ Error extracting activities: $e');
    }

    return activities;
  }

  /// Format date for display (e.g., "July 10")
  static String _formatDisplayDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Get weather icon based on activity description
  static String _getWeatherIconForActivity(String description) {
    final lowerDesc = description.toLowerCase();

    if (lowerDesc.contains('hike') || lowerDesc.contains('walk')) return '🥾';
    if (lowerDesc.contains('drive') || lowerDesc.contains('travel'))
      return '🚗';
    if (lowerDesc.contains('check in') || lowerDesc.contains('hotel'))
      return '🏨';
    if (lowerDesc.contains('dinner') || lowerDesc.contains('restaurant'))
      return '🍽️';
    if (lowerDesc.contains('relax') || lowerDesc.contains('enjoy')) return '😌';
    if (lowerDesc.contains('visit') || lowerDesc.contains('monument'))
      return '🏛️';
    if (lowerDesc.contains('pond') || lowerDesc.contains('lake')) return '🏞️';
    if (lowerDesc.contains('bridge') || lowerDesc.contains('river'))
      return '🌉';

    return '📍'; // Default location icon
  }

  /// Extract title from description
  static String _extractTitleFromDescription(String description) {
    // Take first meaningful part before comma, period, or parentheses
    final titleMatch = RegExp(r'^([^,.(]+)').firstMatch(description);
    if (titleMatch != null) {
      return titleMatch.group(1)?.trim() ?? description;
    }
    return description;
  }

  /// Extract location results from response and function responses
  static List<PlaceSearchResult> extractLocationResults(String response,
      {List<Map<String, dynamic>>? functionResponses}) {
    final List<PlaceSearchResult> places = [];

    print('🔍 Starting location extraction...');

    // First try to extract from function responses (new API format)
    if (functionResponses != null && functionResponses.isNotEmpty) {
      final functionPlaces =
          AIResponseAnalyzer.extractLocationResultsFromFunctions(
              functionResponses);
      places.addAll(functionPlaces);
      print(
          '📍 Extracted ${functionPlaces.length} places from function responses');
    }

    // Fallback to text parsing (old format or mixed format)
    if (places.isEmpty || AIResponseAnalyzer.hasLocationListPattern(response)) {
      final textPlaces = ResponseParser.parseAIResponse(response);
      places.addAll(textPlaces);
      print('📍 Extracted ${textPlaces.length} places from text response');
    }

    // Only extract from map_url in text if we don't have function responses
    // This prevents duplicate URLs when server already provides them
    if (places.isEmpty &&
        (functionResponses == null || functionResponses.isEmpty) &&
        (response.contains('map_url') ||
            response.contains('google.com/maps'))) {
      final fallbackPlaces = _extractPlacesFromMapUrls(response);
      places.addAll(fallbackPlaces);
      print(
          '📍 Extracted ${fallbackPlaces.length} places from map URLs in text');
    }

    print('🏁 Total places extracted: ${places.length}');
    return places;
  }

  /// Extract places from map URLs found in text response
  static List<PlaceSearchResult> _extractPlacesFromMapUrls(String response) {
    final List<PlaceSearchResult> places = [];

    try {
      // Find all Google Maps URLs
      final urlPattern = RegExp(r'https://maps\.google\.com[^\s\n]+');
      final urlMatches = urlPattern.allMatches(response);

      print('🔗 Found ${urlMatches.length} Google Maps URLs in response');

      for (final match in urlMatches) {
        final url = match.group(0)!;
        print('🔗 Processing URL: $url');

        // Extract place name from URL or surrounding text
        final placeName = _extractPlaceNameFromContext(response, match.start);

        if (placeName.isNotEmpty) {
          // Generate approximate coordinates (you can improve this with geocoding)
          final latitude = 35.6762 + (placeName.hashCode % 100) * 0.001;
          final longitude = 139.6503 + (placeName.hashCode % 100) * 0.001;

          places.add(PlaceSearchResult(
            title: placeName,
            address: 'Location from AI response',
            highlights: 'Recommended by AI',
            rating: 4.0,
            latitude: latitude,
            longitude: longitude,
            googleMapsUrl: url,
            placeId: null,
            imageUrl: null,
          ));

          print('✅ Created place: $placeName');
        }
      }
    } catch (e) {
      print('❌ Error extracting places from map URLs: $e');
    }

    return places;
  }

  /// Extract place name from context around a URL
  static String _extractPlaceNameFromContext(String text, int urlStart) {
    try {
      // Look for place name before the URL (within 100 characters)
      final beforeUrl = text.substring(max(0, urlStart - 100), urlStart);

      // Try to find a place name pattern
      final namePatterns = [
        RegExp(
            r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s*:?\s*$'), // Capitalized words
        RegExp(r'\*\*([^*]+)\*\*'), // Bold text
        RegExp(
            r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+Google Maps'), // Name + Google Maps
      ];

      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(beforeUrl);
        if (match != null && match.group(1) != null) {
          final name = match.group(1)!.trim();
          if (name.length > 2 && name.length < 50) {
            print('📝 Extracted place name: $name');
            return name;
          }
        }
      }

      // Fallback: use first capitalized words
      final words = beforeUrl
          .split(' ')
          .where((word) =>
              word.isNotEmpty &&
              word[0] == word[0].toUpperCase() &&
              word.length > 2)
          .toList();

      if (words.isNotEmpty) {
        final name = words.take(3).join(' '); // Take up to 3 words
        print('📝 Fallback place name: $name');
        return name;
      }
    } catch (e) {
      print('❌ Error extracting place name: $e');
    }

    return 'Unknown Location';
  }

  /// Get response summary for UI display
  static String getResponseSummary(String response) {
    if (response.length <= 100) return response;
    return '${response.substring(0, 97)}...';
  }

  /// Extract location results from function responses (new API format)
  static List<PlaceSearchResult> extractLocationResultsFromFunctions(
      List<Map<String, dynamic>> functionResponses) {
    final List<PlaceSearchResult> places = [];

    print('🔍 Processing ${functionResponses.length} function responses...');

    for (final functionResponse in functionResponses) {
      try {
        final String? functionName = functionResponse['name'];
        print('🔧 Processing function: $functionName');

        if (functionName == 'map_tool' || functionName == 'poi_agent') {
          final dynamic response = functionResponse['response'];
          if (response is Map<String, dynamic>) {
            final dynamic placesData = response['places'];
            if (placesData is List) {
              print(
                  '📍 Found ${placesData.length} places in $functionName response');

              for (final placeData in placesData) {
                if (placeData is Map<String, dynamic>) {
                  final place = _parseMapToolPlace(placeData);
                  if (place != null) {
                    places.add(place);
                    print('✅ Parsed place: ${place.title}');
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('❌ Error processing function response: $e');
      }
    }

    print('🏁 Total places extracted from functions: ${places.length}');
    return places;
  }

  /// Parse individual place from map_tool response
  static PlaceSearchResult? _parseMapToolPlace(Map<String, dynamic> placeData) {
    try {
      final String placeName = placeData['place_name'] ?? '';
      final String address = placeData['address'] ?? '';
      final String highlights = placeData['highlights'] ?? '';
      final String ratingStr = placeData['review_ratings'] ?? '0.0';
      final String latStr = placeData['lat'] ?? '0.0';
      final String longStr = placeData['long'] ?? '0.0';
      final String imageUrl = placeData['image_url'] ?? '';
      final String mapUrl = placeData['map_url'] ?? '';
      final String placeId = placeData['place_id'] ?? '';

      // Parse numeric values
      final double rating = double.tryParse(ratingStr) ?? 0.0;
      final double latitude = double.tryParse(latStr) ?? 0.0;
      final double longitude = double.tryParse(longStr) ?? 0.0;

      print('📋 Parsing place:');
      print('   - Name: $placeName');
      print('   - Address: $address');
      print('   - Rating: $rating');
      print('   - Coordinates: $latitude, $longitude');
      print('   - Image URL: ${imageUrl.isNotEmpty ? "✅" : "❌"}');
      print('   - Map URL: ${mapUrl.isNotEmpty ? "✅" : "❌"}');

      // Generate Google Maps URL only if not provided
      String finalMapUrl = mapUrl;
      if (finalMapUrl.isEmpty && latitude != 0.0 && longitude != 0.0) {
        finalMapUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
        print('🔗 Generated Google Maps URL: $finalMapUrl');
      }

      // Validate required fields
      if (placeName.isEmpty || address.isEmpty) {
        print('❌ Missing required fields for place');
        return null;
      }

      return PlaceSearchResult(
        title: placeName,
        address: address,
        highlights: highlights,
        rating: rating,
        latitude: latitude,
        longitude: longitude,
        googleMapsUrl: finalMapUrl,
        placeId: placeId.isNotEmpty ? placeId : null,
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      );
    } catch (e) {
      print('❌ Error parsing map tool place: $e');
      return null;
    }
  }
}

/// Model for parsed itinerary day
class ItineraryDayModel {
  final int dayNumber;
  final DateTime date;
  final String displayDate; // "July 10"
  final List<ItineraryActivityModel> activities;

  const ItineraryDayModel({
    required this.dayNumber,
    required this.date,
    required this.displayDate,
    required this.activities,
  });
}

/// Model for individual activity in itinerary
class ItineraryActivityModel {
  final String timeSlot; // "Morning", "Afternoon", "Evening"
  final String title;
  final String description;
  final String weatherIcon; // Default icon based on activity type
  final bool isActive;

  const ItineraryActivityModel({
    required this.timeSlot,
    required this.title,
    required this.description,
    required this.weatherIcon,
    this.isActive = false,
  });
}

/// User Profile models for Profile Settings
class UserProfile {
  final String id;
  final String username;
  final String email;
  final String address;
  final String interests; // sở thích
  final String? avatarUrl;

  // Extended fields from server
  final String? passportNationality;
  final String? seatPreference;
  final String? foodPreference;
  final List<String>? allergies;
  final List<String>? likes;
  final List<String>? dislikes;
  final List<String>? priceSensitivity;
  final String? homeAddress;
  final String? localPreferMode;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.address,
    required this.interests,
    this.avatarUrl,
    this.passportNationality,
    this.seatPreference,
    this.foodPreference,
    this.allergies,
    this.likes,
    this.dislikes,
    this.priceSensitivity,
    this.homeAddress,
    this.localPreferMode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      interests: json['interests'] ?? '',
      avatarUrl: json['avatar_url'],
      passportNationality: json['passport_nationality'],
      seatPreference: json['seat_preference'],
      foodPreference: json['food_preference'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : null,
      likes: json['likes'] != null ? List<String>.from(json['likes']) : null,
      dislikes:
          json['dislikes'] != null ? List<String>.from(json['dislikes']) : null,
      priceSensitivity: json['price_sensitivity'] != null
          ? List<String>.from(json['price_sensitivity'])
          : null,
      homeAddress: json['home_address'],
      localPreferMode: json['local_prefer_mode'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'address': address,
      'interests': interests,
      'avatar_url': avatarUrl,
      'passport_nationality': passportNationality,
      'seat_preference': seatPreference,
      'food_preference': foodPreference,
      'allergies': allergies,
      'likes': likes,
      'dislikes': dislikes,
      'price_sensitivity': priceSensitivity,
      'home_address': homeAddress,
      'local_prefer_mode': localPreferMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? address,
    String? interests,
    String? avatarUrl,
    String? passportNationality,
    String? seatPreference,
    String? foodPreference,
    List<String>? allergies,
    List<String>? likes,
    List<String>? dislikes,
    List<String>? priceSensitivity,
    String? homeAddress,
    String? localPreferMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      address: address ?? this.address,
      interests: interests ?? this.interests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      passportNationality: passportNationality ?? this.passportNationality,
      seatPreference: seatPreference ?? this.seatPreference,
      foodPreference: foodPreference ?? this.foodPreference,
      allergies: allergies ?? this.allergies,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      priceSensitivity: priceSensitivity ?? this.priceSensitivity,
      homeAddress: homeAddress ?? this.homeAddress,
      localPreferMode: localPreferMode ?? this.localPreferMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Profile update request model
class ProfileUpdateRequest {
  final String username;
  final String email;
  final String address;
  final String interests;
  final String? avatarUrl;

  // Extended fields (optional)
  final String? passportNationality;
  final String? seatPreference;
  final String? foodPreference;
  final List<String>? allergies;
  final List<String>? likes;
  final List<String>? dislikes;
  final List<String>? priceSensitivity;
  final String? homeAddress;
  final String? localPreferMode;

  ProfileUpdateRequest({
    required this.username,
    required this.email,
    required this.address,
    required this.interests,
    this.avatarUrl,
    this.passportNationality,
    this.seatPreference,
    this.foodPreference,
    this.allergies,
    this.likes,
    this.dislikes,
    this.priceSensitivity,
    this.homeAddress,
    this.localPreferMode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'address': address,
      'interests': interests,
    };

    // Only include non-null values
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (passportNationality != null)
      data['passport_nationality'] = passportNationality;
    if (seatPreference != null) data['seat_preference'] = seatPreference;
    if (foodPreference != null) data['food_preference'] = foodPreference;
    if (allergies != null) data['allergies'] = allergies;
    if (likes != null) data['likes'] = likes;
    if (dislikes != null) data['dislikes'] = dislikes;
    if (priceSensitivity != null) data['price_sensitivity'] = priceSensitivity;
    if (homeAddress != null) data['home_address'] = homeAddress;
    if (localPreferMode != null) data['local_prefer_mode'] = localPreferMode;

    return data;
  }
}

/// Password change request model
class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    };
  }
}

/// Profile API response model
class ProfileApiResponse {
  final bool success;
  final String message;
  final UserProfile? data;

  ProfileApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProfileApiResponse.fromJson(Map<String, dynamic> json) {
    return ProfileApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }
}

// Authentication Models
class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String? message;
  final UserData? user;
  final String? token;

  LoginResponse({
    required this.success,
    this.message,
    this.user,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      token: json['token'],
    );
  }
}

class UserData {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? address;
  final List<String>? interests;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.address,
    this.interests,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      address: json['address'],
      interests: json['interests'] != null
          ? List<String>.from(json['interests'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'address': address,
      'interests': interests,
    };
  }
}
