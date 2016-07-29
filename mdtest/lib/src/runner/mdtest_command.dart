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
  bool _usesSpecTemplateOption = false;
  bool _usesTestTemplateOption = false;

  void usesSpecsOption() {
    argParser.addOption(
      'spec',
      defaultsTo: null,
      help:
        'Path to the config file that specifies the devices, '
        'apps and debug-ports for testing.'
    );
    _usesSpecsOption = true;
  }

  void usesCoverageFlag() {
    argParser.addFlag(
      'coverage',
      defaultsTo: false,
      negatable: false,
      help: 'Whether to collect coverage information.'
    );
  }

  void usesTAPReportOption() {
    argParser.addOption(
      'format',
      defaultsTo: 'none',
      allowed: ['none', 'tap'],
      help: 'Format to be used to display test output result.'
    );
  }

  void usesSpecTemplateOption() {
    argParser.addOption(
      'spec-template',
      defaultsTo: null,
      help:
        'Path to create the test spec template.'
    );
    _usesSpecTemplateOption = true;
  }

  void usesTestTemplateOption() {
    argParser.addOption(
      'test-template',
      defaultsTo: null,
      help:
        'Path to create the test script template.'
    );
    _usesTestTemplateOption = true;
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
      String specsPath = argResults['spec'];
      if (specsPath == null) {
        printError('Spec file is not set.');
        return false;
      }
      if (!specsPath.endsWith('.spec')) {
        printError('Spec file must have .spec suffix');
      }
      if (!FileSystemEntity.isFileSync(specsPath)) {
        printError('Spec file "$specsPath" not found.');
        return false;
      }
    }

    if (_usesSpecTemplateOption) {
      String specTemplatePath = argResults['spec-template'];
      if (specTemplatePath != null) {
        if (!specTemplatePath.endsWith('.spec')) {
          printError(
            'Spec template path must have .spec suffix (found "$specTemplatePath").'
          );
          return false;
        }
        if (FileSystemEntity.isDirectorySync(specTemplatePath)) {
          printError('Spec template file "$specTemplatePath" is a directory.');
          return false;
        }
      }
    }

    if (_usesTestTemplateOption) {
      String testTemplatePath = argResults['test-template'];
      if (testTemplatePath != null) {
        if (!testTemplatePath.endsWith('.dart')) {
          printError(
            'Test template path must have .dart suffix (found "$testTemplatePath").'
          );
          return false;
        }
        if (FileSystemEntity.isDirectorySync(testTemplatePath)) {
          printError('Test template file "$testTemplatePath" is a directory.');
          return false;
        }
      }
    }
    return true;
  }
}
