// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TodoModel {
  TodoModel({this.id, this.title, this.completed: false}) {
    id ??= new Uuid().v4();
  }

  String id;
  String title;
  bool completed;
  Key get key => new ObjectKey(this);
}
