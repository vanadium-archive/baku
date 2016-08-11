// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/http.dart' as http;

import 'keys.dart';

const String setMessageUrl = 'http://baku-flutter-chat.appspot.com/set_message';
const String getHistoryUrl = 'http://baku-flutter-chat.appspot.com/get_history';

String myname;
int myColor;

void start(String name, int color) {
  myname = name;
  myColor = color;
  runApp(
    new MaterialApp(
      title: 'Chat Demo',
      theme: new ThemeData(
        primarySwatch: Colors.primaries[myColor],
        accentColor: Colors.orangeAccent[400]
      ),
      home: new ChatScreen()
    )
  );
}

class ChatScreen extends StatefulWidget {
  ChatScreen({ Key key }) : super(key: key);

  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  String _name = myname;
  InputValue _currentMessage = InputValue.empty;
  bool get _isComposing => _currentMessage.text.isNotEmpty;

  int _color = myColor;
  List<ChatMessage> _messages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    listenToHistory();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Chatting as $_name')
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new Block(
              padding: new EdgeInsets.symmetric(horizontal: 8.0),
              scrollAnchor: ViewportAnchor.end,
              children: _messages.map((m) => new ChatMessageListItem(m)).toList()
            )
          ),
          _buildTextComposer()
        ]
      )
    );
  }

  Widget _buildTextComposer() {
    ThemeData themeData = Theme.of(context);
    return new Row(
      children: <Widget>[
        new Flexible(
          child: new Input(
            key: new ValueKey(inputKey),
            value: _currentMessage,
            hintText: 'Enter message',
            onSubmitted: _handleMessageAdded,
            onChanged: _handleMessageChanged
          )
        ),
        new Container(
          margin: new EdgeInsets.symmetric(horizontal: 4.0),
          child: new IconButton(
            key: new ValueKey(buttonKey),
            icon: new Icon(Icons.send),
            onPressed: _isComposing ? () => _handleMessageAdded(_currentMessage) : null,
            color: themeData.accentColor
          )
        )
      ]
    );
  }

  Future<Null> listenToHistory() async {
    while (true) {
      getMessages();
      await new Future<Null>.delayed(new Duration(milliseconds: 500));
    }
  }

  void postMessage(ChatMessage message) {
    ChatUser user = message.sender;
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json'
    };
    Map<String, String> body = <String, String>{
      'user': user.name,
      'color': '${user.color}',
      'text': message.text
    };

    http.post(
      setMessageUrl,
      headers: headers,
      body: JSON.encode(body)
    ).then((http.Response response) {
      String json = response.body;
      if (json == null) {
        print('Fail to post $message to $setMessageUrl');
        return;
      }
      JsonDecoder decoder = new JsonDecoder();
      dynamic result = decoder.convert(json);
      print('Response: ${result["answer"]}');
    });
  }

  void getMessages() {
    http.get(getHistoryUrl).then((http.Response response) {
      String json = response.body;
      if (json == null) {
        print('Fail to get message history from $getHistoryUrl');
        return;
      }
      JsonDecoder decoder = new JsonDecoder();
      dynamic result = decoder.convert(json);
      List<ChatMessage> history = new List.from(
        result['history'].map(
          (message) {
            return new ChatMessage(
              sender: new ChatUser(
                name: message['user'],
                color: int.parse(message['color'])
              ),
              text: message['text'],
              animationController: new AnimationController(
                duration: new Duration(milliseconds: 700)
              )
            );
          }
        )
      );
      if (_messages.length > history.length) {
        print('Local messages size is greater than the remote messages size!');
        setState(() {
          _messages.clear();
        });
      }
      if (_messages.length == history.length) {
        return;
      }
      for (int i = _messages.length; i < history.length; i++) {
        setState(() {
          _messages.add(history[i]);
        });
        history[i].animationController.forward();
      }
    });
  }

  void _addMessage({ String name, int color, String text }) {
    AnimationController animationController = new AnimationController(
      duration: new Duration(milliseconds: 700)
    );
    ChatUser sender = new ChatUser(name: name, color: color);
    ChatMessage message = new ChatMessage(
      sender: sender,
      text: text,
      animationController: animationController
    );
    postMessage(message);
  }

  void _handleMessageChanged(InputValue value) {
    setState(() {
      _currentMessage = value;
    });
  }

  void _handleMessageAdded(InputValue value) {
    setState(() {
      _currentMessage = InputValue.empty;
    });
    _addMessage(name: _name, color: _color, text: value.text);
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    super.dispose();
  }
}

class ChatMessageListItem extends StatelessWidget {
  ChatMessageListItem(this.message);
  final ChatMessage message;

  Widget build(BuildContext context) {
    ListItem item;
    if (message.sender.name == myname) {
      item = new ListItem(
        dense: true,
        trailing: new CircleAvatar(
          child: new Text(message.sender.name[0]),
          backgroundColor: Colors.accents[message.sender.color][700]
        ),
        title: new Align(
          alignment: FractionalOffset.centerRight,
          child: new Text(
            message.sender.name,
            textAlign: TextAlign.center
          )
        ),
        subtitle: new Align(
          alignment: FractionalOffset.centerRight,
          child: new Text(
            message.text,
            textAlign: TextAlign.center
          )
        )
      );
    } else {
      item = new ListItem(
        dense: true,
        leading: new CircleAvatar(
          child: new Text(message.sender.name[0]),
          backgroundColor: Colors.accents[message.sender.color][700]
        ),
        title: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Text(
            message.sender.name,
            textAlign: TextAlign.center
          )
        ),
        subtitle: new Align(
          alignment: FractionalOffset.centerLeft,
          child: new Text(
            message.text,
            textAlign: TextAlign.center
          )
        )
      );
    }
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
        parent: message.animationController,
        curve: Curves.easeOut
      ),
      axisAlignment: 0.0,
      child: item
    );
  }
}

class ChatUser {
  ChatUser({ this.name, this.color });
  final String name;
  final int color;

  @override
  bool operator ==(other) {
    if (other is! ChatUser) return false;
    ChatUser user = other;
    return user.name == name && user.color == color;
  }

  @override
  int get hashCode {
    return hashValues(name, color);
  }

  @override
  String toString() {
    return 'username: $name, color: $color';
  }
}

class ChatMessage {
  ChatMessage({ this.sender, this.text, this.animationController });
  final ChatUser sender;
  final String text;
  final AnimationController animationController;

  @override
  bool operator ==(other) {
    if (other is! ChatMessage) return false;
    ChatMessage message = other;
    return message.sender == sender && message.text == text;
  }

  @override
  int get hashCode {
    return hashValues(sender, text);
  }

  @override
  String toString() {
    return '<${sender.toString()}, text: $text>';
  }
}
