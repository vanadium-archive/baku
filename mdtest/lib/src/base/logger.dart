// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

abstract class Logger {
  void info(String message);
  void error(String message);
}

class StdoutLogger extends Logger {
  @override
  void info(String message) {
    stderr.writeln('[info ] $message');
  }

  @override
  void error(String message) {
    stderr.writeln('[error] $message');
  }
}
