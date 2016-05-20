// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:async';

import 'task_data.dart';

/// [TaskDialog] handles the creation and editing of individual Tasks.
class TaskDialog extends StatefulWidget {
  final TaskData task;

  TaskDialog({Key key, this.task}) : super(key: key) {
    assert(task != null);
  }

  @override
  TaskDialogState createState() => new TaskDialogState();
}

class TaskDialogState extends State<TaskDialog> {
  @override
  void initState() {
    super.initState();

    // HACK(jxson): Trigger an immediate state change to coerce autofocus on
    // the [Input].
    //
    // TODO(jxson): Add an issue to flutter/flutter about this hack to get the
    // autofocus to work.
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

    // TODO(jxson): Clean up the form & input interactions.
    //
    // SEE: https://git.io/vrzFH
    Widget input = new Input(
        autofocus: true,
        hintText: 'What needs to happen?',
        labelText: 'Task Description',
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
    Navigator.pop(context, config.task);
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
    config.task.description = value;
  }
}
