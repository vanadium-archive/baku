// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'package:args/command_runner.dart';

class MDTestCommandRunner extends CommandRunner {
  MDTestCommandRunner() : super(
    'mdtest',
    'Launch multi-device apps and run test script'
  );

  @override
  Future<dynamic> run(Iterable<String> args) {
    return super.run(args).then((dynamic result) {
      return result;
    });
  }
}
