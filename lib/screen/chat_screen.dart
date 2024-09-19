import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import 'package:mokshayani/screen/discover_screen.dart';

class ChatbotUI extends StatefulWidget {
  @override
  _ChatbotUIState createState() => _ChatbotUIState();
}

class _ChatbotUIState extends State<ChatbotUI> {
  bool focusEnabled = false;
  bool inChatMode = false;
  String selectedFile = '';
  List<Map<String, String>> chatMessages = [];
  String sessionId = '';
  TextEditingController searchController = TextEditingController();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _startNewChatSession();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  Future<void> _sendChatQuery(String query) async {
    if (query.isEmpty) return;

    setState(() {
      chatMessages.add({'sender': 'user', 'message': query});
      inChatMode = true; // Transition to chat mode
    });

    final String apiUrl = "http://10.103.119.157/ask";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": query}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String botResponse = jsonResponse['response'];

        setState(() {
          chatMessages.add({'sender': 'bot', 'message': botResponse});
        });
      } else {
        setState(() {
          chatMessages.add({
            'sender': 'bot',
            'message': 'Error: Unable to fetch response from server.'
          });
        });
      }
    } catch (e) {
      setState(() {
        chatMessages.add({
          'sender': 'bot',
          'message': 'Error: Failed to connect to the server.'
        });
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        selectedFile = result.files.single.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selected: ${result.files.single.name}')),
      );
      await _uploadPDF(result.files.single);
    }
  }

  Future<void> _uploadPDF(PlatformFile file) async {
    final String apiUrl = "http://127.0.0.1:8081/upload_pdf";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path!,
        contentType: MediaType('application', 'pdf'),
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading PDF: $e')),
      );
    }
  }

  void _clearChat() {
    setState(() {
      chatMessages.clear();
      inChatMode = false; // Return to initial state
    });
  }

  void _startNewChatSession() {
    setState(() {
      chatMessages.clear();
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      inChatMode = false; // Ensure starting in initial state
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: Text('Mokshayani', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: Icon(Icons.person), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.home, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome to Mokshayani! How can I assist you today?',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Search TextField
            // Center(
            //   child: TextField(
            //     controller: searchController,
            //     onSubmitted: (value) {
            //       _sendChatQuery(value);
            //       searchController.clear(); // Clear text after submission
            //     },
            //     decoration: InputDecoration(
            //       filled: true,
            //       fillColor: Colors.grey[850],
            //       hintText: 'Ask anything...',
            //       hintStyle: TextStyle(color: Colors.white70),
            //       prefixIcon: Icon(Icons.search, color: Colors.white),
            //       suffixIcon: IconButton(
            //         icon: Icon(Icons.send, color: Colors.white),
            //         onPressed: () {
            //           _sendChatQuery(searchController.text);
            //           searchController.clear(); // Clear text after submission
            //         },
            //       ),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(30),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //     style: TextStyle(color: Colors.white),
            //   ),
            // ),
            SizedBox(height: 20),

            // Toggle and File Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Focus', style: TextStyle(color: Colors.white)),
                Switch(
                  value: focusEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      focusEnabled = value;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.white),
                  onPressed: _pickFile,
                ),
                Icon(Icons.lock, color: Colors.white),
              ],
            ),
            SizedBox(height: 20),

            // Conditional Queries List
            Visibility(
              visible: !focusEnabled,
              child: Expanded(
                child: ListView(
                  children: [
                    QueryCard('When will the next iPhone be released?',
                        Icons.phone_android),
                    QueryCard(
                        'Penalty for late tax filing', Icons.error_outline),
                    QueryCard(
                        'Summarize the research on brain breaks', Icons.grain),
                    QueryCard('Will US interest rates go down this year?',
                        Icons.trending_down),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            // Handle navigation to Home if needed
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DiscoverScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/library');
          }
        },
      ),
    );
  }
}

class QueryCard extends StatelessWidget {
  final String queryText;
  final IconData icon;

  QueryCard(this.queryText, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(queryText, style: TextStyle(color: Colors.white)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped: $queryText')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiscoverScreen(initialQuery: queryText),
            ),
          );
        },
      ),
    );
  }
}
