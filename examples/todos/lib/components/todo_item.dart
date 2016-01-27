// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/animation.dart';

import "../todo_model.dart";

const Duration _todoSnapDuration = const Duration(milliseconds: 200);

typedef void TodoHandleDelete(TodoModel);

enum TodoStatus { idle, completing, deleting, }

class TodoItem extends StatefulComponent {
  TodoItem({Key key, this.todo, this.onDelete}) : super(key: key) {
    assert(todo != null);
    assert(onDelete != null);
  }

  final TodoModel todo;
  final TodoHandleDelete onDelete;

  TodoItemState createState() => new TodoItemState();
}

// TODO(jasoncampbell): Create a throttle animation so that dragging
// appears to slow down as the item gets closer to the threshold.
class TodoItemState extends State<TodoItem> {
  HorizontalDragGestureRecognizer drag;
  ValuePerformance<double> snapPerformance;

  TodoItemState() {
    drag = new HorizontalDragGestureRecognizer(
        router: Gesturer.instance.pointerRouter,
        gestureArena: Gesturer.instance.gestureArena)
      ..onStart = handleDragStart
      ..onUpdate = handleDragUpdate
      ..onEnd = handleDragEnd;

    snapPerformance = new ValuePerformance<double>(
        variable: snapValue, duration: _todoSnapDuration)
      ..addStatusListener(handleSnapAnimationStatus);
  }

  TodoModel todo;
  TodoStatus status;
  Size size = new Size(ui.window.size.width, 0.0);
  double position = 0.0;
  double lastDelta;

  final double dragThreshold = ui.window.size.width / 2 * 0.75;

  final AnimatedValue<double> snapValue =
      new AnimatedValue<double>(1.0, end: 0.0, curve: Curves.easeOut);

  /// Override `initState()`.
  @override
  void initState() {
    super.initState();

    todo = config.todo;
  }

  void dispose() {
    snapPerformance?.stop();
    super.dispose();
  }

  void handleSnapAnimationStatus(PerformanceStatus update) {
    if (update == PerformanceStatus.completed) {
      setState(() {
        snapPerformance.progress = 0.0;
        position = 0.0;

        // Make sure the right thing happens after the snap animation.
        switch (status) {
          case TodoStatus.completing:
            todo.completed = true;
            status = TodoStatus.idle;
            break;
          case TodoStatus.deleting:
            config.onDelete(todo);
            break;
          default:
            status = TodoStatus.idle;
        }
      });
    }
  }

  void handlePointerDown(PointerDownEvent event) {
    drag.addPointer(event);
  }

  void handleDragStart(Point globalPosition) {
    position = 0.0;
  }

  void handleDragUpdate(double delta) {
    double update = position + delta;

    // NOTE: My eyes might be playing tricks on me but I think this prevents
    // some jitter while dragging a Todo horizonatlly.
    if (position != update) {
      bool pastThreshold = update.abs() > dragThreshold;

      // Prevent the drag from moving past the treshold.
      if (!pastThreshold) {
        setState(() {
          lastDelta = delta;
          position = update;

          double statusThreshold = dragThreshold / 2;

          // Update status based on the current position.
          if (position.abs() > statusThreshold) {
            if (position.isNegative) {
              // Dragging to the left (revealing the delete icon).
              status = TodoStatus.deleting;
            } else {
              // Dragging to the right (revealing the complete icon).
              status = TodoStatus.completing;
            }
          } else {
            // When dragging back and forth between the original position and
            // the status threshold return the item to the idle state.
            status = TodoStatus.idle;
          }
        });
      }
    }
  }

  void handleDragEnd(Offset velocity) {
    snapPerformance.play();
  }

  void handleResize(Size update) {
    setState(() {
      size = update;
    });
  }

  Widget build(BuildContext context) {
    Widget overlay = new BuilderTransition(
        variables: <AnimatedValue<double>>[snapPerformance.variable],
        performance: snapPerformance.view, builder: (BuildContext context) {
      double left = snapValue.value.clamp(0.0, 1.0) * position;

      return new Positioned(
          width: size.width,
          left: left,
          child: new TodoItemBody(todo: todo, status: status));
    });

    List<Widget> children = [
      // NOTE: This instance of TodoItemBody will never be seen, it is used
      // entirely for sizing purposes and appears behind the action icons
      // below. The visible instance is inside of a positioned element on top
      // of the stack and as a result will lack a hight constraint.
      new TodoItemBody(todo: todo, onResize: handleResize),
    ];

    Widget background = new Container(
        decoration: new BoxDecoration(
            backgroundColor: Theme.of(context).canvasColor,
            border: new Border(
                bottom: new BorderSide(
                    color: Theme.of(context).dividerColor, width: 1.0))),
        height: size.height,
        child: new Row(<Widget>[
          new Flexible(
              child: new Container(
                  child: new Align(
                      child: new Icon(
                          icon: "action/check_circle",
                          color: IconThemeColor.white),
                      alignment: const FractionalOffset(0.0, 0.5)),
                  decoration: new BoxDecoration(
                      backgroundColor: Colors.greenAccent[100]),
                  padding: const EdgeDims.all(24.0))),
          new Flexible(
              child: new Container(
                  child: new Align(
                      child: new Icon(
                          icon: "action/delete", color: IconThemeColor.white),
                      alignment: const FractionalOffset(1.0, 0.5)),
                  decoration: new BoxDecoration(
                      backgroundColor: Colors.redAccent[100]),
                  padding: const EdgeDims.all(24.0)))
        ]));

    children.add(background);
    children.add(overlay);

    return new Listener(
        onPointerDown: handlePointerDown,
        behavior: HitTestBehavior.translucent,
        child: new Stack(children));
  }
}

typedef void TodoHandleResize(Size);

class TodoItemBody extends StatelessComponent {
  TodoItemBody({Key key, this.todo, this.status, this.onResize});

  final TodoModel todo;
  final TodoHandleResize onResize;
  final TodoStatus status;

  void maybeCallResize(Size size) {
    if (onResize != null) {
      onResize(size);
    }
  }

  Widget build(BuildContext context) {
    Color backgroundColor;

    switch (status) {
      case TodoStatus.completing:
        backgroundColor = Colors.greenAccent[100];
        break;
      case TodoStatus.deleting:
        backgroundColor = Colors.redAccent[100];
        break;
      default:
        backgroundColor = Theme.of(context).canvasColor;
    }

    String message = todo.title;

    if (todo.completed) {
      message = "COMPLETED: ${todo.title}";
    }

    return new SizeObserver(
        onSizeChanged: maybeCallResize,
        child: new Container(
            decoration: new BoxDecoration(backgroundColor: backgroundColor),
            child: new Padding(
                padding: const EdgeDims.all(24.0),
                child: new Text(message))));
  }
}
