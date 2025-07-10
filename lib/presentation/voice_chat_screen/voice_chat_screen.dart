import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceChatScreen extends StatelessWidget {
  const VoiceChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microphone icon with animated scale (pulse)
            Icon(
              Icons.mic,
              size: 96,
              color: Colors.blueAccent,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  duration: 1200.ms,
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 32),
            // Thinking animation (shimmer)
            Text(
              'Đang lắng nghe...\nHãy nói nội dung bạn muốn tìm kiếm',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ).animate().shimmer(
                  duration: 1800.ms,
                  color: Colors.blueAccent,
                ),
          ],
        ),
      ),
    );
  }
}
