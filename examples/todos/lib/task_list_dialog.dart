// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:async';

import 'task_list_data.dart';

/// [TaskListDialog] handles the creation and editing of Task Lists.
class TaskListDialog extends StatefulWidget {
  final TaskListData list;

  TaskListDialog({Key key, this.list}) : super(key: key) {
    assert(list != null);
  }

  @override
  TaskListDialogState createState() => new TaskListDialogState();
}

class TaskListDialogState extends State<TaskListDialog> {
  @override
  void initState() {
    super.initState();

    // HACK(jxson): Trigger an immediate state change to coerce autofocus on
    // the [Input].
    new Timer(new Duration(milliseconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget save = new FlatButton(
        child: new Text('SAVE',
            style: theme.textTheme.body1.copyWith(color: Colors.white)),
        onPressed: _save);

    Widget input = new Input(
        autofocus: true,
        hintText: 'What should this list be called?',
        labelText: 'List Name',
        formField:
            new FormField<String>(setter: _update, validator: _validate));

    return new Scaffold(
        appBar: new AppBar(
            leading: new IconButton(icon: Icons.clear, onPressed: _cancel),
            title: new Text('New List'),
            actions: <Widget>[save]),
        body: new Form(
            onSubmitted: _save, child: new Block(children: <Widget>[input])));
  }

  void _save() {
    Navigator.pop(context, config.list);
  }

  void _cancel() {
    Navigator.pop(context);
  }

  String _validate(String value) {
    if (value.isEmpty)
      return 'List name is required';
    else
      return null;
  }

  void _update(String value) {
    config.list.name = value;
  }
}
