import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/safe_avatar_image.dart';
import '../../widgets/shared_chat_input.dart';

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
  bool _autoSend = false;
  bool _hasAutoSent = false;

  // Detected data from AI responses
  List<PlaceSearchResult> _detectedLocations = [];
  List<ItineraryDayModel> _detectedItinerary = [];

  // Lưu trạng thái plan trong session chat với AI Agent
  String? _lastPlanUuid;
  String? _lastPlanTitle;

  // Selected images from arguments
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      print('🔍 AI Chat Screen arguments: $args');

      // Handle selected images
      if (args['selectedImages'] != null) {
        final images = args['selectedImages'] as List<File>;
        setState(() {
          _selectedImages = images;
        });
        print('📷 Received ${images.length} selected images');
        for (int i = 0; i < images.length; i++) {
          print('   📄 Image $i: ${images[i].path}');
        }
      } else {
        print('⚠️ No selectedImages in arguments');
      }

      if (args['autoSend'] == true &&
          !_hasAutoSent &&
          (args['initialQuery'] != null || _selectedImages.isNotEmpty)) {
        _hasAutoSent = true;
        final query = args['initialQuery'] as String? ?? '';
        print(
            '📤 Auto-sending message: "$query" with ${_selectedImages.length} images');
        _sendMessage(query);
      }
    }
    if (_messages.isEmpty) {
      if (args != null && args['conversationHistory'] != null) {
        if (mounted) {
          setState(() {
            _messages = List<ChatMessage>.from(args['conversationHistory']);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _messages = [..._globalChatService.conversationHistory];
          });
        }
      }
    }
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
    if (message.isEmpty && _selectedImages.isEmpty) return;

    _messageController.clear();
    await _sendMessage(message);
  }

  /// Send message to AI
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty && _selectedImages.isEmpty) return;

    print(
        '💬 Sending message: "$message" with ${_selectedImages.length} images');

    // Convert File objects to file paths for ChatMessage
    List<String>? imagePaths;
    if (_selectedImages.isNotEmpty) {
      imagePaths = _selectedImages.map((file) => file.path).toList();
    }

    // If in mockup mode, don't make API calls
    if (widget.useMockupMode) {
      print('🧪 Mockup mode enabled - skipping API call');
      // Add user message to chat with images
      final userMessage = ChatMessage.fromUser(message, imagePaths: imagePaths);
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
    // Convert File objects to file paths for ChatMessage
    List<String>? imagePaths;
    if (_selectedImages.isNotEmpty) {
      imagePaths = _selectedImages.map((file) => file.path).toList();
    }

    final userMessage = ChatMessage.fromUser(message, imagePaths: imagePaths);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _scrollToBottom();
    await _getAIResponse(message);
  }

  /// Send message via global chat service
  Future<void> _sendMessageViaGlobalService(String message) async {
    print(
        '🚀 Sending message via global service: "$message" with ${_selectedImages.length} images');

    // Convert File objects to file paths
    List<String>? imagePaths;
    if (_selectedImages.isNotEmpty) {
      imagePaths = _selectedImages.map((file) => file.path).toList();
    }

    // Clear images after getting paths
    setState(() {
      _isTyping = true;
      _selectedImages.clear();
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
    }, imagePaths: imagePaths);

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
  Future<void> _analyzeResponse(String response,
      {List<Map<String, dynamic>>? functionResponses}) async {
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
    final bool hasItinerary =
        await AIResponseAnalyzer.hasItineraryPattern(response);
    print('   - Has itinerary pattern: $hasItinerary');

    // Check for location pattern
    final bool hasLocationList =
        await AIResponseAnalyzer.hasLocationListPattern(response);
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
        print('       Response type: ${(fr['response'] as Map).runtimeType}');
        if (fr['response'] is Map) {
          print(
              '       Response keys: ${(fr['response'] as Map).keys.toList()}');
        }
      }
    }

    // Handle response based on detected patterns
    bool hasHandledResponse = false;

    // Handle itinerary detection
    if (hasItinerary) {
      print('📅 Processing itinerary response...');
      _handleItineraryResponse(response);
      hasHandledResponse = true;
    }

    // Handle location detection (from both text and function responses)
    if (hasLocationList || hasMapTool || hasMapUrlInText || hasPoiAgent) {
      print('📍 Processing location response...');
      _handleLocationResponse(response, functionResponses);
      hasHandledResponse = true;
    }

    // If no specific patterns detected, use general analyzer as fallback
    if (!hasHandledResponse) {
      print('❓ No specific patterns detected, trying general analysis...');

      // Use new analyzer that handles both text and function responses
      final responseType =
          functionResponses != null && functionResponses.isNotEmpty
              ? await AIResponseAnalyzer.analyzeResponseWithFunctions(
                  response, functionResponses)
              : await AIResponseAnalyzer.analyzeResponse(response);

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
      String response, List<Map<String, dynamic>>? functionResponses) async {
    final locations = await AIResponseAnalyzer.extractLocationResults(
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
  void _handleItineraryResponse(String response) async {
    final itinerary =
        await AIResponseAnalyzer.extractItineraryWithFallback(response);

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
        print('     [${j}] ${activity.timeSlot}: ${activity.title}');
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
  Future<void> _navigateToPlanViewScreen() async {
    if (_detectedItinerary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No itinerary available to display'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Lấy title plan hiện tại (ví dụ: từ ngày đầu tiên hoặc logic bạn muốn)
    final String currentTitle = _detectedItinerary.first.activities.isNotEmpty
        ? _detectedItinerary.first.activities.first.title
        : 'AI Plan';
    final TravelConciergeService travelService = TravelConciergeService();
    String? planUuidToUse;
    // Nếu chưa có plan hoặc title khác thì tạo mới
    if (_lastPlanUuid == null || _lastPlanTitle != currentTitle) {
      final (success, message) =
          await travelService.createPlan(_detectedItinerary);
      if (success) {
        // Lấy plan_uuid từ response body nếu có
        final uuid =
            RegExp(r'plan_uuid[":\s]*([\w-]+)').firstMatch(message)?.group(1);
        if (uuid != null) {
          _lastPlanUuid = uuid;
          _lastPlanTitle = currentTitle;
          planUuidToUse = uuid;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Create plan failed: $message')),
        );
        return;
      }
    } else {
      // Nếu title giống, update plan
      final (success, message) =
          await travelService.updatePlan(_lastPlanUuid!, _detectedItinerary);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update plan failed: $message')),
        );
        return;
      }
      planUuidToUse = _lastPlanUuid;
    }
    // Điều hướng sang Plan View, truyền plan_uuid
    Navigator.pushNamed(
      context,
      AppRoutes.planViewScreen,
      arguments: {
        'itinerary': _detectedItinerary,
        'plan_uuid': planUuidToUse,
        'source': 'ai_chat',
      },
    );
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
          ],
        ),
      ),
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
                  // Display images if present
                  if (message.hasImages) ...[
                    _buildMessageImages(message.imagePaths!),
                    if (message.text.isNotEmpty) SizedBox(height: 8.h),
                  ],

                  // Display text if present
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: isUser
                            ? appTheme.whiteCustom
                            : appTheme.blackCustom,
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
      child: SharedChatInput(
        textController: _messageController,
        hintText: "Type your message...",
        selectedImages: _selectedImages,
        isEnabled: !_isTyping,
        showVoiceButton: false, // Disable voice button in AI chat
        onSend: (message) => _sendMessageFromInput(),
        onImagesSelected: (images) {
          setState(() {
            _selectedImages = images;
          });
        },
      ),
    );
  }





  /// Build images display in message
  Widget _buildMessageImages(List<String> imagePaths) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250.h),
      child: Wrap(
        spacing: 4.h,
        runSpacing: 4.h,
        children: imagePaths.map((imagePath) {
          return Container(
            width: 60.h,
            height: 60.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.h),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.h),
              child: GestureDetector(
                onTap: () => _showImagePreview(imagePath),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 24.h,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Show image preview in dialog
  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.h),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 48.h,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 20.h,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40.h,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24.h,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
