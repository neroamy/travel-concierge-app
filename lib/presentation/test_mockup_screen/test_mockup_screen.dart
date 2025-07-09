import 'package:flutter/material.dart';
import '../../core/services/mockup_data_service.dart';
import '../../core/models/api_models.dart';
import '../ai_chat_screen/ai_chat_screen.dart';

/// Test screen for testing mockup data with Map, Plan, and Quick Action buttons
class TestMockupScreen extends StatefulWidget {
  const TestMockupScreen({Key? key}) : super(key: key);

  @override
  State<TestMockupScreen> createState() => _TestMockupScreenState();
}

class _TestMockupScreenState extends State<TestMockupScreen> {
  MockResponseType _selectedResponseType =
      MockResponseType.locationAndItinerary;
  bool _isLoading = false;
  String _lastResponse = '';
  List<PlaceSearchResult> _detectedLocations = [];
  List<ItineraryDayModel> _detectedItinerary = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mockup Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Response Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Response Type:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildResponseTypeSelector(),
                  ],
                ),
              ),
            ),
            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Actions:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testMockupData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Test Mockup Data'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _detectedLocations.isNotEmpty ||
                                    _detectedItinerary.isNotEmpty
                                ? _navigateToChat
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Go to Chat'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results Display
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Detected Locations
                              if (_detectedLocations.isNotEmpty) ...[
                                const Text(
                                  '📍 Detected Locations:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(_detectedLocations.map((location) =>
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              location.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(location.address),
                                            Text('Rating: ${location.rating}'),
                                          ],
                                        ),
                                      ),
                                    ))),
                                const SizedBox(height: 16),
                              ],

                              // Detected Itinerary
                              if (_detectedItinerary.isNotEmpty) ...[
                                const Text(
                                  '📅 Detected Itinerary:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...(_detectedItinerary.map((day) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Day ${day.dayNumber}: ${day.displayDate}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                                '${day.activities.length} activities'),
                                          ],
                                        ),
                                      ),
                                    ))),
                                const SizedBox(height: 16),
                              ],

                              // Response Preview
                              if (_lastResponse.isNotEmpty) ...[
                                const Text(
                                  '📄 Response Preview:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _lastResponse.length > 200
                                        ? '${_lastResponse.substring(0, 200)}...'
                                        : _lastResponse,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTypeSelector() {
    return Column(
      children: MockResponseType.values.map((type) {
        return RadioListTile<MockResponseType>(
          title: Text(_getResponseTypeTitle(type)),
          subtitle: Text(_getResponseTypeDescription(type)),
          value: type,
          groupValue: _selectedResponseType,
          onChanged: (MockResponseType? value) {
            setState(() {
              _selectedResponseType = value!;
            });
          },
        );
      }).toList(),
    );
  }

  String _getResponseTypeTitle(MockResponseType type) {
    switch (type) {
      case MockResponseType.locationAndItinerary:
        return 'Location + Itinerary';
      case MockResponseType.locationOnly:
        return 'Location Only';
      case MockResponseType.itineraryOnly:
        return 'Itinerary Only';
      case MockResponseType.noSpecialData:
        return 'No Special Data';
    }
  }

  String _getResponseTypeDescription(MockResponseType type) {
    switch (type) {
      case MockResponseType.locationAndItinerary:
        return 'Shows Map, Plan, and Quick Action buttons';
      case MockResponseType.locationOnly:
        return 'Shows Map and Quick Action buttons only';
      case MockResponseType.itineraryOnly:
        return 'Shows Plan and Quick Action buttons only';
      case MockResponseType.noSpecialData:
        return 'Shows no special buttons';
    }
  }

  Future<void> _testMockupData() async {
    setState(() {
      _isLoading = true;
      _detectedLocations.clear();
      _detectedItinerary.clear();
      _lastResponse = '';
    });

    try {
      // Simulate AI response
      final result = await MockupDataService.simulateAIResponse(
        _selectedResponseType,
        delay: const Duration(seconds: 1),
      );

      final response = result['text'] as String;
      final functionResponses =
          result['functionResponses'] as List<Map<String, dynamic>>?;

      setState(() {
        _lastResponse = response;
      });

      // Analyze response for locations and itinerary
      final locations = AIResponseAnalyzer.extractLocationResults(
        response,
        functionResponses: functionResponses,
      );

      final itinerary = AIResponseAnalyzer.extractItinerary(response);

      setState(() {
        _detectedLocations = locations;
        _detectedItinerary = itinerary;
        _isLoading = false;
      });

      // Show results
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test completed!\n'
            'Locations: ${locations.length}\n'
            'Itinerary days: ${itinerary.length}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToChat() {
    // Get mockup data for the selected response type
    final response = MockupDataService.getMockResponse(_selectedResponseType);
    final functionResponses =
        _selectedResponseType == MockResponseType.locationAndItinerary ||
                _selectedResponseType == MockResponseType.locationOnly
            ? MockupDataService.getMockFunctionResponses()
            : null;

    print('🧪 Navigating to chat screen with mockup data');
    print('Response type: $_selectedResponseType');
    print('Response length: ${response.length}');
    print('Function responses: ${functionResponses?.length ?? 0}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(
          useMockupMode: true,
          mockupResponse: response,
          mockupFunctionResponses: functionResponses,
        ),
      ),
    );
  }
}
