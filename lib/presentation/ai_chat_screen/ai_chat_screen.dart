import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/safe_avatar_image.dart';

class AIChatScreen extends StatefulWidget {
  final String? initialQuery;
  final String? mockupResponse;
  final List<Map<String, dynamic>>? mockupFunctionResponses;
  final bool useMockupMode;

  const AIChatScreen({
    super.key,
    this.initialQuery,
    this.mockupResponse,
    this.mockupFunctionResponses,
    this.useMockupMode = false,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalChatService _globalChatService = GlobalChatService();
  final TravelConciergeService _travelService = TravelConciergeService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  bool _useGlobalSession = true;
  String? _initialQuery;

  // Detected data from AI responses
  List<PlaceSearchResult> _detectedLocations = [];
  List<ItineraryDayModel> _detectedItinerary = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize chat with initial query if provided
  void _initializeChat() {
    // If mockup mode is enabled and mockup data is provided, inject it first
    if (widget.useMockupMode && widget.mockupResponse != null) {
      print('🧪 Initializing chat with mockup data...');
      injectMockupData(widget.mockupResponse!, widget.mockupFunctionResponses);
    }

    // Then handle initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _initialQuery = widget.initialQuery;
      _sendMessage(widget.initialQuery!);
    }
  }

  /// Send message from input field
  Future<void> _sendMessageFromInput() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    await _sendMessage(message);
  }

  /// Send message to AI
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    print('💬 Sending message: "$message"');

    // If in mockup mode, don't make API calls
    if (widget.useMockupMode) {
      print('🧪 Mockup mode enabled - skipping API call');
      // Add user message to chat
      final userMessage = ChatMessage.fromUser(message);
      setState(() {
        _messages.add(userMessage);
      });
      _scrollToBottom();
      return;
    }

    if (_useGlobalSession) {
      await _sendMessageViaGlobalService(message);
    } else {
      await _sendMessageViaLocalService(message);
    }
  }

  /// Inject mockup data for testing
  void injectMockupData(
      String response, List<Map<String, dynamic>>? functionResponses) {
    print('🧪 Injecting mockup data for testing...');

    // Add a fake user message for context
    final fakeUserMessage =
        ChatMessage.fromUser('Show me travel options for Maldives');

    // Create a mock AI message
    final mockMessage = ChatMessage.fromApiResponse(response, 'mock_agent');

    setState(() {
      _messages.add(fakeUserMessage);
      _messages.add(mockMessage);
      _isTyping = false;
    });

    // Analyze the mock response
    _analyzeResponse(response, functionResponses: functionResponses);
    _scrollToBottom();

    print('✅ Mockup data injected successfully');
    print('   - Added fake user message');
    print('   - Added mock AI response');
    print('   - Response length: ${response.length}');
    print('   - Function responses: ${functionResponses?.length ?? 0}');
  }

  /// Send message via local travel service
  Future<void> _sendMessageViaLocalService(String message) async {
    final userMessage = ChatMessage.fromUser(message);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _scrollToBottom();
    await _getAIResponse(message);
  }

  /// Send message via global chat service
  Future<void> _sendMessageViaGlobalService(String message) async {
    print('🚀 Sending message via global service: "$message"');
    setState(() {
      _isTyping = true;
    });

    await _globalChatService.sendMessage(message, (chatMessage) {
      print('📨 Received callback message:');
      print('   - ID: ${chatMessage.id}');
      print('   - Text: ${chatMessage.text}');
      print('   - Author: ${chatMessage.author}');
      print('   - IsFromUser: ${chatMessage.isFromUser}');
      print('   - Timestamp: ${chatMessage.timestamp}');

      setState(() {
        // Update local messages with global chat history
        _messages = [..._globalChatService.conversationHistory];
        print('📋 Updated local messages count: ${_messages.length}');

        // Only set typing to false when we receive an AI response
        if (!chatMessage.isFromUser && chatMessage.author != 'system') {
          _isTyping = false;
          print('🤖 AI response received, stopping typing indicator');

          // Analyze response for location data if it's an AI message
          // Get function responses from global chat service if available
          final lastResult = _globalChatService.getLastSearchResult();
          _analyzeResponse(chatMessage.text,
              functionResponses: lastResult?.functionResponses);
        } else {
          print('👤 User message or system message, keeping typing indicator');
        }
      });

      _scrollToBottom();
    });

    print('✅ Global service sendMessage completed');
  }

  /// Get AI response from service
  Future<void> _getAIResponse(String query) async {
    try {
      await for (final result in _travelService.searchTravel(query)) {
        if (result.author != 'system' && result.author != 'user') {
          // This is the AI response
          final aiMessage =
              ChatMessage.fromApiResponse(result.text, result.author);

          setState(() {
            _messages.add(aiMessage);
            _isTyping = false;
          });

          // Analyze response for location data with function responses
          _analyzeResponse(result.text,
              functionResponses: result.functionResponses);
          _scrollToBottom();
          break; // Take the first AI response
        }
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      _showErrorMessage('Connection error. Please try again.');
      print('Chat error: $e');
    }
  }

  /// Analyze AI response for location results and itinerary
  void _analyzeResponse(String response,
      {List<Map<String, dynamic>>? functionResponses}) {
    print('🔍 Analyzing response for locations and itinerary...');
    print('   - Response text length: ${response.length}');
    print('   - Function responses count: ${functionResponses?.length ?? 0}');
    print(
        '   - Response preview: ${response.length > 200 ? response.substring(0, 200) + "..." : response}');

    // Debug: Print full response for analysis
    print('📄 FULL RESPONSE:');
    print(response);
    print('📄 END FULL RESPONSE');

    // Check for itinerary pattern first
    final hasItinerary = AIResponseAnalyzer.hasItineraryPattern(response);
    print('   - Has itinerary pattern: $hasItinerary');

    // Check for location pattern
    final hasLocationList = AIResponseAnalyzer.hasLocationListPattern(response);
    print('   - Has location list pattern: $hasLocationList');

    // Check for map_url in text response
    final hasMapUrlInText = response.contains('map_url') ||
        response.contains('google.com/maps') ||
        response.contains('maps.google.com');
    print('   - Has map_url in text: $hasMapUrlInText');

    // Check function responses for map_tool or poi_agent
    final hasMapTool =
        functionResponses?.any((fr) => fr['name'] == 'map_tool') ?? false;
    final hasPoiAgent =
        functionResponses?.any((fr) => fr['name'] == 'poi_agent') ?? false;
    print('   - Has map_tool function: $hasMapTool');
    print('   - Has poi_agent function: $hasPoiAgent');

    // Debug function responses
    if (functionResponses != null && functionResponses.isNotEmpty) {
      print('🔧 Function responses details:');
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

    // ALWAYS try to extract locations and itinerary from text response
    // This ensures we catch cases where AI returns structured data in text format

    // Handle itinerary detection
    if (hasItinerary) {
      print('📅 Processing itinerary response...');
      _handleItineraryResponse(response);
    }

    // Handle location detection (from both text and function responses)
    if (hasLocationList || hasMapTool || hasMapUrlInText || hasPoiAgent) {
      print('📍 Processing location response...');
      _handleLocationResponse(response, functionResponses);
    }

    // If no specific patterns detected, still try to extract any structured data
    if (!hasItinerary &&
        !hasLocationList &&
        !hasMapTool &&
        !hasMapUrlInText &&
        !hasPoiAgent) {
      print('❓ No specific patterns detected, trying general analysis...');

      // Use new analyzer that handles both text and function responses
      final responseType =
          functionResponses != null && functionResponses.isNotEmpty
              ? AIResponseAnalyzer.analyzeResponseWithFunctions(
                  response, functionResponses)
              : AIResponseAnalyzer.analyzeResponse(response);

      print('   - General response type: $responseType');

      // Handle different response types
      switch (responseType) {
        case AIResponseType.locationList:
          _handleLocationResponse(response, functionResponses);
          break;
        case AIResponseType.itinerary:
          _handleItineraryResponse(response);
          break;
        case AIResponseType.question:
          print('❓ AI is asking a question');
          break;
        case AIResponseType.information:
          print('ℹ️ AI provided general information');
          break;
        default:
          print('❓ Unknown response type');
      }
    }

    // Debug current state after analysis
    print('🏁 Analysis completed:');
    print('   - Detected locations: ${_detectedLocations.length}');
    print('   - Detected itinerary days: ${_detectedItinerary.length}');
  }

  /// Handle location response
  void _handleLocationResponse(
      String response, List<Map<String, dynamic>>? functionResponses) {
    final locations = AIResponseAnalyzer.extractLocationResults(
      response,
      functionResponses: functionResponses,
    );

    setState(() {
      _detectedLocations = locations;
    });

    print('🎯 Detected ${locations.length} locations from response');
    for (int i = 0; i < locations.length; i++) {
      final loc = locations[i];
      print('   [$i] ${loc.title} - ${loc.address}');
      print(
          '       Rating: ${loc.rating}, Coords: ${loc.latitude},${loc.longitude}');
      print('       Image URL: ${loc.imageUrl ?? "No image"}');
      print('       Map URL: ${loc.googleMapsUrl}');
    }
  }

  /// Handle itinerary response
  void _handleItineraryResponse(String response) {
    final itinerary = AIResponseAnalyzer.extractItinerary(response);

    setState(() {
      _detectedItinerary = itinerary;
    });

    print('📅 Detected ${itinerary.length} days from itinerary response');
    for (int i = 0; i < itinerary.length; i++) {
      final day = itinerary[i];
      print(
          '   Day ${day.dayNumber} (${day.displayDate}): ${day.activities.length} activities');
      for (int j = 0; j < day.activities.length; j++) {
        final activity = day.activities[j];
        print('     [$j] ${activity.timeSlot}: ${activity.title}');
      }
    }
  }

  /// Show error message
  void _showErrorMessage(String message) {
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      author: 'system',
      timestamp: DateTime.now(),
      isFromUser: false,
    );

    setState(() {
      _messages.add(errorMessage);
    });
    _scrollToBottom();
  }

  /// Navigate to location screen with detected results
  void _navigateToLocationScreen() {
    if (_detectedLocations.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.locationTargetingScreenWithMaps,
        arguments: {
          'searchQuery': _initialQuery ?? 'Travel search',
          'searchResults': _detectedLocations,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No locations available to display on map'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Navigate to weather query screen with itinerary
  void _navigateToPlanViewScreen() {
    if (_detectedItinerary.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.planViewScreen,
        arguments: {
          'itinerary': _detectedItinerary,
          'source': 'ai_chat',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No itinerary available to display'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Debug method to print current state
  void _debugPrintState() {
    print('🐞 DEBUG STATE:');
    print('   - Local messages count: ${_messages.length}');
    print(
        '   - Global chat history count: ${_globalChatService.conversationHistory.length}');
    print('   - IsTyping: $_isTyping');
    print('   - IsLoading: $_isLoading');
    print('   - UseGlobalSession: $_useGlobalSession');
    print('   - Detected locations: ${_detectedLocations.length}');
    print('   - Detected itinerary days: ${_detectedItinerary.length}');

    print('   - Local messages:');
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      print(
          '     [$i] ${msg.author}: ${msg.text.length > 50 ? msg.text.substring(0, 50) + "..." : msg.text}');
    }

    print('   - Global messages:');
    final globalMessages = _globalChatService.conversationHistory;
    for (int i = 0; i < globalMessages.length; i++) {
      final msg = globalMessages[i];
      print(
          '     [$i] ${msg.author}: ${msg.text.length > 50 ? msg.text.substring(0, 50) + "..." : msg.text}');
    }

    // Force re-analyze last AI response
    _forceReanalyzeLastResponse();
  }

  /// Force re-analyze the last AI response for debugging
  void _forceReanalyzeLastResponse() {
    print('🔄 Force re-analyzing last AI response...');

    // Find last AI response
    final aiMessages = _messages.where((msg) => !msg.isFromUser).toList();
    if (aiMessages.isNotEmpty) {
      final lastAiMessage = aiMessages.last;
      print('📄 Last AI message: ${lastAiMessage.text}');

      // Clear current detections
      setState(() {
        _detectedLocations.clear();
        _detectedItinerary.clear();
      });

      // Re-analyze
      _analyzeResponse(lastAiMessage.text);

      print('✅ Re-analysis completed');
      print('   - New detected locations: ${_detectedLocations.length}');
      print('   - New detected itinerary days: ${_detectedItinerary.length}');
    } else {
      print('❌ No AI messages found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteCustom,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Chat Messages
            Expanded(
              child: _buildChatMessages(),
            ),

            // Input Section
            _buildInputSection(),

            // Add bottom padding for floating action button
            if (_detectedLocations.isNotEmpty || _detectedItinerary.isNotEmpty)
              SizedBox(height: 80.h),
          ],
        ),
      ),
      // Floating Action Button for quick access
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build header with back button and title
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.05),
            blurRadius: 4.h,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                color: appTheme.whiteCustom,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blackCustom.withOpacity(0.1),
                    blurRadius: 8.h,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: appTheme.blackCustom,
                size: 20.h,
              ),
            ),
          ),

          SizedBox(width: 16.h),

          // Title and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Travel Assistant',
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: appTheme.blackCustom,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _isTyping ? 'AI is typing...' : 'Online',
                      style: TextStyle(
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: _isTyping ? appTheme.colorFF0373 : Colors.green,
                      ),
                    ),
                    if (widget.useMockupMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MOCKUP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              // Map Navigation Button (only show if locations detected)
              if (_detectedLocations.isNotEmpty)
                GestureDetector(
                  onTap: _navigateToLocationScreen,
                  child: Container(
                    width: 48.h,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: appTheme.colorFF0373,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: appTheme.colorFF0373.withOpacity(0.3),
                          blurRadius: 8.h,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.map_outlined,
                      color: appTheme.whiteCustom,
                      size: 24.h,
                    ),
                  ),
                ),

              // Plan Button (only show if itinerary detected)
              if (_detectedItinerary.isNotEmpty) ...[
                if (_detectedLocations.isNotEmpty) SizedBox(width: 8.h),
                GestureDetector(
                  onTap: _navigateToPlanViewScreen,
                  child: Container(
                    width: 48.h,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0373F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0373F3).withOpacity(0.3),
                          blurRadius: 8.h,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: appTheme.whiteCustom,
                      size: 24.h,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build chat messages list
  Widget _buildChatMessages() {
    print(
        '🎨 Building chat messages. Count: ${_messages.length}, isTyping: $_isTyping');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            print('💬 Building typing indicator at index: $index');
            return _buildTypingIndicator();
          }

          final message = _messages[index];
          print(
              '💬 Building message bubble for index: $index - Author: ${message.author} - IsUser: ${message.isFromUser}');
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  /// Build individual message bubble
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;
    final isSystem = message.author == 'system';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: 32.h,
              height: 32.h,
              decoration: BoxDecoration(
                color: isSystem ? Colors.orange : appTheme.colorFF0373,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSystem ? Icons.warning : Icons.smart_toy,
                color: appTheme.whiteCustom,
                size: 16.h,
              ),
            ),
            SizedBox(width: 8.h),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: isUser
                    ? appTheme.colorFF0373
                    : isSystem
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(16.h),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                      color:
                          isUser ? appTheme.whiteCustom : appTheme.blackCustom,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.fSize,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: isUser
                          ? appTheme.whiteCustom.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            SizedBox(width: 8.h),
            // User Avatar - Using Profile Data
            UserAvatarImage(
              imageUrl: _globalChatService.getUserAvatarUrl(),
              username: _globalChatService.getUserDisplayName(),
              size: 32.h,
            ),
          ],
        ],
      ),
    );
  }

  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 32.h,
            height: 32.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF0373,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              color: appTheme.whiteCustom,
              size: 16.h,
            ),
          ),
          SizedBox(width: 8.h),
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.h),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4.h),
                _buildDot(1),
                SizedBox(width: 4.h),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated dot for typing indicator
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8.h,
      height: 8.h,
      decoration: BoxDecoration(
        color: appTheme.colorFF0373.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Build input section
  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.all(24.h),
      decoration: BoxDecoration(
        color: appTheme.whiteCustom,
        boxShadow: [
          BoxShadow(
            color: appTheme.blackCustom.withOpacity(0.05),
            blurRadius: 8.h,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Input Field
          Expanded(
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24.h),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(
                    fontSize: 16.fSize,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.h,
                    vertical: 12.h,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16.fSize,
                  color: appTheme.blackCustom,
                  fontFamily: 'Poppins',
                ),
                enabled: !_isTyping,
                onSubmitted: (_) => _sendMessageFromInput(),
              ),
            ),
          ),

          SizedBox(width: 12.h),

          // Send Button
          GestureDetector(
            onTap: _isTyping ? null : _sendMessageFromInput,
            child: Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                color: _isTyping ? Colors.grey[400] : appTheme.colorFF0373,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: appTheme.whiteCustom,
                size: 20.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build floating action button for quick access to Map and Plan
  Widget? _buildFloatingActionButton() {
    // Disable Quick Actions button in AI Chat screen since we have Map and Plan buttons in header
    // Quick Actions should only be shown in other screens like home
    return null;

    // Original code (commented out):
    // Only show if we have detected locations or itinerary
    // if (_detectedLocations.isEmpty && _detectedItinerary.isEmpty) {
    //   return null;
    // }

    // return FloatingActionButton.extended(
    //   onPressed: () {
    //     _showQuickActionsDialog();
    //   },
    //   backgroundColor: appTheme.colorFF0373,
    //   icon: Icon(
    //     Icons.flash_on,
    //     color: appTheme.whiteCustom,
    //   ),
    //   label: Text(
    //     'Quick Actions',
    //     style: TextStyle(
    //       color: appTheme.whiteCustom,
    //       fontWeight: FontWeight.w600,
    //     ),
    //   ),
    // );
  }

  /// Show quick actions dialog
  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: appTheme.whiteCustom,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.blackCustom,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Map Action
                  if (_detectedLocations.isNotEmpty)
                    _buildQuickActionTile(
                      icon: Icons.map_outlined,
                      title: 'View on Map',
                      subtitle: '${_detectedLocations.length} locations found',
                      color: appTheme.colorFF0373,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToLocationScreen();
                      },
                    ),

                  // Plan Action
                  if (_detectedItinerary.isNotEmpty)
                    _buildQuickActionTile(
                      icon: Icons.calendar_today,
                      title: 'View Itinerary',
                      subtitle: '${_detectedItinerary.length} days planned',
                      color: const Color(0xFF0373F3),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToPlanViewScreen();
                      },
                    ),

                  // Combined Action
                  if (_detectedLocations.isNotEmpty &&
                      _detectedItinerary.isNotEmpty)
                    _buildQuickActionTile(
                      icon: Icons.explore,
                      title: 'Plan & Explore',
                      subtitle: 'View both itinerary and map',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _showCombinedView();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action tile
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: appTheme.whiteCustom,
                size: 24.h,
              ),
            ),
            SizedBox(width: 16.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.blackCustom,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.fSize,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16.h,
            ),
          ],
        ),
      ),
    );
  }

  /// Show combined view (both itinerary and map)
  void _showCombinedView() {
    // For now, navigate to itinerary first, then user can access map from there
    _navigateToPlanViewScreen();

    // Show a snackbar to inform user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Viewing itinerary. Use the map button in the itinerary screen to see locations.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
