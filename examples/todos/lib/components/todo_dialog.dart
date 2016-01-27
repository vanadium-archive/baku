// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

typedef void TodoHandleSave(Todo);

class TodoDialog extends StatefulComponent {
  TodoDialog({Key key, this.value: "", this.title: "Add Todo", this.onSave})
      : super(key: key);

  final String title;
  final TodoHandleSave onSave;
  final String value;

  TodoDialogState createState() => new TodoDialogState();
}

class TodoDialogState extends State<TodoDialog> {
  String value;

  @override
  void initState() {
    super.initState();
    value = config.value;
  }

  void handleInputChange(String update) {
    value = update;
  }

  // The Input widget gets different values on change versus on submit, be
  // sure to update the todo with the most recent value.
  void handleInputSubmit(String value) {
    handleInputChange(value);
    save();
  }

  void close() {
    Navigator.pop(context);
  }

  void save() {
    close();
    config.onSave(value);
  }

  static final GlobalKey inputKey = new GlobalKey(debugLabel: 'todo input');

  Widget build(BuildContext context) {
    Text label = new Text("What needs to get done?");
    Input input = new Input(
        key: inputKey,
        initialValue: value,
        onChanged: handleInputChange,
        onSubmitted: handleInputSubmit);
    List children = <Widget>[label, input];

    return new Scaffold(
        toolBar: buildToolbar(),
        body: new Container(
            margin: new EdgeDims.all(24.0), child: new Block(children)));
  }

  Widget buildToolbar() {
    return new ToolBar(
        left: new IconButton(icon: "navigation/close", onPressed: close),
        center: new Text(config.title),
        right: <Widget>[
          // NOTE: The right spacing is off here.
          new FlatButton(
              child: new Text('SAVE'),
              // NOTE: without this the button text color is black instead of
              // white. Is there a correct/canonical way to reach into the
              // theme and grab the toolbar text color to use here?
              textColor: Colors.white,
              onPressed: save)
        ]);
  }
}
