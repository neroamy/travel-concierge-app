import 'dart:async';
import '../models/api_models.dart';
import 'travel_concierge_service.dart';
import 'profile_service.dart';

class GlobalChatService {
  static final GlobalChatService _instance = GlobalChatService._internal();
  factory GlobalChatService() => _instance;
  GlobalChatService._internal();

  final TravelConciergeService _travelService = TravelConciergeService();
  final ProfileService _profileService = ProfileService();
  final List<ChatMessage> _conversationHistory = [];
  bool _isSessionInitialized = false;
  SearchResult?
      _lastSearchResult; // Store last API result with function responses

  /// Get current conversation history
  List<ChatMessage> get conversationHistory => List.from(_conversationHistory);

  /// Check if session is initialized
  bool get isSessionInitialized => _isSessionInitialized;

  /// Initialize session if not already initialized
  Future<bool> ensureSessionInitialized() async {
    if (!_isSessionInitialized) {
      final success = await _travelService.initializeSession();
      _isSessionInitialized = success;
      if (success) {
        print('✅ Global chat session initialized successfully');
      } else {
        print('❌ Failed to initialize global chat session');
      }
      return success;
    }
    return true; // Already initialized
  }

  /// Add message to conversation history
  void addMessageToHistory(ChatMessage message) {
    _conversationHistory.add(message);
    print(
        '💬 Added message to global chat history. Total messages: ${_conversationHistory.length}');
  }

  /// Send message and get AI response
  Future<void> sendMessage(
      String message, Function(ChatMessage) onMessageReceived,
      {List<String>? imagePaths}) async {
    print(
        '🌐 GlobalChatService: Starting sendMessage for: "$message" with ${imagePaths?.length ?? 0} images');

    if (!await ensureSessionInitialized()) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Failed to initialize chat session. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
        isFromUser: false,
      );
      addMessageToHistory(errorMessage);
      onMessageReceived(errorMessage);
      return;
    }

    // Add user message to history with images
    print(
        '👤 Adding user message to history with ${imagePaths?.length ?? 0} images');
    final userMessage = ChatMessage.fromUser(message, imagePaths: imagePaths);
    addMessageToHistory(userMessage);
    onMessageReceived(userMessage);

    try {
      print('🔄 Starting stream from travel service...');
      bool receivedAIResponse = false;
      String accumulatedText = '';
      List<Map<String, dynamic>> allFunctionResponses = [];
      String? lastAuthor;

      await for (final result in _travelService.searchTravel(message, imagePaths: imagePaths)) {
        print('📡 Received stream result:');
        print('   - Author: ${result.author}');
        print('   - Text length: ${result.text.length}');
        print(
            '   - Text preview: ${result.text.length > 100 ? result.text.substring(0, 100) + "..." : result.text}');

        if (result.author != 'system' && result.author != 'user') {
          // This is an AI response - accumulate all parts
          print('🤖 Processing AI response part...');

          // Accumulate text (skip system indicators)
          if (!result.text.startsWith('🏝️') &&
              !result.text.startsWith('📍') &&
              !result.text.startsWith('✈️') &&
              !result.text.startsWith('🏨') &&
              !result.text.startsWith('📅') &&
              !result.text.startsWith('🌤️')) {
            if (accumulatedText.isNotEmpty && result.text.trim().isNotEmpty) {
              accumulatedText += '\n\n' + result.text;
            } else if (result.text.trim().isNotEmpty) {
              accumulatedText = result.text;
            }
          }

          // Accumulate function responses
          if (result.functionResponses != null &&
              result.functionResponses!.isNotEmpty) {
            allFunctionResponses.addAll(result.functionResponses!);
            print(
                '📦 Added ${result.functionResponses!.length} function responses. Total: ${allFunctionResponses.length}');
          }

          lastAuthor = result.author;
          receivedAIResponse = true;

          // Continue to collect more parts instead of breaking
        } else if (result.author == 'system') {
          // Handle system messages (including function responses)
          print('🔧 Processing system message: ${result.text}');

          // Accumulate function responses from system messages
          if (result.functionResponses != null &&
              result.functionResponses!.isNotEmpty) {
            allFunctionResponses.addAll(result.functionResponses!);
            print(
                '📦 Added ${result.functionResponses!.length} function responses from system message. Total: ${allFunctionResponses.length}');
          }

          // Mark that we received a response (even if it's a system message)
          receivedAIResponse = true;
        } else {
          print('⚠️ Skipping non-AI message: ${result.author}');
        }
      }

      // Process accumulated response after stream ends
      if (receivedAIResponse && accumulatedText.isNotEmpty) {
        print('🎯 Processing accumulated AI response:');
        print('   - Total text length: ${accumulatedText.length}');
        print('   - Total function responses: ${allFunctionResponses.length}');

        // Create final search result with all accumulated data
        _lastSearchResult = SearchResult(
          text: accumulatedText,
          author: lastAuthor ?? 'agent',
          timestamp: DateTime.now(),
          functionResponses: allFunctionResponses,
        );

        final aiMessage =
            ChatMessage.fromApiResponse(accumulatedText, lastAuthor ?? 'agent');

        print('📨 Created final AI message:');
        print('   - ID: ${aiMessage.id}');
        print('   - Author: ${aiMessage.author}');
        print('   - Text length: ${aiMessage.text.length}');
        print('   - Function responses: ${allFunctionResponses.length}');

        addMessageToHistory(aiMessage);
        onMessageReceived(aiMessage);
      } else if (!receivedAIResponse) {
        print('❌ No AI response received from stream');
      }
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Connection error. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
        isFromUser: false,
      );
      addMessageToHistory(errorMessage);
      onMessageReceived(errorMessage);
      print('Global chat error: $e');
    }

    print('✅ GlobalChatService: sendMessage completed');
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    print('🗑️ Cleared global chat history');
  }

  /// Reset session (for testing or logout)
  void resetSession() {
    _isSessionInitialized = false;
    _conversationHistory.clear();
    print('🔄 Reset global chat session');
  }

  /// Get user display name from profile
  String getUserDisplayName() {
    return _profileService.getDisplayName();
  }

  /// Get user avatar URL from profile
  String? getUserAvatarUrl() {
    return _profileService.getAvatarUrl();
  }

  /// Update user info for chat display
  Future<void> updateUserInfo({
    String? displayName,
    String? avatarUrl,
  }) async {
    // This method will be used to update user info when auth changes
    // The actual display will use ProfileService data
    print('🔄 User info updated for chat: $displayName');
  }

  /// Clear session (for logout)
  Future<void> clearSession() async {
    _isSessionInitialized = false;
    _conversationHistory.clear();
    print('🗑️ Chat session cleared');
  }

  /// Update chat messages with current profile info
  void syncProfileData() {
    // Update existing user messages to use current profile data
    for (var message in _conversationHistory) {
      if (message.isFromUser) {
        // The message display will use current profile data
        // No need to modify the message itself
      }
    }
    print('🔄 Synced chat with profile data: ${getUserDisplayName()}');
  }

  /// Get last search result with function responses
  SearchResult? getLastSearchResult() {
    return _lastSearchResult;
  }
}
