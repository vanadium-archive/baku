// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'home.dart';
import 'task_list_data.dart';
import 'task_list_view.dart';

/// Start the application.
///
/// Create an instance of [App] and use the Flutter [runApp] function render
/// this application to the screen.
void main() {
  runApp(new App());
}

/// Subclass [StatefulWidget] to build the top-level component.
///
/// The top-level [App] widget manages the composition of the enitre
/// applications's widget tree based on it's state. [AppState] holds an
/// in-memory [Map] of Task Lists. It is critical this state is held at the
/// top level (and not further down the widget tree) to prevent user created
/// values from disappearing between navigation changes.
class App extends StatefulWidget {
  @override
  AppState createState() => new AppState();
}

class AppState extends State<StatefulWidget> {
  final Map<String, TaskListData> lists = <String, TaskListData>{};
  final ThemeData theme = new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.indigo,
      accentColor: Colors.pinkAccent[200]);

  /// Build a [MaterialApp] widget.
  ///
  /// The [MaterialApp] widget allows the inheritance of [ThemeData].
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'TODO',
        theme: theme,
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => new Home(lists)
        },
        onGenerateRoute: handleRoute);
  }

  // TODO(jxson): look into creating a more ergonomic routing system with
  // clear route definitions and ways to explicitly handle not found errors.
  Route<Null> handleRoute(RouteSettings settings) {
    List<String> path = settings.name.split('/');

    if (!settings.name.startsWith('/')) return null;

    switch (path[1]) {
      case 'lists':
        TaskListData list = lists[path[2]];
        return new MaterialPageRoute<Null>(
            settings: settings,
            builder: (BuildContext context) {
              return new TaskListView(list: list);
            });
      default:
        return null;
    }
  }
}
