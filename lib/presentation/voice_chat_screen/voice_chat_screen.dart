import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as dart_math;

import '../../core/app_export.dart';
import 'bloc/voice_chat_bloc.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({Key? key}) : super(key: key);

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late VoiceChatBloc _voiceChatBloc;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _voiceChatBloc = VoiceChatBloc();

    // Auto-initialize and connect immediately
    _voiceChatBloc.add(const InitializeVoiceChat());

    // Auto-connect after initialization
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _voiceChatBloc.add(const ConnectToServer());
      }
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Start thinking animation immediately
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();

    // Auto-cleanup when leaving screen
    _voiceChatBloc.add(const DisconnectFromServer());
    _voiceChatBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _voiceChatBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: BlocListener<VoiceChatBloc, VoiceChatState>(
          listener: (context, state) {
            _handleStateChanges(state);
          },
          child: SafeArea(
            child: BlocBuilder<VoiceChatBloc, VoiceChatState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: _buildMainContent(state),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleStateChanges(VoiceChatState state) {
    switch (state.status) {
      case VoiceChatStateStatus.recording:
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        break;
      case VoiceChatStateStatus.playing:
        _pulseController.repeat(reverse: true);
        _waveController.stop();
        break;
      case VoiceChatStateStatus.error:
        _pulseController.stop();
        _waveController.stop();
        _showErrorSnackBar(state.errorMessage ?? 'Có lỗi xảy ra');
        break;
      case VoiceChatStateStatus.sessionActive:
        // Keep animations running when session is active
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        break;
      default:
        // Keep subtle animation for thinking state
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
        break;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44.h,
              height: 44.h,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12.h,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
                size: 18.h,
              ),
            ),
          ),
          SizedBox(width: 16.h),
          Expanded(
            child: Text(
              'Đang nói chuyện với AI',
              style: TextStyle(
                fontSize: 20.h,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(VoiceChatState state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Avatar with thinking animation
          _buildAIAvatar(state),

          SizedBox(height: 32.h),

          // Thinking indicator
          _buildThinkingIndicator(state),

          SizedBox(height: 24.h),

          // Status text
          _buildStatusText(state),

          SizedBox(height: 48.h),

          // Voice visualizer
          _buildVoiceVisualizer(state),
        ],
      ),
    );
  }

  Widget _buildAIAvatar(VoiceChatState state) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isAIThinking(state) ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 120.h,
            height: 120.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  appTheme.colorFF0373,
                  appTheme.colorFF0373.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.colorFF0373.withOpacity(0.3),
                  blurRadius: _isAIThinking(state) ? 20.h : 10.h,
                  spreadRadius: _isAIThinking(state) ? 5.h : 0,
                ),
              ],
            ),
            child: Icon(
              _getAvatarIcon(state),
              color: Colors.white,
              size: 48.h,
            ),
          ),
        );
      },
    );
  }

  Widget _buildThinkingIndicator(VoiceChatState state) {
    if (!_isAIThinking(state)) {
      return SizedBox(height: 20.h);
    }

    return Container(
      height: 20.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              double delay = index * 0.2;
              double animationValue = (_waveAnimation.value + delay) % 1.0;
              double scale =
                  0.5 + (0.5 * (1 + sin(animationValue * 2 * pi)) / 2);

              return Container(
                width: 8.h,
                height: 8.h,
                margin: EdgeInsets.symmetric(horizontal: 3.h),
                decoration: BoxDecoration(
                  color: appTheme.colorFF0373.withOpacity(scale),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildStatusText(VoiceChatState state) {
    String statusText = _getStatusText(state);
    Color statusColor = _getStatusColor(state);

    return Text(
      statusText,
      style: TextStyle(
        fontSize: 16.h,
        fontWeight: FontWeight.w500,
        color: statusColor,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVoiceVisualizer(VoiceChatState state) {
    if (!state.isRecording && !state.isPlaying) {
      return SizedBox(height: 60.h);
    }

    return Container(
      height: 60.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isRecording) ..._buildRecordingWaves(),
          if (state.isPlaying) ..._buildPlayingIndicator(),
        ],
      ),
    );
  }

  List<Widget> _buildRecordingWaves() {
    return List.generate(7, (index) {
      return AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          double delay = index * 0.1;
          double animationValue = (_waveAnimation.value + delay) % 1.0;
          double height = 10.h + (40.h * animationValue);

          return Container(
            width: 4.h,
            height: height,
            margin: EdgeInsets.symmetric(horizontal: 2.h),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2.h),
            ),
          );
        },
      );
    });
  }

  List<Widget> _buildPlayingIndicator() {
    return [
      Icon(
        Icons.volume_up,
        color: Colors.purple,
        size: 24.h,
      ),
      SizedBox(width: 8.h),
      Text(
        'AI đang phản hồi...',
        style: TextStyle(
          fontSize: 14.h,
          color: Colors.purple,
          fontWeight: FontWeight.w500,
        ),
      ),
    ];
  }

  bool _isAIThinking(VoiceChatState state) {
    return state.status == VoiceChatStateStatus.initializing ||
        state.status == VoiceChatStateStatus.connecting ||
        state.status == VoiceChatStateStatus.sessionStarting ||
        state.status == VoiceChatStateStatus.processing ||
        state.isPlaying;
  }

  IconData _getAvatarIcon(VoiceChatState state) {
    if (state.isRecording) return Icons.mic;
    if (state.isPlaying) return Icons.volume_up;
    if (state.status == VoiceChatStateStatus.error) return Icons.error_outline;
    return Icons.smart_toy;
  }

  String _getStatusText(VoiceChatState state) {
    switch (state.status) {
      case VoiceChatStateStatus.initial:
        return 'Đang khởi tạo...';
      case VoiceChatStateStatus.initializing:
        return 'Đang kết nối với AI Agent...';
      case VoiceChatStateStatus.connecting:
        return 'Đang thiết lập kết nối...';
      case VoiceChatStateStatus.sessionStarting:
        return 'Đang khởi tạo phiên trò chuyện...';
      case VoiceChatStateStatus.sessionActive:
        return 'Sẵn sàng! Hãy nói để trò chuyện với AI';
      case VoiceChatStateStatus.recording:
        return 'Đang lắng nghe bạn nói...';
      case VoiceChatStateStatus.processing:
        return 'AI đang suy nghĩ...';
      case VoiceChatStateStatus.playing:
        return 'AI đang trả lời bạn';
      case VoiceChatStateStatus.error:
        return 'Có lỗi xảy ra: ${state.errorMessage ?? ""}';
      case VoiceChatStateStatus.disconnected:
        return 'Kết nối đã bị ngắt';
      default:
        return 'AI đang chuẩn bị...';
    }
  }

  Color _getStatusColor(VoiceChatState state) {
    switch (state.status) {
      case VoiceChatStateStatus.error:
        return Colors.red;
      case VoiceChatStateStatus.recording:
        return Colors.red;
      case VoiceChatStateStatus.sessionActive:
        return Colors.green;
      case VoiceChatStateStatus.playing:
        return Colors.purple;
      case VoiceChatStateStatus.processing:
        return appTheme.colorFF0373;
      default:
        return Colors.grey[600] ?? Colors.grey;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: () {
            _voiceChatBloc.add(const InitializeVoiceChat());
          },
        ),
      ),
    );
  }
}

// Helper function for sine wave animation
double sin(double value) {
  return dart_math.sin(value);
}

const double pi = dart_math.pi;
