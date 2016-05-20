// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'task_data.dart';

typedef void TaskRowHandleDelete(String uuid);
typedef void TaskRowHandleComplete(String uuid);

/// [TaskRow] renders individual rows of Tasks .
class TaskRow extends StatefulWidget {
  final TaskData task;
  final TaskRowHandleDelete onDelete;
  final TaskRowHandleComplete onComplete;

  TaskRow({Key key, this.task, this.onDelete, this.onComplete})
      : super(key: key) {
    assert(task != null);
  }

  @override
  TaskRowState createState() => new TaskRowState();
}

class TaskRowState extends State<TaskRow> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Text description = config.task.completed
        ? new Text(config.task.description,
            style: new TextStyle(
                color: theme.disabledColor,
                decoration: TextDecoration.lineThrough))
        : new Text(config.task.description);

    // TODO(jxson): create a flutter issue about the ripple effect going away
    // when using Dismissable.
    return new Dismissable(
        // NOTE: Key needs to change based on completion.
        key: new ObjectKey("${config.task.uuid}-${config.task.completed}"),
        direction: DismissDirection.horizontal,
        onDismissed: _handleDismiss,
        background: new Container(
            decoration: new BoxDecoration(
                backgroundColor: theme.canvasColor,
                border: new Border(
                    bottom: new BorderSide(color: theme.dividerColor))),
            child: new ListItem(leading: new Icon(icon: Icons.check))),
        secondaryBackground: new Container(
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
                title: description,
                subtitle: new Text(config.task.uuid))));
  }

  void _handleDismiss(DismissDirection direction) {
    switch (direction) {
      // Swipe from right to left to delete.
      case DismissDirection.endToStart:
        config.onDelete(config.task.uuid);
        break;
      // Swipe from left to right to complete.
      case DismissDirection.startToEnd:
        config.onComplete(config.task.uuid);
        break;
      default:
        throw "Not implemented.";
        break;
    }
  }
}
