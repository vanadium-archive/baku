// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'task_list_data.dart';

typedef void TaskListRowHandleDelete(String uuid);

/// [TaskListRow] renders individual rows of Task Lists.
class TaskListRow extends StatefulWidget {
  final TaskListData list;
  final TaskListRowHandleDelete onDelete;

  TaskListRow(this.list, this.onDelete);

  @override
  TaskListRowState createState() => new TaskListRowState();
}

class TaskListRowState extends State<TaskListRow> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // TODO(jxson): create a flutter issue about the ink effect going away
    // when using Dismissable.
    return new Dismissable(
        key: new ObjectKey(config.list),
        direction: DismissDirection.endToStart,
        onDismissed: _handleDismiss,
        background: new Container(
            decoration: new BoxDecoration(
                backgroundColor: theme.canvasColor,
                border: new Border(
                    bottom: new BorderSide(color: theme.dividerColor))),
            child: new ListItem(trailing: new Icon(icon: Icons.delete))),
        child: new Container(
            decoration: new BoxDecoration(
                backgroundColor: theme.cardColor,
                boxShadow: kElevationToShadow[2],
                border: new Border(
                    bottom: new BorderSide(color: theme.dividerColor))),
            child: new ListItem(
                isThreeLine: true,
                title: new Text(config.list.name),
                subtitle: new Text(config.list.uuid),
                onTap: _open)));
  }

  void _open() {
    Navigator.pushNamed(context, '/lists/${config.list.uuid}');
  }

  void _handleDismiss(DismissDirection direction) {
    switch (direction) {
      // Swipe from right to left to delete.
      case DismissDirection.endToStart:
        config.onDelete(config.list.uuid);
        break;
      default:
        throw "Not implemented.";
        break;
    }
  }
}
