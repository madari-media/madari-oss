import 'package:flutter/material.dart';

class ChatEmpty extends StatefulWidget {
  final Function(String input) handleSubmit;

  const ChatEmpty({
    super.key,
    required this.handleSubmit,
  });

  @override
  State<ChatEmpty> createState() => _ChatEmptyState();
}

class _ChatEmptyState extends State<ChatEmpty> {
  @override
  Widget build(BuildContext context) {
    final suggestions = [
      "📚 How to create a study schedule?",
      "🧠 Best memory techniques for exams",
      "⏰ Time management tips for exam prep",
      "📝 Practice test strategies",
      "📱 Best study apps and tools",
      "🎯 How to stay focused while studying",
      "💡 Active recall techniques",
      "📊 Spaced repetition methods",
      "🌟 Exam day preparation tips",
      "✍️ Note-taking strategies",
      "🧘‍♂️ Study break activities",
      "👥 Group study benefits",
    ];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? Colors.blue[400]! : Theme.of(context).primaryColor;

    return Center(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated gradient container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.3),
                        primaryColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'How can I help you today?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : primaryColor,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a suggestion or type your own question',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 100,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggestions
                                .sublist(0, suggestions.length ~/ 2)
                                .map((suggestion) => Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _buildSuggestionChip(
                                        suggestion,
                                        isDarkMode: isDarkMode,
                                        primaryColor: primaryColor,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggestions
                                .sublist(suggestions.length ~/ 2)
                                .map((suggestion) => Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _buildSuggestionChip(
                                        suggestion,
                                        isDarkMode: isDarkMode,
                                        primaryColor: primaryColor,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
    String suggestion, {
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.handleSubmit(suggestion),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                isDarkMode ? Colors.grey[850]! : Theme.of(context).cardColor,
                isDarkMode
                    ? Colors.grey[900]!
                    : Theme.of(context).cardColor.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey[800]!
                  : primaryColor.withOpacity(0.1),
            ),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
