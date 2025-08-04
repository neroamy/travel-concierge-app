import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart'; // Audio recording functionality
import 'package:audioplayers/audioplayers.dart'; // Audio playback functionality
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'environment_config.dart';

/// Events emitted by VoiceChatService
abstract class VoiceChatEvent {
  const VoiceChatEvent();
}

class VoiceChatConnectedEvent extends VoiceChatEvent {
  final Map<String, dynamic> serverConfig;
  const VoiceChatConnectedEvent(this.serverConfig);
}

class VoiceChatDisconnectedEvent extends VoiceChatEvent {
  const VoiceChatDisconnectedEvent();
}

class VoiceChatSessionStartedEvent extends VoiceChatEvent {
  final String sessionId;
  final String userId;
  const VoiceChatSessionStartedEvent(this.sessionId, this.userId);
}

class VoiceChatSessionStoppedEvent extends VoiceChatEvent {
  final String sessionId;
  const VoiceChatSessionStoppedEvent(this.sessionId);
}

class VoiceChatRecordingStartedEvent extends VoiceChatEvent {
  const VoiceChatRecordingStartedEvent();
}

class VoiceChatRecordingStoppedEvent extends VoiceChatEvent {
  const VoiceChatRecordingStoppedEvent();
}

class VoiceChatAudioResponseEvent extends VoiceChatEvent {
  final Uint8List audioData;
  const VoiceChatAudioResponseEvent(this.audioData);
}

class VoiceChatTextResponseEvent extends VoiceChatEvent {
  final String text;
  const VoiceChatTextResponseEvent(this.text);
}

class VoiceChatTurnCompleteEvent extends VoiceChatEvent {
  const VoiceChatTurnCompleteEvent();
}

class VoiceChatInterruptedEvent extends VoiceChatEvent {
  const VoiceChatInterruptedEvent();
}

class VoiceChatErrorEvent extends VoiceChatEvent {
  final String message;
  const VoiceChatErrorEvent(this.message);
}

class VoiceChatSessionErrorEvent extends VoiceChatEvent {
  final String errorType;
  final String message;
  final bool requiresServerSetup;
  const VoiceChatSessionErrorEvent(
      this.errorType, this.message, this.requiresServerSetup);
}

class VoiceChatAdkErrorEvent extends VoiceChatEvent {
  final String error;
  const VoiceChatAdkErrorEvent(this.error);
}

/// Status of the voice chat service
enum VoiceChatStatus {
  disconnected,
  connecting,
  connected,
  sessionActive,
  recording,
  processing,
  playing,
  error,
}

/// Voice Chat Service for real-time communication with AI Agent
/// Updated for automatic session management and simplified flow
class VoiceChatService {
  static final VoiceChatService _instance = VoiceChatService._internal();
  factory VoiceChatService() => _instance;
  VoiceChatService._internal();

  // WebSocket configuration - Uses environment config for unified voice server
  // No subprotocol needed for unified server

  // Audio configuration - optimized for ADK Live API
  static const int _inputSampleRate = 16000;
  static const int _outputSampleRate = 24000;
  static const int _chunkSize = 1600; // 100ms of 16kHz audio (160 samples * 10)
  static const Duration _streamingInterval = Duration(milliseconds: 150);

  // Service state
  VoiceChatStatus _status = VoiceChatStatus.disconnected;
  WebSocketChannel? _channel;
  StreamController<VoiceChatEvent> _eventController =
      StreamController.broadcast();

  // Audio components
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  // Audio queue management
  final Queue<Uint8List> _audioQueue = Queue<Uint8List>();
  bool _isProcessingAudioQueue = false;
  StreamSubscription<void>? _playerCompleteSubscription;

  // Session data (auto-managed by server)
  String? _sessionId;
  String? _userId;
  Map<String, dynamic>? _serverConfig;
  bool _hasAutoSession = false;

  // Audio state
  bool _isRecording = false;
  bool _isPlaying = false;

  // Getters
  VoiceChatStatus get status => _status;
  Stream<VoiceChatEvent> get eventStream => _eventController.stream;
  String? get sessionId => _sessionId;
  String? get userId => _userId;
  bool get isConnected =>
      _status != VoiceChatStatus.disconnected &&
      _status != VoiceChatStatus.error;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  /// Initialize the voice chat service with auto-session
  Future<bool> initialize() async {
    try {
      debugPrint('🎤 Initializing VoiceChatService with auto-session...');

      // Recreate event controller if closed
      if (_eventController.isClosed) {
        _eventController = StreamController.broadcast();
      }

      // Initialize audio components
      _recorder = AudioRecorder();
      _player = AudioPlayer();

      // Request microphone permission
      final permissionStatus = await _requestMicrophonePermission();
      if (!permissionStatus) {
        _emitEvent(VoiceChatErrorEvent('Microphone permission denied'));
        return false;
      }

      debugPrint('✅ VoiceChatService initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to initialize VoiceChatService: $e');
      _emitEvent(VoiceChatErrorEvent('Initialization failed: $e'));
      return false;
    }
  }

  /// Connect to the WebSocket server with automatic session
  Future<bool> connect() async {
    if (_status == VoiceChatStatus.connected ||
        _status == VoiceChatStatus.connecting) {
      return true;
    }

    try {
      _setStatus(VoiceChatStatus.connecting);
      
      // Get voice chat URL from environment config
      final url = EnvironmentConfig.currentVoiceChatUrl;
      debugPrint('🔌 Connecting to voice chat server with auto-session: $url');

      // Create WebSocket connection - no subprotocol for unified server
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Listen for messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketClose,
      );

      // Wait for connection to be established
      await _waitForConnection();

      _setStatus(VoiceChatStatus.sessionActive);
      debugPrint('✅ Connected with unified server ready');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to connect with auto-session: $e');
      _setStatus(VoiceChatStatus.error);
      _emitEvent(VoiceChatErrorEvent('Connection failed: $e'));
      return false;
    }
  }

  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    try {
      debugPrint('🔌 Disconnecting from voice chat server...');

      // Stop recording if active
      if (_isRecording) {
        await stopRecording();
      }

      // Close WebSocket (auto-session will be cleaned up by server)
      await _channel?.sink.close();
      _channel = null;

      // Reset session data
      _sessionId = null;
      _userId = null;
      _hasAutoSession = false;

      _setStatus(VoiceChatStatus.disconnected);
      _emitEvent(VoiceChatDisconnectedEvent());

      debugPrint('✅ Disconnected from voice chat server');
    } catch (e) {
      debugPrint('❌ Error during disconnect: $e');
    }
  }

  /// Start recording audio (session managed by unified server)
  Future<bool> startRecording() async {
    if (!isConnected) {
      _emitEvent(VoiceChatErrorEvent('Not connected to server'));
      return false;
    }

    if (_isRecording) {
      return true;
    }

    try {
      debugPrint('🎙️ Starting audio recording with auto-session...');

      // Configure recording for real-time streaming
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _inputSampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      // Start recording stream for real-time processing
      final stream = await _recorder!.startStream(config);

      // Listen to audio chunks and send to server
      stream.listen((audioChunk) {
        if (_isRecording && isConnected && audioChunk.isNotEmpty) {
          // Filter out very quiet audio chunks to reduce server load
          if (_hasSignificantAudio(audioChunk)) {
            _sendAudioChunkToServer(audioChunk);
          }
        }
      });

      _isRecording = true;
      _setStatus(VoiceChatStatus.recording);
      _emitEvent(VoiceChatRecordingStartedEvent());

      debugPrint('✅ Real audio recording started with unified server');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      _emitEvent(VoiceChatErrorEvent('Failed to start recording: $e'));
      return false;
    }
  }

  /// Stop recording audio
  Future<bool> stopRecording() async {
    if (!_isRecording) {
      return true;
    }

    try {
      debugPrint('🛑 Stopping audio recording...');

      // Stop recording
      await _recorder!.stop();

      _isRecording = false;
      _setStatus(VoiceChatStatus.processing);
      _emitEvent(VoiceChatRecordingStoppedEvent());

      debugPrint('✅ Audio recording stopped');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      _emitEvent(VoiceChatErrorEvent('Failed to stop recording: $e'));
      return false;
    }
  }

  /// Queue audio response for playback
  Future<void> playAudioResponse(Uint8List audioData) async {
    debugPrint('📥 Queuing audio response: ${audioData.length} bytes');

    // Add to queue
    _audioQueue.add(audioData);

    // Start processing queue if not already processing
    if (!_isProcessingAudioQueue) {
      _processAudioQueue();
    }
  }

  /// Process audio queue sequentially
  Future<void> _processAudioQueue() async {
    if (_audioQueue.isEmpty || _isProcessingAudioQueue) {
      return;
    }

    _isProcessingAudioQueue = true;

    while (_audioQueue.isNotEmpty) {
      final audioData = _audioQueue.removeFirst();
      await _playAudioChunk(audioData);
    }

    _isProcessingAudioQueue = false;
  }

  /// Play single audio chunk
  Future<void> _playAudioChunk(Uint8List audioData) async {
    try {
      debugPrint('🔊 Playing audio chunk: ${audioData.length} bytes');

      _isPlaying = true;
      _setStatus(VoiceChatStatus.playing);

      // Cancel previous player complete subscription
      await _playerCompleteSubscription?.cancel();

      // Stop and reset player if currently playing
      try {
        await _player!.stop();
      } catch (e) {
        debugPrint('⚠️ Player stop error (expected): $e');
      }

      // Create audio file with WAV format
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/voice_response_${DateTime.now().millisecondsSinceEpoch}.wav');

      // Create WAV file
      final wavData = _createWavFile(audioData, _outputSampleRate);
      await tempFile.writeAsBytes(wavData);

      // Set up completion listener
      final completer = Completer<void>();
      _playerCompleteSubscription = _player!.onPlayerComplete.listen((_) {
        _isPlaying = false;
        if (_hasAutoSession) {
          _setStatus(VoiceChatStatus.sessionActive);
        } else {
          _setStatus(VoiceChatStatus.connected);
        }

        // Clean up temp file
        tempFile.delete().catchError((e) {
          debugPrint('❌ Failed to delete temp file: $e');
        });

        debugPrint('✅ Audio playback completed');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Play audio file
      await _player!.play(DeviceFileSource(tempFile.path));

      // Wait for completion
      await completer.future;
    } catch (e) {
      debugPrint('❌ Failed to play audio chunk: $e');
      _isPlaying = false;
      _emitEvent(VoiceChatErrorEvent('Failed to play audio: $e'));
    }
  }

  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    try {
      var status = await Permission.microphone.status;

      if (status == PermissionStatus.granted) {
        return true;
      }

      if (status == PermissionStatus.denied) {
        status = await Permission.microphone.request();
      }

      if (status == PermissionStatus.permanentlyDenied) {
        await openAppSettings();
        return false;
      }

      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Send audio chunk to server as binary data (as per design document)
  void _sendAudioChunkToServer(Uint8List audioChunk) {
    try {
      // Send raw binary audio data as per design document section 4.3
      // The unified server expects direct binary PCM data
      _channel!.sink.add(audioChunk);

      debugPrint('📤 Sent binary audio chunk: ${audioChunk.length} bytes');
    } catch (e) {
      debugPrint('❌ Failed to send audio chunk: $e');
    }
  }

  /// Check if audio chunk has significant audio signal
  bool _hasSignificantAudio(Uint8List audioData) {
    if (audioData.isEmpty) return false;

    // Calculate RMS of audio data
    double sum = 0;
    for (int i = 0; i < audioData.length; i += 2) {
      if (i + 1 < audioData.length) {
        int sample = (audioData[i + 1] << 8) | audioData[i];
        if (sample > 32767) sample -= 65536;
        sum += sample * sample;
      }
    }

    double rms = sum > 0 ? (sum / (audioData.length / 2)).abs() : 0;
    double amplitude = rms > 0 ? (rms / (32767 * 32767)) : 0;

    const double silenceThreshold = 0.001;
    return amplitude > silenceThreshold;
  }

  /// Handle WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        _handleJsonMessage(data);
      } else {
        debugPrint('📥 Received unknown message type: ${message.runtimeType}');
      }
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
      _emitEvent(VoiceChatErrorEvent('Message handling error: $e'));
    }
  }

  /// Handle JSON messages from unified server
  void _handleJsonMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'connected':
        // Handle unified server connection confirmation
        final messageData = data['data'] as Map<String, dynamic>?;
        _sessionId = messageData?['session_id'] as String?;
        _userId = 'flutter_client';
        _hasAutoSession = true;
        _serverConfig = messageData;
        
        _emitEvent(VoiceChatConnectedEvent(data));
        _emitEvent(VoiceChatSessionStartedEvent(_sessionId ?? 'unified_session', _userId!));
        debugPrint('🎯 Unified server connected: $_sessionId');
        break;

      case 'transcript':
        // Handle text transcript from unified server
        final text = data['data'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          _emitEvent(VoiceChatTextResponseEvent(text));
          debugPrint('📝 Received transcript: $text');
        }
        break;

      case 'audio_chunk':
        // Handle audio chunk from unified server
        final audioBase64 = data['data'] as String?;
        if (audioBase64 != null) {
          final audioData = base64Decode(audioBase64);
          _emitEvent(VoiceChatAudioResponseEvent(audioData));
          playAudioResponse(audioData);
          debugPrint('🔊 Received audio chunk: ${audioData.length} bytes');
        }
        break;

      case 'turn_complete':
        // Handle turn completion from unified server
        _emitEvent(VoiceChatTurnCompleteEvent());
        _setStatus(VoiceChatStatus.sessionActive);
        debugPrint('✅ Turn completed');
        break;

      case 'interrupted':
        // Handle interruption from unified server
        _emitEvent(VoiceChatInterruptedEvent());
        debugPrint('🤐 Conversation interrupted');
        break;

      case 'error':
        // Handle error from unified server
        final errorData = data['data'] as Map<String, dynamic>?;
        final errorMessage = errorData?['error_message'] as String? ?? 
                            data['message'] as String? ?? 
                            'Unknown error';
        debugPrint('❌ Server error: $errorMessage');
        _emitEvent(VoiceChatErrorEvent(errorMessage));
        _setStatus(VoiceChatStatus.error);
        break;

      default:
        debugPrint('⚠️ Unknown message type: $type');
        debugPrint('📄 Message data: $data');
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    debugPrint('❌ WebSocket error: $error');
    _setStatus(VoiceChatStatus.error);
    _emitEvent(VoiceChatErrorEvent('Connection error: $error'));
  }

  /// Handle WebSocket close
  void _handleWebSocketClose() {
    debugPrint('🔌 WebSocket connection closed');
    _setStatus(VoiceChatStatus.disconnected);
    _hasAutoSession = false;
    _emitEvent(VoiceChatDisconnectedEvent());
  }

  /// Wait for connection to unified server
  Future<void> _waitForConnection() async {
    final completer = Completer<void>();

    StreamSubscription? subscription;
    subscription = eventStream.listen((event) {
      if (event is VoiceChatConnectedEvent) {
        // Unified server establishes connection immediately
        subscription?.cancel();
        completer.complete();
      } else if (event is VoiceChatSessionStartedEvent) {
        // Session is auto-created by unified server
        subscription?.cancel();
        completer.complete();
      } else if (event is VoiceChatErrorEvent) {
        subscription?.cancel();
        completer.completeError(event.message);
      }
    });

    // Timeout after 10 seconds (unified server is faster)
    Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.completeError('Connection timeout');
      }
    });

    return completer.future;
  }


  /// Create WAV file from PCM data
  Uint8List _createWavFile(Uint8List pcmData, int sampleRate) {
    if (pcmData.isEmpty) {
      throw ArgumentError('PCM data cannot be empty');
    }

    final alignedData =
        pcmData.length % 2 == 0 ? pcmData : Uint8List.fromList([...pcmData, 0]);
    final channels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;

    final header = BytesBuilder();

    // RIFF header
    header.add('RIFF'.codeUnits);
    header.add(_int32ToBytes(36 + alignedData.length));
    header.add('WAVE'.codeUnits);

    // fmt subchunk
    header.add('fmt '.codeUnits);
    header.add(_int32ToBytes(16));
    header.add(_int16ToBytes(1));
    header.add(_int16ToBytes(channels));
    header.add(_int32ToBytes(sampleRate));
    header.add(_int32ToBytes(byteRate));
    header.add(_int16ToBytes(blockAlign));
    header.add(_int16ToBytes(bitsPerSample));

    // data subchunk
    header.add('data'.codeUnits);
    header.add(_int32ToBytes(alignedData.length));

    return Uint8List.fromList(header.toBytes() + alignedData);
  }

  /// Convert int32 to little-endian bytes
  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Convert int16 to little-endian bytes
  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  /// Set status and notify listeners
  void _setStatus(VoiceChatStatus status) {
    _status = status;
    debugPrint('📊 VoiceChatService status: ${status.name}');
  }

  /// Emit event to listeners
  void _emitEvent(VoiceChatEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();

    // Clear audio queue
    _audioQueue.clear();
    _isProcessingAudioQueue = false;

    // Cancel subscriptions
    _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;

    // Dispose audio components
    _recorder?.dispose();
    _player?.dispose();

    // Close controllers
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }

  // Legacy methods for compatibility (now handled automatically)
  @deprecated
  Future<bool> startSession(String userId) async {
    // Auto-session is handled by server, this is a no-op for compatibility
    return _hasAutoSession;
  }

  @deprecated
  Future<bool> stopSession() async {
    // Auto-session cleanup is handled by server
    return true;
  }
}
