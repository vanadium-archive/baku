// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'task_list_data.dart';
import 'task_list_dialog.dart';
import 'task_list_row.dart';

/// [Home] is a [StatefulWidget].
///
/// This widget is responsible for holding a
/// collection of Task Lists and rendering them appropriately. The home screen
/// is composed of a tool bar, a list view, and the floating action button for
/// adding a new Lists.
class Home extends StatefulWidget {
  final Map<String, TaskListData> lists;

  Home(this.lists);

  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // TODO(jxson): Look into using a widget that accepts a builder function
    // for rendering rows in the scrollable list.
    //
    // SEE: https://git.io/vrzFH
    List<Widget> children = config.lists.keys.map((String uuid) {
      TaskListData list = config.lists[uuid];
      return new TaskListRow(list, _delete);
    }).toList();

    return new Scaffold(
        appBar: new AppBar(title: new Text('Todo Lists')),
        // NOTE: Using any kind of scrollable list with a height extent prevents
        // dismissible height animations from occurring.
        body: new Block(children: children),
        floatingActionButton: new FloatingActionButton(
            tooltip: 'Add new list.',
            child: new Icon(icon: Icons.add),
            onPressed: _showNewTaskListDialog));
  }

  void _showNewTaskListDialog() {
    TaskListData list = new TaskListData();
    Widget dialog = new TaskListDialog(list: list);

    // TODO(jxson): Use a callback instead of the return future from
    // `showDialog`. There is too much indirection with the current method
    // since the dialog needs to use `Navigator.pop(...)` to get values back
    // to this widget.
    //
    // SEE: https://git.io/vrzFH
    showDialog(context: context, child: dialog).then(_add);
  }

  void _add(TaskListData list) {
    if (list == null) return;

    // Use `setState(fn)` to signal to that some internal state has changed
    // and the widget needs to be rebuilt. If the state updates are not
    // wrapped in a `setState` call the change will not be displayed.
    setState(() => config.lists[list.uuid] = list);
  }

  void _delete(String uuid) {
    setState(() => config.lists.remove(uuid));
  }
}
