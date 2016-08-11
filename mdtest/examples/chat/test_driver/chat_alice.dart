// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:chat/main.dart' as chatapp;

void main() {
  enableFlutterDriverExtension();
  chatapp.start('Alice', 0);
}
