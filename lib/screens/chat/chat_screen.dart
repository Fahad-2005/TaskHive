import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String workspaceId;
  final String workspaceName;

  const ChatScreen({
    super.key,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'content': text,
        'workspace_id': widget.workspaceId,
        'user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.workspaceName} Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('workspace_id', widget.workspaceId)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _MessageBubble(
                      message: msg['content'],
                      userId: msg['user_id'],
                      // 🇵🇰 Converts UTC from database to Pakistan Time
                      createdAt: DateTime.parse(msg['created_at']).toLocal(),
                      isMe: msg['user_id'] == myId,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String userId;
  final DateTime createdAt;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.userId,
    required this.createdAt,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // We use Supabase.instance.client directly to avoid the 'undefined' error
    final client = Supabase.instance.client;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            ChatAvatar(userId: userId),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 🏷️ SHOW USERNAME ABOVE BUBBLE (Only for others)
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: FutureBuilder(
                      future: client.from('profiles').select('username').eq('id', userId).single(),
                      builder: (context, snapshot) {
                        final name = snapshot.data?['username'] ?? 'User';
                        return Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: Radius.circular(isMe ? 15 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 15),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                  ),
                ),
                // 🕒 TIME (PST)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    DateFormat('hh:mm a').format(createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            ChatAvatar(userId: userId),
          ],
        ],
      ),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  final String userId;
  const ChatAvatar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Supabase.instance.client
          .from('profiles')
          .select('avatar_url, username')
          .eq('id', userId)
          .single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircleAvatar(radius: 14);
        final data = snapshot.data as Map<String, dynamic>;
        final url = data['avatar_url'] as String?;
        final name = data['username'] as String;

        return CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty)
              ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 10))
              : null,
        );
      },
    );
  }
}