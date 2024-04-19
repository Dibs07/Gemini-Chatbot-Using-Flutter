import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentuser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiuser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://i.gadgets360cdn.com/large/gemini_ai_google_1701928139717.jpg",
  );

  late String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Gemini Chat'),
      ),
      body: buildUi(),
    );
  }

  Widget buildUi() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Enter Query about Image'),
                  content: TextField(
                    onChanged: (value) {
                      setState(() {
                        description = value;
                      });
                    },
                    decoration: InputDecoration(hintText: "Description"),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (description.isNotEmpty) {
                          sendmediamessage(description);
                        }
                      },
                      child: Text('Send'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
        alwaysShowSend: true,
        sendOnEnter: true,
      ),
      currentUser: currentuser,
      onSend: sendmessage,
      messages: messages.reversed.toList(), // Reversing the list here
    );
  }

  void sendmessage(ChatMessage message) {
    setState(() {
      messages = [...messages, message];
      // Gemini.sendMessage(message.text);
    });
    try {
      String qs = message.text;
      List<Uint8List>? images;
      if (message.medias?.isNotEmpty ?? false) {
        images = [File(message.medias!.first.url).readAsBytesSync()];
      }
      gemini.streamGenerateContent(qs, images: images).listen((event) {
        ChatMessage? last = messages.firstOrNull;
        if (last != null && last.user.id == geminiuser.id) {
          last = messages.removeAt(0);
          String response = event.content?.parts?.fold("",
                  (previousValue, element) => "$previousValue ${element.text}") ??
              "";
          last.text += response;
          setState(() {
            messages = [last!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold("",
                  (previousValue, element) => "$previousValue ${element.text}") ??
              "";
          ChatMessage responseMessage = ChatMessage(
              text: response, user: geminiuser, createdAt: DateTime.now());
          setState(() {
            messages = [...messages, responseMessage];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void sendmediamessage(String description) async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage message = ChatMessage(
        text: description,
        user: currentuser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            type: MediaType.image,
            fileName: "",
            url: file.path,
          )
        ],
      );
      sendmessage(message);
    }
  }
}
