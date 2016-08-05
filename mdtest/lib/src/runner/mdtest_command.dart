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
  bool _usesSaveTestReportOption = false;
  bool _usesReportTypeOption = false;

  void usesSpecsOption() {
    argParser.addOption(
      'spec',
      defaultsTo: null,
      help:
        'Path to the test spec file that specifies devices that you '
        'want your applications to run on.'
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

  void usesSaveTestReportOption() {
    argParser.addOption(
      'save-report-data',
      defaultsTo: null,
      help:
        'Path to save the test output report data.  '
        'The report will be saved in JSON format.'
    );
    _usesSaveTestReportOption = true;
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

  void usesReportTypeOption() {
    argParser.addOption('report-type',
      defaultsTo: null,
      allowed: [
        'test',
        'coverage'
      ],
      help: 'Whether to generate a test report or a code coverage report.'
    );
    _usesReportTypeOption = true;
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
        printError('Spec file path is not specified.');
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
          printError(
            'Spec template file "$specTemplatePath" is a directory.  '
            'A file path is expected.'
          );
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
          printError(
            'Test template file "$testTemplatePath" is a directory.  '
            'A file path is expected.'
          );
          return false;
        }
      }
    }

    if (_usesSaveTestReportOption) {
      String savedReportPath = argResults['save-report-data'];
      if (savedReportPath != null) {
        if (argResults['format'] != 'tap') {
          printError(
            'The --save-report-data option must be used with TAP test output '
            'format.  Please set --format to tap.'
          );
          return false;
        }
        if (!savedReportPath.endsWith('.json')) {
          printError(
            'Report data file must have .json suffix (found "$savedReportPath").'
          );
          return false;
        }
        if (FileSystemEntity.isDirectorySync(savedReportPath)) {
          printError('Report data file "$savedReportPath" is a directory.');
          return false;
        }
      }
    }

    if (_usesReportTypeOption) {
      String reportType = argResults['report-type'];
      if (reportType == null) {
        printError(
          'You must specify a report-type.  '
          'Only "test" and "coverage" is allowed.'
        );
        return false;
      }
      // Report data path cannot be null and must be an existing file
      String loadReportPath = argResults['load-report-data'];
      if (loadReportPath == null) {
        printError('You must specify a path to load the report data.');
        return false;
      }
      if (!FileSystemEntity.isFileSync(loadReportPath)) {
        printError(
          'Report data path $loadReportPath is not a file.  '
          'An existing file path is expected.'
        );
        return false;
      }
      // Output path cannot be null and must either point to an empty directory,
      // or not exist
      String outputPath = argResults['output'];
      if (outputPath == null) {
        printError('You must specify a path to generate the web report.');
        return false;
      }
      if (FileSystemEntity.isFileSync(outputPath)) {
        printError(
          'Output path $outputPath is a file.  '
          'An empty directory path or non-existing path is expected.'
        );
        return false;
      }

      // Lib path that points to the source code that code coverage report
      // refers to
      String libPath = argResults['lib'];

      if (reportType == 'coverage') {
        if (!loadReportPath.endsWith('.lcov')) {
          printError(
            'Coverage report data path $loadReportPath must have .lcov suffix'
          );
          return false;
        }
        if (libPath == null) {
          printError(
            'A lib path is expected in code coverage report generating mode.'
          );
          return false;
        }
        if (!FileSystemEntity.isDirectorySync(libPath)) {
          printError(
            'Lib path $libPath is not a directory.  '
            'A source code directory path is expected.'
          );
          return false;
        }
      }

      if (reportType == 'test') {
        if (!loadReportPath.endsWith('.json')) {
          printError(
            'Test report data path $loadReportPath must have .json suffix'
          );
          return false;
        }
        if (libPath != null) {
          printError(
            'A lib path is not expected in test report generating mode.'
          );
          return false;
        }
      }

    }
    return true;
  }
}
