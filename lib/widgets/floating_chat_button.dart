import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../core/services/global_chat_service.dart';

class FloatingChatButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const FloatingChatButton({
    super.key,
    this.onPressed,
  });

  @override
  State<FloatingChatButton> createState() => _FloatingChatButtonState();
}

class _FloatingChatButtonState extends State<FloatingChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final GlobalChatService _globalChatService = GlobalChatService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Custom callback or default navigation
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      _navigateToChat();
    }
  }

  void _navigateToChat() {
    // Navigate to AI Chat Screen with existing conversation history
    Navigator.pushNamed(
      context,
      AppRoutes.aiChatScreen,
      arguments: {
        'conversationHistory': _globalChatService.conversationHistory,
        'useGlobalSession': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24.h,
      right: 24.h,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 56.h,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: appTheme.colorFF0373,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: appTheme.colorFF0373.withOpacity(0.3),
                        blurRadius: 12.h,
                        offset: Offset(0, 6.h),
                        spreadRadius: 2.h,
                      ),
                      BoxShadow(
                        color: appTheme.blackCustom.withOpacity(0.1),
                        blurRadius: 8.h,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Main chat icon
                      Center(
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: appTheme.whiteCustom,
                          size: 24.h,
                        ),
                      ),

                      // Notification badge (if there are unread messages)
                      if (_globalChatService.conversationHistory.isNotEmpty)
                        Positioned(
                          top: 8.h,
                          right: 8.h,
                          child: Container(
                            width: 8.h,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: appTheme.whiteCustom,
                                width: 1.h,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
