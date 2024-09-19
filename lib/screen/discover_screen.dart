import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class DiscoverScreen extends StatefulWidget {
  final String? initialQuery;

  DiscoverScreen({this.initialQuery});

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool inChatMode = false;
  List<Map<String, String>> searchResults = [];
  File? _image;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _sendSearchQuery(widget.initialQuery!);
    }
  }

  Future<void> _sendSearchQuery(String query) async {
    setState(() {
      searchResults.add({'sender': 'user', 'message': query});
    });

    final String apiUrl =
        "http://127.0.0.1:8081/ask"; // Update to your API endpoint

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
          searchResults.add({'sender': 'bot', 'message': botResponse});
        });
      } else {
        print("Server error: ${response.statusCode}");
        setState(() {
          searchResults.add({'sender': 'bot', 'message': 'Error from server'});
        });
      }
    } catch (e) {
      print("Error during HTTP request: $e");
      setState(() {
        searchResults.add(
            {'sender': 'bot', 'message': 'Error: Unable to send request.'});
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final option = await showModalBottomSheet<String>(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Icon(Icons.file_copy),
                title: Text('Choose a file'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
            ],
          );
        },
      );

      if (option == null) return;

      File? file;
      final picker = ImagePicker();

      switch (option) {
        case 'camera':
          final pickedFile = await picker.pickImage(source: ImageSource.camera);
          if (pickedFile != null) file = File(pickedFile.path);
          break;
        case 'gallery':
          final pickedFile =
              await picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) file = File(pickedFile.path);
          break;
        case 'file':
          final pickedFile =
              await FilePicker.platform.pickFiles(type: FileType.any);
          if (pickedFile != null) file = File(pickedFile.files.single.path!);
          break;
      }

      if (file != null) {
        setState(() {
          _image = file;
          searchResults.add({'sender': 'user', 'message': '[Image uploaded]'});
        });
        await _uploadFile(file);
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _uploadFile(File file) async {
    final String apiUrl =
        "http://10.103.119.157:8081/ocr"; // Update to your API endpoint

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        String ocrText = jsonResponse['text'];

        setState(() {
          searchResults.add({'sender': 'bot', 'message': ocrText});
        });
      } else {
        setState(() {
          searchResults.add({
            'sender': 'bot',
            'message': 'Error: Unable to fetch response from server.'
          });
        });
      }
    } catch (e) {
      print("Error during file upload: $e");
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatStrings =
        searchResults.map((chat) => jsonEncode(chat)).toList();
    await prefs.setStringList('chatHistory', chatStrings);
  }

  void _startNewChatSession() {
    setState(() {
      searchResults.clear();
    });
    _saveChatHistory(); // Save history
  }

  void _clearChat() {
    setState(() {
      searchResults.clear();
    });
    _saveChatHistory(); // Save history
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _startNewChatSession),
          IconButton(icon: Icon(Icons.clear), onPressed: _clearChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final chat = searchResults[index];
                bool isUser = chat['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[850],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        chat['message'] == '[Image uploaded]' && _image != null
                            ? Image.file(_image!)
                            : Text(
                                chat['message']!,
                                style: TextStyle(color: Colors.white),
                              ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.white),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    final query = _textController.text.trim();
                    if (query.isNotEmpty) {
                      _sendSearchQuery(query);
                      _textController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
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
            Navigator.pushReplacementNamed(context, '/library');
          }
        },
      ),
    );
  }
}
