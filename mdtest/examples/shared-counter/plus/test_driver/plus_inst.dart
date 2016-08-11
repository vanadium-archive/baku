// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter_driver/driver_extension.dart';
import 'package:plus/main.dart' as plusapp;

void main() {
  enableFlutterDriverExtension();
  plusapp.main();
}
