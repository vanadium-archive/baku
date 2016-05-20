// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'task_data.dart';

class TaskListData {
  String uuid;
  String name;
  int createdAt;
  int updatedAt;
  final Map<String, TaskData> tasks = <String, TaskData>{};

  TaskListData({this.uuid}) {
    int now = new DateTime.now().millisecondsSinceEpoch;
    uuid ??= new Uuid().v4();
    createdAt = now;
    updatedAt = now;
  }

  Key get key => new ObjectKey(this);
}
