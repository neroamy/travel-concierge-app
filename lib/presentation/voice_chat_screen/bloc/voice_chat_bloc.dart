import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/voice_chat_service.dart';

// BLoC Events (simplified for auto-session flow)
abstract class VoiceChatBlocEvent extends Equatable {
  const VoiceChatBlocEvent();

  @override
  List<Object?> get props => [];
}

class InitializeVoiceChat extends VoiceChatBlocEvent {
  const InitializeVoiceChat();
}

class ConnectToServer extends VoiceChatBlocEvent {
  const ConnectToServer();
}

class StartRecording extends VoiceChatBlocEvent {
  const StartRecording();
}

class StopRecording extends VoiceChatBlocEvent {
  const StopRecording();
}

class DisconnectFromServer extends VoiceChatBlocEvent {
  const DisconnectFromServer();
}

class ServiceEventReceived extends VoiceChatBlocEvent {
  final VoiceChatEvent serviceEvent;
  const ServiceEventReceived(this.serviceEvent);

  @override
  List<Object?> get props => [serviceEvent];
}

// BLoC State (simplified)
class VoiceChatState extends Equatable {
  final VoiceChatStateStatus status;
  final bool isInitialized;
  final bool isConnected;
  final bool hasActiveSession;
  final bool isRecording;
  final bool isPlaying;
  final String? sessionId;
  final String? userId;
  final String? errorMessage;
  final List<VoiceChatMessage> messages;
  final Map<String, dynamic>? serverConfig;

  const VoiceChatState({
    this.status = VoiceChatStateStatus.initial,
    this.isInitialized = false,
    this.isConnected = false,
    this.hasActiveSession = false,
    this.isRecording = false,
    this.isPlaying = false,
    this.sessionId,
    this.userId,
    this.errorMessage,
    this.messages = const [],
    this.serverConfig,
  });

  VoiceChatState copyWith({
    VoiceChatStateStatus? status,
    bool? isInitialized,
    bool? isConnected,
    bool? hasActiveSession,
    bool? isRecording,
    bool? isPlaying,
    String? sessionId,
    String? userId,
    String? errorMessage,
    List<VoiceChatMessage>? messages,
    Map<String, dynamic>? serverConfig,
  }) {
    return VoiceChatState(
      status: status ?? this.status,
      isInitialized: isInitialized ?? this.isInitialized,
      isConnected: isConnected ?? this.isConnected,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
      messages: messages ?? this.messages,
      serverConfig: serverConfig ?? this.serverConfig,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isInitialized,
        isConnected,
        hasActiveSession,
        isRecording,
        isPlaying,
        sessionId,
        userId,
        errorMessage,
        messages,
        serverConfig,
      ];
}

enum VoiceChatStateStatus {
  initial,
  initializing,
  ready,
  connecting,
  connected,
  sessionStarting,
  sessionActive,
  recording,
  processing,
  playing,
  error,
  disconnected,
}

// Message model for voice responses
class VoiceChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final VoiceChatMessageType type;

  const VoiceChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.type = VoiceChatMessageType.text,
  });

  @override
  List<Object?> get props => [id, text, isFromUser, timestamp, type];
}

enum VoiceChatMessageType {
  text,
  audio,
  system,
}

// Simplified BLoC for auto-session management
class VoiceChatBloc extends Bloc<VoiceChatBlocEvent, VoiceChatState> {
  final VoiceChatService _voiceChatService;
  StreamSubscription<VoiceChatEvent>? _serviceSubscription;
  Timer? _autoRecordingTimer;

  VoiceChatBloc({VoiceChatService? voiceChatService})
      : _voiceChatService = voiceChatService ?? VoiceChatService(),
        super(const VoiceChatState()) {
    // Register event handlers
    on<InitializeVoiceChat>(_onInitialize);
    on<ConnectToServer>(_onConnect);
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<DisconnectFromServer>(_onDisconnect);
    on<ServiceEventReceived>(_onServiceEventReceived);

    // Listen to service events
    _subscribeToServiceEvents();
  }

  void _subscribeToServiceEvents() {
    _serviceSubscription = _voiceChatService.eventStream.listen(
      (event) => add(ServiceEventReceived(event)),
    );
  }

  Future<void> _onInitialize(
    InitializeVoiceChat event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VoiceChatStateStatus.initializing));
      debugPrint('🎤 Initializing voice chat with auto-session...');

      final success = await _voiceChatService.initialize();

      if (success) {
        emit(state.copyWith(
          status: VoiceChatStateStatus.ready,
          isInitialized: true,
          errorMessage: null,
        ));
        debugPrint('✅ Voice chat initialized successfully');
      } else {
        emit(state.copyWith(
          status: VoiceChatStateStatus.error,
          errorMessage: 'Failed to initialize voice chat',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: 'Initialization error: $e',
      ));
    }
  }

  Future<void> _onConnect(
    ConnectToServer event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VoiceChatStateStatus.connecting));
      debugPrint('🔌 Connecting to voice chat server with auto-session...');

      final success = await _voiceChatService.connect();

      if (success) {
        // Server automatically creates session, so we'll be in sessionActive status
        debugPrint('✅ Connected to voice chat server with auto-session');
      } else {
        emit(state.copyWith(
          status: VoiceChatStateStatus.error,
          errorMessage: 'Failed to connect to server',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: 'Connection error: $e',
      ));
    }
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      debugPrint('🎙️ Starting recording...');

      final success = await _voiceChatService.startRecording();

      if (success) {
        emit(state.copyWith(
          status: VoiceChatStateStatus.recording,
          isRecording: true,
          errorMessage: null,
        ));
        debugPrint('✅ Recording started successfully');
      } else {
        emit(state.copyWith(
          status: VoiceChatStateStatus.error,
          errorMessage: 'Failed to start recording',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: 'Recording start error: $e',
      ));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      debugPrint('🛑 Stopping recording...');

      final success = await _voiceChatService.stopRecording();

      if (success) {
        emit(state.copyWith(
          status: VoiceChatStateStatus.processing,
          isRecording: false,
          errorMessage: null,
        ));
        debugPrint('✅ Recording stopped successfully');
      } else {
        emit(state.copyWith(
          status: VoiceChatStateStatus.error,
          errorMessage: 'Failed to stop recording',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: 'Recording stop error: $e',
      ));
    }
  }

  Future<void> _onDisconnect(
    DisconnectFromServer event,
    Emitter<VoiceChatState> emit,
  ) async {
    try {
      debugPrint('🔌 Disconnecting from server...');

      await _voiceChatService.disconnect();

      emit(state.copyWith(
        status: VoiceChatStateStatus.disconnected,
        isConnected: false,
        hasActiveSession: false,
        isRecording: false,
        isPlaying: false,
        sessionId: null,
        errorMessage: null,
      ));

      debugPrint('✅ Disconnected from server');
    } catch (e) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: 'Disconnect error: $e',
      ));
    }
  }

  void _onServiceEventReceived(
    ServiceEventReceived event,
    Emitter<VoiceChatState> emit,
  ) {
    final serviceEvent = event.serviceEvent;

    if (serviceEvent is VoiceChatConnectedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.connected,
        isConnected: true,
        serverConfig: serviceEvent.serverConfig,
      ));
    } else if (serviceEvent is VoiceChatDisconnectedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.disconnected,
        isConnected: false,
        hasActiveSession: false,
        isRecording: false,
        isPlaying: false,
      ));
    } else if (serviceEvent is VoiceChatSessionStartedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.sessionActive,
        hasActiveSession: true,
        isConnected: true,
        sessionId: serviceEvent.sessionId,
        userId: serviceEvent.userId,
      ));

      // Auto-start recording when session is active
      _scheduleAutoRecording();

      _addSystemMessage('Voice chat session ready. Start speaking!');
    } else if (serviceEvent is VoiceChatSessionStoppedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.connected,
        hasActiveSession: false,
        sessionId: null,
      ));
    } else if (serviceEvent is VoiceChatRecordingStartedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.recording,
        isRecording: true,
      ));
    } else if (serviceEvent is VoiceChatRecordingStoppedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.processing,
        isRecording: false,
      ));
    } else if (serviceEvent is VoiceChatAudioResponseEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.playing,
        isPlaying: true,
      ));
    } else if (serviceEvent is VoiceChatTextResponseEvent) {
      _addAIMessage(serviceEvent.text);

      emit(state.copyWith(
        status: VoiceChatStateStatus.sessionActive,
        isPlaying: false,
      ));
    } else if (serviceEvent is VoiceChatTurnCompleteEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.sessionActive,
        isPlaying: false,
      ));

      // Auto-start recording again for continuous conversation
      _scheduleAutoRecording();
    } else if (serviceEvent is VoiceChatInterruptedEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.sessionActive,
        isRecording: false,
        isPlaying: false,
      ));
      _addSystemMessage('Conversation interrupted');
    } else if (serviceEvent is VoiceChatErrorEvent) {
      emit(state.copyWith(
        status: VoiceChatStateStatus.error,
        errorMessage: serviceEvent.message,
      ));
    }
  }

  void _scheduleAutoRecording() {
    // Cancel any existing timer
    _autoRecordingTimer?.cancel();

    // Start recording after a short delay to allow UI to settle
    _autoRecordingTimer = Timer(const Duration(milliseconds: 500), () {
      if (state.hasActiveSession && !state.isRecording && !state.isPlaying) {
        add(const StartRecording());
      }
    });
  }

  void _addAIMessage(String text) {
    final message = VoiceChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      type: VoiceChatMessageType.text,
    );

    final updatedMessages = List<VoiceChatMessage>.from(state.messages)
      ..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  void _addSystemMessage(String text) {
    final message = VoiceChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      type: VoiceChatMessageType.system,
    );

    final updatedMessages = List<VoiceChatMessage>.from(state.messages)
      ..add(message);
    emit(state.copyWith(messages: updatedMessages));
  }

  @override
  Future<void> close() {
    _serviceSubscription?.cancel();
    _autoRecordingTimer?.cancel();
    _voiceChatService.dispose();
    return super.close();
  }

  // Legacy compatibility methods (deprecated)
  @deprecated
  void addOldEvent(dynamic event) {
    // No-op for backward compatibility
  }
}
