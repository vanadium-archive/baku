// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

import '../util.dart';

abstract class Report {
  File reportDataFile;
  Directory outputDirectory;

  Report(String reportDataPath, String outputPath) {
    reportDataFile = new File(reportDataPath);
    outputDirectory = createNewDirectory(outputPath);
  }

  void writeReport();
}
