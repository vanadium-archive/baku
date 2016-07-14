// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

abstract class Logger {
  void info(String message);
  void error(String message);
  void trace(String message);
}

class StdoutLogger extends Logger {
  @override
  void info(String message) {
    stderr.writeln('[INFO] $message');
  }

  @override
  void error(String message) {
    stderr.writeln('[ERROR] $message');
  }

  @override
  void trace(String message) {}
}

class VerboseLogger extends Logger {
  @override
  void info(String message) {
    stderr.writeln('[INFO] $message');
  }

  @override
  void error(String message) {
    stderr.writeln('[ERROR] $message');
  }

  @override
  void trace(String message) {
    stderr.writeln('[TRACE] $message');
  }
}
