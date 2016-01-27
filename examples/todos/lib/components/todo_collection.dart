// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'todo_item.dart';
import 'todo_dialog.dart';
import '../todo_model.dart';

/// [TodoCollection] is a [StatefulComponent] component.
///
/// This component is responsible for holding a list of TodoModel instances
/// and rendering the list appropriately. A Todo list fills the whole screen
/// and is composed of a tool bar, a list view, and the floating action button
/// for adding a new Todo item.
class TodoCollection extends StatefulComponent {
  TodoCollectionState createState() => new TodoCollectionState();
}

class TodoCollectionState extends State<TodoCollection> {
  List<TodoModel> todos = new List<TodoModel>();

  void removeTodo(TodoModel todo) {
    setState(() {
      todos.remove(todo);
    });
  }

  void addTodo(String title) {
    // Use `setState(fn)` to signal to the framework that some internal state
    // has been changed and a needs to be rebuilt. If the state update is not
    // wrapped in a `setState` call the change will not be displayed to the
    // screen.
    setState(() {
      todos.add(new TodoModel(title: title));
    });
  }

  Widget buildTodo(BuildContext context, int index) {
    if (index >= todos.length) {
      return null;
    }

    TodoModel todo = todos[index];

    return new TodoItem(
        // Key is required here to support a requirement of child
        // ScrollableMixedWidgetList.
        key: todo.key,
        todo: todo,
        onDelete: removeTodo);
  }

  Widget build(BuildContext context) {
    return new Scaffold(
        toolBar: new ToolBar(center: new Text('TODO List')),
        // Avoiding MaterialList/ScrollableList here since children
        // would be required to have a pre-defined height via the contstructor
        // property itemExtent.
        // SEE: http://goo.gl/cB5bOE
        body: new ScrollableMixedWidgetList(
            builder: buildTodo, token: todos.length),
        floatingActionButton: new FloatingActionButton(
            child: new Icon(icon: 'content/add'),
            onPressed: () => showDialog(
                context: context, child: new TodoDialog(onSave: addTodo))));
  }
}
