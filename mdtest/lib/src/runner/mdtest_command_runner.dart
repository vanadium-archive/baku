// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import '../base/logger.dart';
import '../globals.dart';

class MDTestCommandRunner extends CommandRunner {
  MDTestCommandRunner() : super(
    'mdtest',
    'Launch mdtest and run tests'
  ) {
    argParser.addFlag('verbose',
        abbr: 'v',
        negatable: false,
        help: 'Noisy logging, including all shell commands executed.');
  }

  @override
  Future<dynamic> run(Iterable<String> args) {
    return super.run(args).then((dynamic result) {
      return result;
    });
  }

  @override
  Future<int> runCommand(ArgResults globalResults) async {
    if (globalResults['verbose'])
      defaultLogger = new VerboseLogger();
    return await super.runCommand(globalResults);
  }
}
