import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'api_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service class for Google Maps integration
class GoogleMapsService {
  static const String _placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';
  static const String _geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode';

  /// Check network connectivity
  static Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 10),
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (kDebugMode) {
          print('✅ Network connectivity: OK');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Network connectivity check failed: $e');
        print('💡 Troubleshooting tips:');
        print('   1. Check emulator internet connection');
        print('   2. Try cold boot emulator');
        print('   3. Check host machine DNS settings');
        print('   4. Try different emulator (Pixel API 34)');
      }
    }
    return false;
  }

  /// Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Search places using Google Places API
  static Future<List<PlaceModel>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    // Check network connectivity first
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      if (kDebugMode) {
        print('🔄 Network unavailable, using mock data for testing...');
      }
      // Return mock data for testing when network is unavailable
      return _getMockPlaces(query);
    }

    try {
      final String url = '$_placesBaseUrl/textsearch/json'
          '?query=$query'
          '&key=${ApiConfig.googleMapsApiKey}';

      if (kDebugMode) {
        print('Making request to: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'TravelConciergeApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check API response status
        final String status = data['status'] ?? '';
        if (status == 'REQUEST_DENIED') {
          final String errorMessage =
              data['error_message'] ?? 'API key not authorized';
          throw Exception('Google API Error: $errorMessage');
        } else if (status != 'OK' && status != 'ZERO_RESULTS') {
          final String errorMessage =
              data['error_message'] ?? 'Unknown API error';
          throw Exception('Google API Error ($status): $errorMessage');
        }

        final List results = data['results'] ?? [];

        return results.map((place) => PlaceModel.fromJson(place)).toList();
      } else {
        throw Exception(
            'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ SocketException: $e');
        print('🔄 Falling back to mock data...');
      }
      return _getMockPlaces(query);
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('❌ ClientException: $e');
        print('🔄 Falling back to mock data...');
      }
      return _getMockPlaces(query);
    } catch (e) {
      if (kDebugMode) {
        print('Error searching places: $e');
        print('🔄 Falling back to mock data...');
      }
      return _getMockPlaces(query);
    }
  }

  /// Get mock places for testing when network is unavailable
  static List<PlaceModel> _getMockPlaces(String query) {
    if (kDebugMode) {
      print('📍 Generating mock places for query: "$query"');
    }

    final mockPlaces = <PlaceModel>[
      PlaceModel(
        placeId: 'mock_1',
        name: 'Mock Hotel ${query.split(' ').first}',
        address: '123 Test Street, Mock City',
        latitude: 37.7749,
        longitude: -122.4194,
        rating: 4.5,
        photoReferences: [],
      ),
      PlaceModel(
        placeId: 'mock_2',
        name: 'Sample Resort near ${query.split(' ').first}',
        address: '456 Demo Avenue, Test Town',
        latitude: 37.7849,
        longitude: -122.4094,
        rating: 4.2,
        photoReferences: [],
      ),
      PlaceModel(
        placeId: 'mock_3',
        name: 'Demo Lodge ${query.split(' ').last}',
        address: '789 Mock Boulevard, Sample City',
        latitude: 37.7649,
        longitude: -122.4294,
        rating: 4.8,
        photoReferences: [],
      ),
    ];

    return mockPlaces;
  }

  /// Get place details by place ID
  static Future<PlaceDetailsModel?> getPlaceDetails(String placeId) async {
    try {
      final String url = '$_placesBaseUrl/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry,photos,rating,price_level'
          '&key=${ApiConfig.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic>? result = data['result'];

        if (result != null) {
          return PlaceDetailsModel.fromJson(result);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting place details: $e');
      }
      return null;
    }
  }

  /// Get autocomplete suggestions
  static Future<List<AutocompletePrediction>> getAutocompletePredictions(
      String input) async {
    if (input.isEmpty) return [];

    // Check network connectivity first
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      if (kDebugMode) {
        print('🔄 Network unavailable, using mock autocomplete data...');
      }
      return _getMockAutocompletePredictions(input);
    }

    try {
      final String url = '$_placesBaseUrl/autocomplete/json'
          '?input=$input'
          '&types=establishment'
          '&key=${ApiConfig.googleMapsApiKey}';

      if (kDebugMode) {
        print('Making autocomplete request to: $url');
      }

      final response = await http.get(Uri.parse(url));

      if (kDebugMode) {
        print('Autocomplete response status: ${response.statusCode}');
        print('Autocomplete response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check API response status
        final String status = data['status'] ?? '';
        if (status == 'REQUEST_DENIED') {
          final String errorMessage =
              data['error_message'] ?? 'API key not authorized';
          throw Exception('Google API Error: $errorMessage');
        } else if (status != 'OK' && status != 'ZERO_RESULTS') {
          final String errorMessage =
              data['error_message'] ?? 'Unknown API error';
          throw Exception('Google API Error ($status): $errorMessage');
        }

        final List predictions = data['predictions'] ?? [];

        return predictions
            .map((prediction) => AutocompletePrediction.fromJson(prediction))
            .toList();
      } else {
        throw Exception(
            'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ Autocomplete SocketException: $e');
        print('🔄 Falling back to mock autocomplete data...');
      }
      return _getMockAutocompletePredictions(input);
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        print('❌ Autocomplete ClientException: $e');
        print('🔄 Falling back to mock autocomplete data...');
      }
      return _getMockAutocompletePredictions(input);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting autocomplete predictions: $e');
        print('🔄 Falling back to mock autocomplete data...');
      }
      return _getMockAutocompletePredictions(input);
    }
  }

  /// Get mock autocomplete predictions for testing
  static List<AutocompletePrediction> _getMockAutocompletePredictions(
      String input) {
    if (kDebugMode) {
      print('📍 Generating mock autocomplete for: "$input"');
    }

    final suggestions = <AutocompletePrediction>[
      AutocompletePrediction(
        placeId: 'mock_auto_1',
        description: '$input Hotel, Mock City, Test Country',
        mainText: '$input Hotel',
        secondaryText: 'Mock City, Test Country',
      ),
      AutocompletePrediction(
        placeId: 'mock_auto_2',
        description: '$input Resort, Sample Town, Demo State',
        mainText: '$input Resort',
        secondaryText: 'Sample Town, Demo State',
      ),
      AutocompletePrediction(
        placeId: 'mock_auto_3',
        description: '$input Station, Test District, Mock Region',
        mainText: '$input Station',
        secondaryText: 'Test District, Mock Region',
      ),
    ];

    return suggestions;
  }

  /// Get turn-by-turn route polyline points from Google Directions API
  static Future<List<LatLng>> getTurnByTurnRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final String baseUrl =
        'https://maps.googleapis.com/maps/api/directions/json';
    final String originStr = '${origin.latitude},${origin.longitude}';
    final String destinationStr =
        '${destination.latitude},${destination.longitude}';
    String waypointsStr = '';
    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsStr = '&waypoints=' +
          waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
    }
    final String url =
        '$baseUrl?origin=$originStr&destination=$destinationStr$waypointsStr&key=${ApiConfig.googleMapsApiKey}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final overviewPolyline = routes[0]['overview_polyline']['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result =
              polylinePoints.decodePolyline(overviewPolyline);
          return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
        }
      }
      throw Exception('Directions API error: ${data['status']}');
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }
}

/// Model class for Place
class PlaceModel {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final List<String> photoReferences;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    required this.photoReferences,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    final photos = json['photos'] as List?;

    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? '',
      latitude: geometry?['lat']?.toDouble() ?? 0.0,
      longitude: geometry?['lng']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble(),
      photoReferences: photos
              ?.map((photo) => photo['photo_reference'] as String?)
              .where((ref) => ref != null)
              .cast<String>()
              .toList() ??
          [],
    );
  }
}

/// Model class for Place Details
class PlaceDetailsModel {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? priceLevel;
  final List<String> photoReferences;

  PlaceDetailsModel({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.priceLevel,
    required this.photoReferences,
  });

  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']?['location'];
    final photos = json['photos'] as List?;

    return PlaceDetailsModel(
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? '',
      latitude: geometry?['lat']?.toDouble() ?? 0.0,
      longitude: geometry?['lng']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble(),
      priceLevel: json['price_level'],
      photoReferences: photos
              ?.map((photo) => photo['photo_reference'] as String?)
              .where((ref) => ref != null)
              .cast<String>()
              .toList() ??
          [],
    );
  }
}

/// Model class for Autocomplete Prediction
class AutocompletePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  AutocompletePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'];

    return AutocompletePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting?['main_text'] ?? '',
      secondaryText: structuredFormatting?['secondary_text'],
    );
  }
}
