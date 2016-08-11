// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

import '../util.dart';

// Provide paths which point to the assets directory
String mdtestScriptPath = Platform.script.toFilePath();
int mdtestStart = mdtestScriptPath.lastIndexOf('/mdtest/');
String mdtestRootPath = mdtestScriptPath.substring(0, mdtestStart);
String assetsPath = normalizePath(
  mdtestRootPath,
  'mdtest/dart-packages/mdtest_tools/lib/assets'
);

List<String> get assetItemPaths => <String>[
  normalizePath(assetsPath, 'emerald.png'),
  normalizePath(assetsPath, 'ruby.png'),
  normalizePath(assetsPath, 'report.css')
];
