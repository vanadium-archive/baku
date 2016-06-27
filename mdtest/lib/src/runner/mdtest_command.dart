// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../globals.dart';
import 'mdtest_command_runner.dart';

typedef bool Validator();

abstract class MDTestCommand extends Command {

  MDTestCommand() {
    commandValidator = _commandValidator;
  }

  @override
  MDTestCommandRunner get runner => super.runner;

  bool _usesSpecsOption = false;

  void usesSpecsOption() {
    argParser.addOption(
      'specs',
      defaultsTo: null,
      allowMultiple: false,
      help:
        'Path to the config file that specifies the devices, '
        'apps and debug-ports for testing.'
    );
    _usesSpecsOption = true;
  }

  @override
  Future<int> run() {
    Stopwatch stopwatch = new Stopwatch()..start();
    return _run().then((int exitCode) {
      int ms = stopwatch.elapsedMilliseconds;
      printInfo('"mdtest $name" took ${ms}ms; exiting with code $exitCode.');
      return exitCode;
    });
  }

  Future<int> _run() async {
    if (!commandValidator())
      return 1;
    return await runCore();
  }

  Future<int> runCore();

  Validator commandValidator;

  bool _commandValidator() {
    if (_usesSpecsOption) {
      String specsPath = argResults['specs'];
      if (specsPath == null) {
        printError('Specs file is not set.');
        return false;
      }
      if (!FileSystemEntity.isFileSync(specsPath)) {
        printError('Specs file "$specsPath" not found.');
        return false;
      }
    }
    return true;
  }
}
