import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    // Auto-scroll on new messages
    if (chatState.activeMessages.isNotEmpty || chatState.isGenerating) {
      _scrollToBottom();
    }

    // Determine model display name
    String modelName(String key) {
      switch (key) {
        case 'gemini':
          return 'Gemini 2.5 Flash';
        case 'deepseek':
          return 'DeepSeek Chat';
        case 'qwen':
          return 'Qwen 3 Next 80B';
        default:
          return 'AI Assistant';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('แชทอัจฉริยะ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Model Selection Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.slate900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate800),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: chatState.selectedModel,
                dropdownColor: AppTheme.slate900,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.indigo500),
                onChanged: (newModel) {
                  if (newModel != null) {
                    chatNotifier.selectModel(newModel);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'gemini', child: Text('Gemini 2.5 (Google)')),
                  DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek Chat (Direct/OR)')),
                  DropdownMenuItem(value: 'qwen', child: Text('Qwen 3 (OpenRouter)')),
                ],
              ),
            ),
          )
        ],
      ),
      // Drawer for Switching Sessions (ChatGPT Style)
      drawer: Drawer(
        backgroundColor: AppTheme.slate950,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.slate900,
                border: Border(bottom: BorderSide(color: AppTheme.slate800)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.indigo600.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.indigo500.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.forum, color: AppTheme.indigo500, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ประวัติการแชท',
                      style: TextStyle(color: AppTheme.slate100, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            // New Session Action
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  chatNotifier.createNewSession();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('สร้างห้องแชทใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.indigo600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const Divider(),

            // Sessions List
            Expanded(
              child: ListView.builder(
                itemCount: chatState.sessions.length,
                itemBuilder: (context, index) {
                  final session = chatState.sessions[index];
                  final isSelected = session.id == chatState.activeSessionId;
                  
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppTheme.slate900,
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: isSelected ? AppTheme.indigo500 : AppTheme.slate400,
                    ),
                    title: Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? AppTheme.slate100 : AppTheme.slate300,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.rose400, size: 16),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('ลบห้องสนทนานี้?'),
                                  content: const Text('คุณยืนยันที่จะลบประวัติการคุยในห้องนี้ทั้งหมดหรือไม่?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('ยกเลิก', style: TextStyle(color: AppTheme.slate400)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        chatNotifier.deleteSession(session.id);
                                        Navigator.pop(context);
                                        Navigator.pop(context); // Close Drawer
                                      },
                                      child: const Text('ลบ', style: TextStyle(color: AppTheme.rose400)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : null,
                    onTap: () {
                      chatNotifier.selectSession(session.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error Message Banner (if any)
          if (chatState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.rose950,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.rose400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: const TextStyle(color: AppTheme.rose400, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

          // Messages Viewport
          Expanded(
            child: chatState.activeMessages.isEmpty && !chatState.isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.indigo600.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum_outlined, color: AppTheme.slate700, size: 56),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'มีอะไรให้ผมช่วยวันนี้บ้างครับ?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate300),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'เริ่มสนทนาโดยใช้โมเดล ${modelName(chatState.selectedModel)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.activeMessages.length + (chatState.isGenerating ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Render Typing Indicator at the end
                      if (index == chatState.activeMessages.length) {
                        return _buildTypingIndicator(modelName(chatState.selectedModel));
                      }

                      final msg = chatState.activeMessages[index];
                      final isUser = msg.sender == 'user';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              // AI Avatar
                              Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 8, top: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.indigo600, AppTheme.purple600],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                                ),
                              )
                            ],
                            
                            // Message Bubble
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppTheme.indigo600
                                      : AppTheme.slate900,
                                  border: isUser
                                      ? null
                                      : Border.all(color: AppTheme.slate800),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Model Info tag if Assistant
                                    if (!isUser && msg.modelUsed != null) ...[
                                      Text(
                                        modelName(msg.modelUsed!),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.slate500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    // Content text
                                    Text(
                                      msg.message,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: isUser ? Colors.white : AppTheme.slate100,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Message Input Bottom Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.slate950,
              border: Border(top: BorderSide(color: AppTheme.slate800, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'พิมพ์ข้อความของคุณที่นี่...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: chatState.isGenerating ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.indigo600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.slate900,
                    disabledForegroundColor: AppTheme.slate700,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(String model) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.indigo600, AppTheme.purple600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.slate900,
              border: Border.all(color: AppTheme.slate800),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$model กำลังพิมพ์...',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.slate500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.indigo500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
