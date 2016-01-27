// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import './components/todo_collection.dart';

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
      accentColor: Colors.pinkAccent[200]);

  /// Build a `MaterialApp` widget.
  ///
  /// The `MaterialApp` widget allows the inheritance of theme data. For now
  /// only an empty Todo List is rendered as the single, default route.
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'TODO',
        theme: theme,
        routes: {'/': (RouteArguments args) => new TodoCollection()});
  }
}
