import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65, // Max width is 65% of screen width
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF467BA1).withOpacity(0.2),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: null,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
