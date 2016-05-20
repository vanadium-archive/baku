// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TaskData {
  String uuid;
  String description;
  bool completed;
  int createdAt;
  int updatedAt;

  // TODO(jxson): implement task.<from/to>JSON.
  TaskData({this.uuid}) {
    int now = new DateTime.now().millisecondsSinceEpoch;
    uuid ??= new Uuid().v4();
    completed = false;
    createdAt = now;
    updatedAt = now;
  }

  Key get key => new ObjectKey(this);
}
