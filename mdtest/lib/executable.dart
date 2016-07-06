// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'src/commands/run.dart';
import 'src/commands/auto.dart';
import 'src/runner/mdtest_command_runner.dart';

Future<Null> main(List<String> args) async {
  MDTestCommandRunner runner = new MDTestCommandRunner()
    ..addCommand(new RunCommand())
    ..addCommand(new AutoCommand());

    return Chain.capture(() async {
      dynamic result = await runner.run(args);
      exit(result is int ? result : 0);
    }, onError: (dynamic error, Chain chain) {
      print(error);
    });
}
