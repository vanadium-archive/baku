// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

import 'report.dart';
import '../globals.dart';

class CoverageReport extends Report {
  Directory libDirectory;

  CoverageReport(String reportDataPath, String libPath, String outputPath)
    : super(reportDataPath, outputPath) {
    this.libDirectory = new Directory(libPath);
  }

  @override
  void writeReport() {
    // Move the lib folder into the output directory
    Process.runSync('cp', ['-r', libDirectory.path, outputDirectory.path]);
    ProcessResult result = Process.runSync(
      'genhtml',
      ['-o', outputDirectory.path, reportDataFile.path]
    );
    result.stdout.toString().trim().split('\n').forEach(printInfo);
    if (result.stderr.isNotEmpty) {
      result.stderr.trim().split('\n').forEach(
        (String line) => printError(line)
      );
    }
  }
}
