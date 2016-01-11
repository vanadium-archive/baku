// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

/// Start the Todo application.
///
/// Use the Flutter `runApp` function render this application's widget tree
/// to the screen.
void main() {
  runApp(new App());
}

/// Subclass `StatelessComponent` to build the top-level component.
///
/// The `App` component composes other, lower-level components in it's
/// `build` function. This top-level component, `App` does not need to hold
/// any state since that is managed by components lower down in the tree like
/// `TodoList`. Because this component is stateless, and only manages
/// composition of the widget tree it can inherit from `StatelessComponent`.
class App extends StatelessComponent {
  final ThemeData theme = new ThemeData(
    brightness: ThemeBrightness.light,
    primarySwatch: Colors.indigo,
    accentColor: Colors.pinkAccent[200]
  );

  /// Build a `MaterialApp` widget.
  ///
  /// The `MaterialApp` widget allows the inheritance of theme data. For now
  /// only an empty Todo List is rendered as the single, default route.
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'TODO',
      theme: theme,
      routes: {'/': (RouteArguments args) => new TodoList()}
    );
  }
}

/// `TodoList` is a `StatefulComponent` component.
///
/// This component is responsible for holding a list of `Todo` items and
/// rendering the list appropriately. A Todo list fills the whole screen
/// and is composed of a tool bar, a list view, and the floating
/// action button for adding a new Todo item.
class TodoList extends StatefulComponent {
  TodoListState createState() => new TodoListState();
}

class TodoListState extends State<TodoList> {
  List<Todo> todos = new List<Todo>();

  void addTodo() {
    // Use `setState(fn)` to signal to the framework that some internal state
    // has been changed and a needs to be rebuilt. If the state update is not
    // wrapped in a `setState` call the change will not be displayed to the
    // screen.
    setState(() {
      todos.add(new Todo(title: 'FAB Item #${todos.length}.'));
    });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('TODO List')
      ),
      body: new MaterialList(
        type: MaterialListType.oneLine,
        children: todos
      ),
      floatingActionButton: new FloatingActionButton(
          child: new Icon(icon: 'content/add'),
          onPressed: addTodo
      )
    );
  }
}

class Todo extends StatefulComponent {
  Todo({Key key, this.title, this.completed: false}) : super(key: key);

  final String title;
  final bool completed;

  TodoState createState() => new TodoState();
}

class TodoState extends State<Todo> {
  bool completed;

  /// Override `initState()`.
  ///
  /// Initialize internal state value `completed` with the value passed into
  /// the parent `Todo` constructor. The `config` property allows the state
  /// instance to access the properties of the `Todo` component.
  @override
  void initState() {
    super.initState();
    completed = config.completed;
  }

  void toggle() {
    setState(() {
      completed = !completed;
    });
  }

  Widget build(BuildContext context) {
    return new ListItem(
      center: new Text('${config.title} - done: $completed'),
      onTap: toggle
    );
  }
}
