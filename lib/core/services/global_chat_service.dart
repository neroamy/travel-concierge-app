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
      String message, Function(ChatMessage) onMessageReceived) async {
    if (!await ensureSessionInitialized()) {
      onMessageReceived(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Failed to initialize chat session. Please try again.',
        author: 'system',
        timestamp: DateTime.now(),
        isFromUser: false,
      ));
      return;
    }

    // Add user message to history
    final userMessage = ChatMessage.fromUser(message);
    addMessageToHistory(userMessage);
    onMessageReceived(userMessage);

    try {
      await for (final result in _travelService.searchTravel(message)) {
        if (result.author != 'system' && result.author != 'user') {
          // This is the AI response
          final aiMessage =
              ChatMessage.fromApiResponse(result.text, result.author);
          addMessageToHistory(aiMessage);
          onMessageReceived(aiMessage);
          break; // Take the first AI response
        }
      }
    } catch (e) {
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
}
