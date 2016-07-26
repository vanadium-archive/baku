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
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Noisy logging, including detailed information '
            'through the entire execution.'
    );
    argParser.addFlag(
      'brief',
      abbr: 'b',
      negatable: false,
      help: 'Disable logging, only report test execution output.'
    );
  }

  @override
  Future<dynamic> run(Iterable<String> args) {
    return super.run(args).then((dynamic result) {
      return result;
    });
  }

  @override
  Future<int> runCommand(ArgResults globalResults) async {
    if (!_commandValidator(globalResults)) {
      return 1;
    }
    if (globalResults['verbose']) {
      defaultLogger = new VerboseLogger();
    }
    if (globalResults['brief']) {
      defaultLogger = new DumbLogger();
      briefMode = true;
    }
    return await super.runCommand(globalResults);
  }

  bool _commandValidator(ArgResults globalResults) {
    if (globalResults['verbose'] && globalResults['brief']) {
      printError('--verbose flag conflicts with --brief flag');
      return false;
    }
    return true;
  }
}
