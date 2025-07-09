import 'dart:async';
import '../models/api_models.dart';

/// Mockup data service for testing Plan and Map screens
class MockupDataService {
  static final MockupDataService _instance = MockupDataService._internal();
  factory MockupDataService() => _instance;
  MockupDataService._internal();

  /// Mock response with both location and itinerary data
  static const String mockResponseWithLocationAndItinerary = '''
Now that we have your flight (driving) and hotel information, let's create a draft itinerary for your trip to Kyoto!

**Trip:** Family Trip to Historic Kyoto
**Dates:** July 15, 2025 - July 17, 2025
**Origin:** Tokyo
**Destination:** Kyoto
**Hotel:** RIHGA Royal Hotel Kyoto (Twin with Balcony)

**Day 1: July 15, 2025**

*   Morning: Drive from Tokyo to Kyoto (Allow ample time for the drive, including breaks).
*   Afternoon: Check in to RIHGA Royal Hotel Kyoto (Check-in time: 15:00).
*   Afternoon: Visit Kiyomizu-dera Temple (Historic temple with panoramic views).
*   Evening: Walk through Historic Higashiyama District.
*   Dinner: Traditional Kaiseki Dinner (Kikunoi Restaurant - Booking Required).

**Day 2: July 16, 2025**

*   Morning: Explore Fushimi Inari Shrine (Thousands of vibrant red torii gates).
*   Afternoon: Family-friendly Bamboo Grove Walk (Arashiyama Bamboo Grove).
*   Afternoon: Visit Tenryu-ji Temple and Gardens (Booking Required).
*   Evening: Family Dinner at Ramen Restaurant (Ippudo Ramen Kyoto).

**Day 3: July 17, 2025**

*   Morning: Visit Kyoto National Museum (Booking Required).
*   Afternoon: Last-minute Souvenir Shopping at Kyoto Station.
*   Afternoon: Drive back to Tokyo.

Here are some amazing places to visit in Kyoto:

1. **Kinkaku-ji (Golden Pavilion):** Zen Buddhist temple covered in gold leaf, reflected in a beautiful pond. Address: 1 Kinkakujicho, Kita Ward, Kyoto, 603-8361, Japan. Rating: 4.6. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJvUbrwCCoAWARX2QiHCsn5A4) Place ID: ChIJvUbrwCCoAWARX2QiHCsn5A4

2. **Fushimi Inari-taisha Shrine:** Thousands of vibrant red torii gates winding up a mountainside. Address: 68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto, 612-0882, Japan. Rating: 4.7. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJIW0uPRUPAWAR6eI6dRzKGns) Place ID: ChIJIW0uPRUPAWAR6eI6dRzKGns

3. **Kiyomizu-dera Temple:** Historic temple with a wooden stage offering panoramic views. Address: 294 Kiyomizu 1-chome, Higashiyama Ward, Kyoto, 605-0862, Japan. Rating: 4.5. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJB_vchdMIAWARujTEUIZlr2I) Place ID: ChIJB_vchdMIAWARujTEUIZlr2I

4. **Arashiyama Bamboo Grove:** A stunning path through towering bamboo stalks. Address: Ukyo Ward, Kyoto, 616-8394, Japan. Rating: 4.5. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJrYtcv-urAWAR3XzWvXv8n_s) Place ID: ChIJrYtcv-urAWAR3XzWvXv8n_s

5. **Nishiki Market:** A vibrant marketplace with local food and crafts. Address: 609 Shinkyogoku-dori, Nakagyo Ward, Kyoto, 604-8054, Japan. Rating: 4.3. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJT8uMzZwIAWARnGzsARCjnrY) Place ID: ChIJT8uMzZwIAWARnGzsARCjnrY

Is this draft itinerary satisfactory?
''';

  /// Mock function responses with location data
  static const List<Map<String, dynamic>> mockFunctionResponses = [
    {
      'name': 'poi_agent',
      'response': {
        'places': [
          {
            'place_name': 'Kinkaku-ji (Golden Pavilion)',
            'address': '1 Kinkakujicho, Kita Ward, Kyoto, 603-8361, Japan',
            'lat': '35.03937',
            'long': '135.7292431',
            'review_ratings': '4.6',
            'highlights':
                'Zen Buddhist temple covered in gold leaf, reflected in a beautiful pond.',
            'image_url':
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=ATKogpd5zSL2tWu72e79Goky3kmB3hq1cI6TMynzmeGR4t_kvqgvoeDgTbgK3z7tdykblbh57MyWJ8W22V2j39WLec2r6QRCbRH8QRlhgkHLRa3WANtj1M3GN2Wz0bKFeubxZpliRxhm6qUeLohjrdpT1Xr_WHABVb-ptTQq0SxIrz6PAI5EMUprl6XEeXc0sblJT5NPFs1lTxkMlXJqQAN-mtXEgjiQ2KMx6r2TdSik4lsJUB7uG0hhzNw8v6fgMJAGCUe7D60YvZJVpvItPF2ooJaHTiOiiIRBzJ0cmc5Z47NoyO-ewxMAeZelOzkV7VvcM_yfe0KjnBO-VDWPbqLV1KlRZencO9aSMRzIv_CbqSXr9S6V4dOYfe86wRzz8qWwh0Z3MqjD4cOM0ZAUwPPPc6nqlSktsEWZjwQUUBMq0klqWQBhEWH6rMbvVymNYUORryErAOVS_3HFl8YNAVlmLbYInZ877k_FvP4lWm60QxyKGaIPU3iGR6GAOsCx6LJ7q5CTOkClHWksUFHj_xoS9yqJBHvyWS7EzZ3ucos-zWnxQkx8r7QI7cFNxQpStOB7V2T1-_2H7N6IVg&key=AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg',
            'map_url':
                'https://www.google.com/maps/place/?q=place_id:ChIJvUbrwCCoAWARX2QiHCsn5A4',
            'place_id': 'ChIJvUbrwCCoAWARX2QiHCsn5A4'
          },
          {
            'place_name': 'Fushimi Inari-taisha Shrine',
            'address':
                '68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto, 612-0882, Japan',
            'lat': '34.9676945',
            'long': '135.7791876',
            'review_ratings': '4.7',
            'highlights':
                'Thousands of vibrant red torii gates winding up a mountainside.',
            'image_url':
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=ATKogpfb__9tYb9Hv4vuELrhAH0h0WblbonRremoForZbUPi-yN4ihUMwoz-zCaai1mx9Azaw1376_ShOJqBD_uWNBI3oPWfHcfKWfrBtbdd6MWCdlun3xp2jRkCKz1rlyOx3o1dQosfRO6O4czjONO-eW2oLMreyaSO5Lm9ZigXBbgHWIOYKlIhcAgHIpNZDwf7abTrGHCkBo4ogh5AIgkoZC1IoGYZk0FaHSHH3612BF0dnn94oIOh94OhMeqFZFQETHsSZcRjV8ENKiSuU9CwFntOKZ9kB7t8Qxs5gvOiyQKanyo2Su-9D5EUHWT9BT2xNkb5Dgt_qFlEXLpllq7JdmQavH8nVcbaGKBwcACrNsPKv0mEZNMcqjtyS7wGeJOciHetHUnyHSqExLE2s9AOBJgP0GuVxmestfO-pBYBuc7O4wYXz5rQjQm_DRVR8fmjdmfk4_3t3eZGlzKuMTdbSVMcK74mXWbZNIaEF6TfVuyQYgT8Vcu1PeOC5DtaXo8iIRtq4ZPgHS4DU6uKdVQZqihxhToa_FkVmCiL3GFftC1uFeM5762IRaSjaAgAC_50yIbevOP8_7OYzQ&key=AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg',
            'map_url':
                'https://www.google.com/maps/place/?q=place_id:ChIJIW0uPRUPAWAR6eI6dRzKGns',
            'place_id': 'ChIJIW0uPRUPAWAR6eI6dRzKGns'
          },
          {
            'place_name': 'Kiyomizu-dera Temple',
            'address':
                '294 Kiyomizu 1-chome, Higashiyama Ward, Kyoto, 605-0862, Japan',
            'lat': '34.9946662',
            'long': '135.784661',
            'review_ratings': '4.5',
            'highlights':
                'Historic temple with a wooden stage offering panoramic views.',
            'image_url':
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=ATKogpevL9Ali_6cI437Sut7cs6GJgXxA3yKhAJrMI__DiNs6PrPUggcaV41iqLoFgpyEtsiNvqbEX1pFhzBZf4osDs437w9QNHzS4itXSeRDJx1FXvFEenGHLG8BhAb7w_CvjUG9tRGvOsPEKutQoWMAb9eaTG0MExpeg7-7323cT2dynJNEl0W-CuSYqAK--LQRKz7nMHLRWZJgNCf6jGGvMOgExwLEag-_Ie-Wj9T-Q0b_5KfyLZEIY6UDQZEBned781slWqdS6pAnZv5bCgCBA-709MnKIj16UGX7zvP0zMm_PbR02PXFMoZcUIKKgWMwwPJgx5rB0G1xUo3akqV93PrW789H3Qfydrs-vPe4UMplEZFDQkNU2jiZgp-VJOwcK7RewT6NWJexkgWmZwVGkOPLRPaKVwnpxep8jue-B45YUjlrFzBjsdiidJR7SH3B-5Xx3O1rq8bIEdEhuSinIfvLzYIseKTErDYmkIthiL_E_vdhK0KdcalWVt43LVqHRB6bElegiPherH9sXVXXYTa1g5s5MtpjcZnFVLiBUBHD-TqT51BrMG5ma481qwsbqChcVj4&key=AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg',
            'map_url':
                'https://www.google.com/maps/place/?q=place_id:ChIJB_vchdMIAWARujTEUIZlr2I',
            'place_id': 'ChIJB_vchdMIAWARujTEUIZlr2I'
          },
          {
            'place_name': 'Arashiyama Bamboo Grove',
            'address': 'Ukyo Ward, Kyoto, 616-8394, Japan',
            'lat': '35.0168187',
            'long': '135.6713013',
            'review_ratings': '4.5',
            'highlights': 'A stunning path through towering bamboo stalks.',
            'image_url':
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=ATKogpczq4-RvwW4uL1bxvaFSqRGqWbEGzA_zWkx8akG6j5KeKdY_zZWxLHCDQrkKeG91jzqfFtWybdNiNpc3-okNjPI8X9McbG8kSt5tPZE_ZYJNM23VNzgChs6eVSaf0dW-iLbKpPYTxndxMHztkNxz23r0eEEAReUq1VBVDXmKUuXGrRChNsLmBErTmPJV-XK0RQqwRkP-zSzzBPKQHb05LZaZdFIRqpqMA0DYPwHxqk4EOxAcSrW3gf2O8j_ZtL4cme3nuI92QTUppNzrlj9hnwXE2F7688bqnSlDGeMVlwXICqxqRuCpwjr7xwG90Bj9GljvjjmptQuxO8qsVbWLNHoMEnTvKiR6GYSlC5f0lSnds_bGo9ZLCSzKs2sUKp_9CShbw8dpKtGjgsfQuIbRNiEMTlkIfjK9dG5g_MpDfktALB8xQvt-DSIZJdWJ35yE7I71Q6YFnT2-fe2KbpycN7e5SmlLNgJGLRgKEaFCtqf3L1HfYBOLn42GVT7DnIAQrjOM_S_tXsKDh4PBPV2uA3j2bcOHuuXGn7GnFjah5g7om7l2yDdouO_9WmB89NosTkzTc9murFgcA&key=AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg',
            'map_url':
                'https://www.google.com/maps/place/?q=place_id:ChIJrYtcv-urAWAR3XzWvXv8n_s',
            'place_id': 'ChIJrYtcv-urAWAR3XzWvXv8n_s'
          },
          {
            'place_name': 'Nishiki Market',
            'address':
                '609番地 Shinkyogoku-dori, Nakagyo Ward, Kyoto, 604-8054, Japan',
            'lat': '35.0050258',
            'long': '135.764723',
            'review_ratings': '4.3',
            'highlights': 'A vibrant marketplace with local food and crafts.',
            'image_url':
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=ATKogpexWFEdo70g1Zqh4BF2V1wFHfFcJg6DePo2VPFMSJVzxV1kgev83m3LLjRupCCY13vwR5ewJHMZ_S7EaLLE-KrolD5ns-AzWRl1g8TrCKnHHBuIa5k1XG5ok5hnkUq3dp1tDBvR74pxpV4HM9a-kpc6pZUc8cBU682VMrUqT_bhYr6Dyey6tLt1RsaHB1tTsONQFEm7KzNi6UX8npJeW9rOaTMyROdRn3IMr9kiW2YvgboFiGSbiFq_dwTGdBdw6t9oYLMbnzaz3KLgV86mMfw2RGJt97UHIVs-19qrJv81xAjWj7tlyJzvJ3z73hPUgl7muOwheoZeqaUicFbreGQWWlxnvf69v3YaRnN9Az-Q2GNBDnAB5QDLpVGFgZo2auNDod-Pa_t2aLAZfGK5bc2yxIf9mggQt5MDdR79FZXMGrJVTYL1UfABZpkVpw9b4_30K9Mnv3kq_NM-fqeczS8vtALkuYGAXbrwW7tyq0kD1yfhpHxoFCbveC8ywJYHSduATlmlxUhD02aP2Fagz3bc0u8jkhyvC4OzHDNuChO4vhdxEHzLo20Lfnk45HptGyWY0-gW&key=AIzaSyC6CKHUDCkbDcukn3-U8sG0xkoWGsKv9Xg',
            'map_url':
                'https://www.google.com/maps/place/?q=place_id:ChIJT8uMzZwIAWARnGzsARCjnrY',
            'place_id': 'ChIJT8uMzZwIAWARnGzsARCjnrY'
          }
        ]
      }
    }
  ];

  /// Mock response with only location data (no itinerary)
  static const String mockResponseWithLocationOnly = '''
Here are some amazing places to visit in Kyoto:

1. **Kinkaku-ji (Golden Pavilion):** Zen Buddhist temple covered in gold leaf, reflected in a beautiful pond. Address: 1 Kinkakujicho, Kita Ward, Kyoto, 603-8361, Japan. Rating: 4.6. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJvUbrwCCoAWARX2QiHCsn5A4) Place ID: ChIJvUbrwCCoAWARX2QiHCsn5A4

2. **Fushimi Inari-taisha Shrine:** Thousands of vibrant red torii gates winding up a mountainside. Address: 68 Fukakusa Yabunouchicho, Fushimi Ward, Kyoto, 612-0882, Japan. Rating: 4.7. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJIW0uPRUPAWAR6eI6dRzKGns) Place ID: ChIJIW0uPRUPAWAR6eI6dRzKGns

3. **Kiyomizu-dera Temple:** Historic temple with a wooden stage offering panoramic views. Address: 294 Kiyomizu 1-chome, Higashiyama Ward, Kyoto, 605-0862, Japan. Rating: 4.5. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJB_vchdMIAWARujTEUIZlr2I) Place ID: ChIJB_vchdMIAWARujTEUIZlr2I

4. **Arashiyama Bamboo Grove:** A stunning path through towering bamboo stalks. Address: Ukyo Ward, Kyoto, 616-8394, Japan. Rating: 4.5. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJrYtcv-urAWAR3XzWvXv8n_s) Place ID: ChIJrYtcv-urAWAR3XzWvXv8n_s

5. **Nishiki Market:** A vibrant marketplace with local food and crafts. Address: 609 Shinkyogoku-dori, Nakagyo Ward, Kyoto, 604-8054, Japan. Rating: 4.3. [Google Maps](https://www.google.com/maps/place/?q=place_id:ChIJT8uMzZwIAWARnGzsARCjnrY) Place ID: ChIJT8uMzZwIAWARnGzsARCjnrY

These are some of the most popular attractions in Kyoto that you shouldn't miss!
''';

  /// Mock response with only itinerary data (no location)
  static const String mockResponseWithItineraryOnly = '''
Perfect! Here's your detailed itinerary for Kyoto:

**Trip:** Family Trip to Historic Kyoto
**Dates:** July 15, 2025 - July 17, 2025
**Origin:** Tokyo
**Destination:** Kyoto
**Hotel:** RIHGA Royal Hotel Kyoto (Twin with Balcony)

**Day 1: July 15, 2025**

*   Morning: Drive from Tokyo to Kyoto (Allow ample time for the drive, including breaks).
*   Afternoon: Check in to RIHGA Royal Hotel Kyoto (Check-in time: 15:00).
*   Afternoon: Visit Kiyomizu-dera Temple (Historic temple with panoramic views).
*   Evening: Walk through Historic Higashiyama District.
*   Dinner: Traditional Kaiseki Dinner (Kikunoi Restaurant - Booking Required).

**Day 2: July 16, 2025**

*   Morning: Explore Fushimi Inari Shrine (Thousands of vibrant red torii gates).
*   Afternoon: Family-friendly Bamboo Grove Walk (Arashiyama Bamboo Grove).
*   Afternoon: Visit Tenryu-ji Temple and Gardens (Booking Required).
*   Evening: Family Dinner at Ramen Restaurant (Ippudo Ramen Kyoto).

**Day 3: July 17, 2025**

*   Morning: Visit Kyoto National Museum (Booking Required).
*   Afternoon: Last-minute Souvenir Shopping at Kyoto Station.
*   Afternoon: Drive back to Tokyo.

This itinerary is designed to give you a perfect balance of cultural experiences, relaxation, and family-friendly activities. Enjoy your trip!
''';

  /// Mock response with no special data (just text)
  static const String mockResponseWithNoSpecialData = '''
Hello! How can I help you plan your dream vacation today?

I can assist you with:
- Finding the best destinations for your interests
- Creating detailed travel itineraries
- Discovering amazing places to visit
- Planning your perfect trip

What would you like to explore today?
''';

  /// Get mock response based on type
  static String getMockResponse(MockResponseType type) {
    switch (type) {
      case MockResponseType.locationAndItinerary:
        return mockResponseWithLocationAndItinerary;
      case MockResponseType.locationOnly:
        return mockResponseWithLocationOnly;
      case MockResponseType.itineraryOnly:
        return mockResponseWithItineraryOnly;
      case MockResponseType.noSpecialData:
        return mockResponseWithNoSpecialData;
    }
  }

  /// Get mock function responses
  static List<Map<String, dynamic>> getMockFunctionResponses() {
    return mockFunctionResponses;
  }

  /// Simulate AI response with delay
  static Future<Map<String, dynamic>> simulateAIResponse(
    MockResponseType type, {
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);

    return {
      'text': getMockResponse(type),
      'functionResponses': type == MockResponseType.locationAndItinerary ||
              type == MockResponseType.locationOnly
          ? getMockFunctionResponses()
          : null,
    };
  }
}

/// Types of mock responses
enum MockResponseType {
  locationAndItinerary, // Has both location and itinerary data
  locationOnly, // Has only location data
  itineraryOnly, // Has only itinerary data
  noSpecialData, // Has no special data (just text)
}
