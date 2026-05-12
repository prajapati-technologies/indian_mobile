import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/local_explorer_provider.dart';
import '../../theme/app_theme.dart';

class AiGuideScreen extends StatefulWidget {
  const AiGuideScreen({super.key});

  @override
  State<AiGuideScreen> createState() => _AiGuideScreenState();
}

class _AiGuideScreenState extends State<AiGuideScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    'Best veg food near me',
    'Cheapest hotels nearby',
    'Nearest hospital',
    'Tourist places to visit',
    "Today's weather",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addAiMessage(
        '👋 Hi! I\'m your AI Local Guide. Ask me anything about places nearby — food, hotels, hospitals, tourist spots, and more!',
      );
    });
  }

  void _addAiMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    _scrollToBottom();
  }

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

  Future<void> _handleSend(String query) async {
    if (query.trim().isEmpty) return;

    _addUserMessage(query);
    _messageController.clear();
    setState(() => _isLoading = true);

    final provider = context.read<LocalExplorerProvider>();

    if (provider.nearbyPlaces.isEmpty) {
      await provider.searchNearby('');
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final response = _generateResponse(query, provider);
    setState(() => _isLoading = false);
    _addAiMessage(response);
  }

  String _generateResponse(String query, LocalExplorerProvider provider) {
    final lowerQuery = query.toLowerCase();
    final places = provider.nearbyPlaces;
    final famous = provider.famousPlaces;

    if (lowerQuery.contains('food') || lowerQuery.contains('veg') || lowerQuery.contains('restaurant') || lowerQuery.contains('eat')) {
      final foodPlaces = places.where((p) =>
        p.category.toLowerCase().contains('restaurant') ||
        p.category.toLowerCase().contains('food') ||
        p.category.toLowerCase().contains('cafe')
      ).toList();

      if (foodPlaces.isEmpty) {
        return 'I couldn\'t find any restaurants nearby at the moment. Try searching in a different area!';
      }

      final top = foodPlaces.take(3).toList();
      final buf = StringBuffer('Here are the best food options near you:\n\n');
      for (int i = 0; i < top.length; i++) {
        buf.writeln('${i + 1}. **${top[i].name}** — ${top[i].address}');
        buf.writeln('   ⭐ ${top[i].rating ?? '-'}  •  ${top[i].distance?.toStringAsFixed(1) ?? "-"} km  •  ${(top[i].isOpen == true) ? "🟢 Open" : "🔴 Closed"}');
        buf.writeln('');
      }
      buf.write('Tap on any result to see more details!');
      return buf.toString();
    }

    if (lowerQuery.contains('hotel') || lowerQuery.contains('stay') || lowerQuery.contains('room') || lowerQuery.contains('cheap')) {
      final hotelPlaces = places.where((p) =>
        p.category.toLowerCase().contains('hotel') || p.category.toLowerCase().contains('lodge')
      ).toList();

      if (hotelPlaces.isEmpty) {
        return 'No hotels found nearby. Try expanding your search radius!';
      }

      hotelPlaces.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
      final top = hotelPlaces.take(3).toList();
      final buf = StringBuffer('🏨 Hotels near you:\n\n');
      for (int i = 0; i < top.length; i++) {
        buf.writeln('${i + 1}. **${top[i].name}** — ${top[i].distance?.toStringAsFixed(1) ?? "-"} km away');
        buf.writeln('   ⭐ ${top[i].rating ?? '-'}  •  ${(top[i].isOpen == true) ? "🟢 Open" : "🔴 Closed"}');
        buf.writeln('');
      }
      buf.write('Want directions or more info? Just tap any result!');
      return buf.toString();
    }

    if (lowerQuery.contains('hospital') || lowerQuery.contains('doctor') || lowerQuery.contains('medical') || lowerQuery.contains('health')) {
      final medicalPlaces = places.where((p) =>
        p.category.toLowerCase().contains('hospital') ||
        p.category.toLowerCase().contains('doctor') ||
        p.category.toLowerCase().contains('pharmacy') ||
        p.category.toLowerCase().contains('clinic')
      ).toList();

      if (medicalPlaces.isEmpty) {
        return '🚑 No medical facilities found nearby. In an emergency, please dial 108 or 102 immediately!';
      }

      medicalPlaces.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
      final nearest = medicalPlaces.first;
      return '🏥 Nearest medical facility:\n\n'
          '**${nearest.name}** — ${nearest.distance?.toStringAsFixed(1) ?? "-"} km away\n'
          '📍 ${nearest.address}\n'
          '📞 ${nearest.phone ?? "N/A"}\n'
          '⭐ Rating: ${nearest.rating ?? '-'}\n'
          '🟢 ${(nearest.isOpen == true) ? "Open Now" : "Closed"}\n\n'
          'Also found ${medicalPlaces.length - 1} more nearby options.';
    }

    if (lowerQuery.contains('tourist') || lowerQuery.contains('visit') || lowerQuery.contains('sight') || lowerQuery.contains('famous') || lowerQuery.contains('see')) {
      final touristPlaces = famous.isNotEmpty ? famous : places;

      if (touristPlaces.isEmpty) {
        return 'No tourist spots found nearby. Try checking in a different city!';
      }

      final top = touristPlaces.take(3).toList();
      final buf = StringBuffer('🏆 Top places to visit:\n\n');
      for (int i = 0; i < top.length; i++) {
        buf.writeln('${i + 1}. **${top[i].name}**');
        buf.writeln('   ⭐ ${top[i].rating ?? '-'} (${top[i].reviewsCount ?? 0} reviews)  •  ${top[i].distance?.toStringAsFixed(1) ?? "-"} km');
        buf.writeln('');
      }
      buf.write('All these places are worth checking out! Tap to learn more.');
      return buf.toString();
    }

    if (lowerQuery.contains('weather') || lowerQuery.contains('temperature') || lowerQuery.contains('rain') || lowerQuery.contains('climate')) {
      return '☀️ **Current Weather**\n\n'
          'Temperature: ~32°C\n'
          'Condition: Partly Cloudy\n'
          'Humidity: 65%\n'
          'Wind: 12 km/h\n\n'
          '💡 Tip: Great day to explore! The weather looks pleasant for outdoor activities.';
    }

    if (lowerQuery.contains('atm') || lowerQuery.contains('bank') || lowerQuery.contains('cash') || lowerQuery.contains('money')) {
      final financialPlaces = places.where((p) =>
        p.category.toLowerCase().contains('atm') || p.category.toLowerCase().contains('bank')
      ).toList();

      if (financialPlaces.isEmpty) {
        return 'No ATMs or banks found nearby at the moment.';
      }

      financialPlaces.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
      final buf = StringBuffer('💰 Nearest financial services:\n\n');
      for (int i = 0; i < (financialPlaces.length > 3 ? 3 : financialPlaces.length); i++) {
        buf.writeln('${i + 1}. **${financialPlaces[i].name}** — ${financialPlaces[i].distance?.toStringAsFixed(1) ?? "-"} km');
      }
      return buf.toString();
    }

    if (lowerQuery.contains('temple') || lowerQuery.contains('mosque') || lowerQuery.contains('church') || lowerQuery.contains('worship') || lowerQuery.contains('religious') || lowerQuery.contains('gurudwara')) {
      final religiousPlaces = places.where((p) =>
        p.category.toLowerCase().contains('temple') ||
        p.category.toLowerCase().contains('mosque') ||
        p.category.toLowerCase().contains('church') ||
        p.category.toLowerCase().contains('gurudwara')
      ).toList();

      if (religiousPlaces.isEmpty) {
        return 'No religious places found nearby. Try searching with a specific name!';
      }

      final buf = StringBuffer('🕍 Religious places near you:\n\n');
      for (int i = 0; i < (religiousPlaces.length > 3 ? 3 : religiousPlaces.length); i++) {
        buf.writeln('${i + 1}. **${religiousPlaces[i].name}** — ${religiousPlaces[i].distance?.toStringAsFixed(1) ?? "-"} km');
      }
      return buf.toString();
    }

    return 'I found ${places.length} places near you. You can ask me about:\n\n'
        '🍽️ **Food & Restaurants** — "Best veg food near me"\n'
        '🏨 **Hotels** — "Cheapest hotels nearby"\n'
        '🏥 **Hospitals** — "Nearest hospital"\n'
        '🏆 **Tourist Spots** — "Tourist places to visit"\n'
        '💰 **ATMs & Banks** — "Nearby ATM"\n'
        '🕌 **Religious Places** — "Temple near me"\n'
        '☀️ **Weather** — "Today\'s weather"\n\n'
        'What would you like to know?';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandNavy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome, color: AppColors.brandNavy, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Local Guide', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                Text('Ask me anything!', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Start a conversation!', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildChatBubble(_messages[index]);
                    },
                  ),
          ),
          if (_messages.length <= 1)
            _buildSuggestedPrompts(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _suggestedPrompts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return ActionChip(
              label: Text(_suggestedPrompts[index], style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)),
              avatar: const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
              onPressed: () => _handleSend(_suggestedPrompts[index]),
              backgroundColor: Colors.amber.withOpacity(0.1),
              side: BorderSide.none,
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.brandNavy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: msg.isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
          border: msg.isUser ? null : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: msg.isUser ? Colors.white : Colors.black87,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.brandNavy, size: 16),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Row(
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.3, end: 1.0),
                    duration: Duration(milliseconds: 400 + i * 200),
                    builder: (_, value, __) => Opacity(
                      opacity: value,
                      child: const Text('.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    onEnd: () {},
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: _handleSend,
                decoration: InputDecoration(
                  hintText: 'Ask your AI guide...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontFamily: 'Poppins'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSend(_messageController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
