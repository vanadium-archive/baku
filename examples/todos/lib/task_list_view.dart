// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'task_data.dart';
import 'task_row.dart';
import 'task_list_data.dart';
import 'task_dialog.dart';

/// [TaskListView] renders a page showing all the Tasks associated to a given
/// `list`.
class TaskListView extends StatefulWidget {
  final TaskListData list;

  TaskListView({Key key, this.list}) : super(key: key) {
    assert(list != null);
  }

  @override
  TaskListViewState createState() => new TaskListViewState();
}

class TaskListViewState extends State<TaskListView> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = config.list.tasks.keys.map((String uuid) {
      TaskData task = config.list.tasks[uuid];
      return new TaskRow(task: task, onDelete: _delete, onComplete: _complete);
    }).toList();

    return new Scaffold(
        appBar: new AppBar(title: new Text('List: ${config.list.name}')),
        body: new Block(children: children),
        floatingActionButton: new FloatingActionButton(
            onPressed: _showNewTaskDialog,
            tooltip: 'Add new list.',
            child: new Icon(icon: Icons.add)));
  }

  void _showNewTaskDialog() {
    TaskData task = new TaskData();
    Widget dialog = new TaskDialog(task: task);

    showDialog(context: context, child: dialog).then(_add);
  }

  void _add(TaskData task) {
    if (task == null) return;

    setState(() => config.list.tasks[task.uuid] = task);
  }

  void _delete(String uuid) {
    setState(() => config.list.tasks.remove(uuid));
  }

  void _complete(String uuid) {
    setState(() {
      TaskData task = config.list.tasks[uuid];
      task.completed = true;
    });
  }
}
