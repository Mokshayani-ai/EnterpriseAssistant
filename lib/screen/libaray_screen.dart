import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, String>> chatHistory = [];

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? chatStrings = prefs.getStringList('chatHistory');
    if (chatStrings != null) {
      setState(() {
        chatHistory = chatStrings
            .map((chatString) => jsonDecode(chatString))
            .toList()
            .cast<Map<String, String>>();
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatStrings =
        chatHistory.map((chat) => jsonEncode(chat)).toList();
    await prefs.setStringList('chatHistory', chatStrings);
  }

  Future<void> _deleteChat(int index) async {
    setState(() {
      chatHistory.removeAt(index);
    });
    await _saveChatHistory(); // Save updated history after deletion
  }

  Future<void> _clearAllChatHistory() async {
    setState(() {
      chatHistory.clear();
    });
    await _saveChatHistory(); // Save updated (empty) history
  }

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () async {
              bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Clear All History'),
                      content: Text(
                          'Are you sure you want to clear all chat history?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Clear'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirm) {
                _clearAllChatHistory();
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chatHistory.length,
        itemBuilder: (context, index) {
          final chat = chatHistory[index];
          return ListTile(
            title: Text(chat['sender'] == 'user' ? 'User' : 'Bot'),
            subtitle: Text(chat['message']!),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Chat'),
                        content:
                            Text('Are you sure you want to delete this chat?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirm) {
                  _deleteChat(index);
                }
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(chat: chat),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Library'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/discover');
          } else if (index == 2) {
            // Already on Library screen
          }
        },
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final Map<String, String> chat;

  ChatDetailScreen({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chat['sender'] == 'user' ? 'User' : 'Bot'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(chat['message']!),
      ),
    );
  }
}
