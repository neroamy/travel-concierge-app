import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../widgets/safe_avatar_image.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TravelConciergeService _travelService = TravelConciergeService();
  final GlobalChatService _globalChatService = GlobalChatService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  String? _initialQuery;
  List<PlaceSearchResult> _detectedLocations = [];
  bool _useGlobalSession = false;

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

  /// Initialize chat with arguments from navigation
  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _initialQuery = args['initialQuery'] as String?;
        _useGlobalSession = args['useGlobalSession'] as bool? ?? false;
        final conversationHistory =
            args['conversationHistory'] as List<ChatMessage>?;

        if (_useGlobalSession) {
          // Use global chat service for session management
          setState(() {
            _messages = [..._globalChatService.conversationHistory];
          });
          print('🔄 Loaded ${_messages.length} messages from global session');
        } else if (conversationHistory != null) {
          setState(() {
            _messages = [...conversationHistory];
          });
        }

        // Start conversation with initial query if provided
        if (_initialQuery != null && _initialQuery!.isNotEmpty) {
          if (_useGlobalSession) {
            _sendMessageViaGlobalService(_initialQuery!);
          } else {
            _sendInitialMessage(_initialQuery!);
          }
        }
      }
    });
  }

  /// Send initial message and get AI response
  void _sendInitialMessage(String message) async {
    // Add user message
    final userMessage = ChatMessage.fromUser(message);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _scrollToBottom();
    await _getAIResponse(message);
  }

  /// Send message to AI and handle response
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    if (_useGlobalSession) {
      await _sendMessageViaGlobalService(message);
    } else {
      // Add user message
      final userMessage = ChatMessage.fromUser(message);
      setState(() {
        _messages.add(userMessage);
        _isTyping = true;
      });

      _scrollToBottom();
      await _getAIResponse(message);
    }
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

  /// Analyze AI response for location results
  void _analyzeResponse(String response,
      {List<Map<String, dynamic>>? functionResponses}) {
    print('🔍 Analyzing response for locations...');
    print('   - Response text length: ${response.length}');
    print('   - Function responses count: ${functionResponses?.length ?? 0}');

    // Use new analyzer that handles both text and function responses
    final responseType =
        functionResponses != null && functionResponses.isNotEmpty
            ? AIResponseAnalyzer.analyzeResponseWithFunctions(
                response, functionResponses)
            : AIResponseAnalyzer.analyzeResponse(response);

    print('   - Response type: $responseType');

    if (responseType == AIResponseType.locationList) {
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
    } else {
      print('❌ No locations detected in response');
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
                Text(
                  _isTyping ? 'AI is typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                    color: _isTyping ? appTheme.colorFF0373 : Colors.green,
                  ),
                ),
              ],
            ),
          ),

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
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          SizedBox(width: 12.h),

          // Send Button
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
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
}
