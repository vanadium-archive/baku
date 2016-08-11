// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import '../runner/mdtest_command.dart';
import '../globals.dart';
import '../report/test_report.dart';
import '../report/coverage_report.dart';

class GenerateCommand extends MDTestCommand {

  @override
  final String name = 'generate';

  @override
  final String description
    = 'Generate code coverage or test output web report.  Examples:\n'
      'mdtest generate --report-type coverage '
      '--load-report-data path/to/coverage.lcov '
      '--lib path/to/lib --output out\n'
      'mdtest generate --report-type test '
      '--load-report-data path/to/report_data.json --output out';

  @override
  Future<int> runCore() async {
    printInfo('Running "mdtest generate command" ...');
    String reportDataPath = argResults['load-report-data'];
    String outputPath = argResults['output'];
    String reportType = argResults['report-type'];
    if (reportType == 'test') {
      printInfo('Generating test report to $outputPath.');
      TestReport testReport = new TestReport(reportDataPath, outputPath);
      testReport.writeReport();
    }
    if (reportType == 'coverage') {
      printInfo('Generating code coverage report to $outputPath.');
      String libPath = argResults['lib'];
      CoverageReport coverageReport
        = new CoverageReport(reportDataPath, libPath, outputPath);
      coverageReport.writeReport();
    }
    return 0;
  }

  void printGuide(String guide) {
    guide.split('\n').forEach((String line) => printInfo(line));
  }

  GenerateCommand() {
    usesReportTypeOption();
    argParser.addOption(
      'load-report-data',
      defaultsTo: null,
      help:
        'Path to load the report data.  '
        'The report data could be either lcov format for code coverage, '
        'or JSON format for test output.'
    );
    argParser.addOption(
      'lib',
      defaultsTo: null,
      help:
        'Path to the flutter lib folder that contains all source code of your '
        'flutter application.  The source code should be what the code coverage '
        'report data refers to.  This option is only used when --report-type '
        'is set to `coverage`.'
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: null,
      help:
        'Path to generate a web report.  The path should either not exist or '
        'point to a directory.  If the path does not exist, a new directory '
        'will be created using that path.'
    );
  }
}
