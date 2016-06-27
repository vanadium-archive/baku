// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../mobile/device.dart';
import '../mobile/device_util.dart';
import '../globals.dart';
import '../runner/mdtest_command.dart';

class RunCommand extends MDTestCommand {

  @override
  final String name = 'run';

  @override
  final String description = 'Run multi-device driver tests';

  dynamic _specs;

  List<Device> _devices;

  @override
  Future<int> runCore() async {
    print('Running "mdtest run command" ...');
    this._specs = await loadSpecs(argResults['specs']);
    print(_specs);
    this._devices = await getDevices();
    if (_devices.isEmpty) {
      printError('No device found.');
      return 1;
    }
    return 0;
  }

  RunCommand() {
    usesSpecsOption();
  }
}

Future<dynamic> loadSpecs(String specsPath) async {
  try {
    // Read specs file into json format
    dynamic newSpecs = JSON.decode(await new File(specsPath).readAsString());
    // Get the parent directory of the specs file
    String rootPath = new File(specsPath).parent.absolute.path;
    // Normalize the 'test-path' in the specs file
    newSpecs['test-path'] = normalizePath(rootPath, newSpecs['test-path']);
    // Normalize the 'app-path' in the specs file
    newSpecs['devices'].forEach((String name, Map<String, String> map) {
      map['app-path'] = normalizePath(rootPath, map['app-path']);
      map['app-root'] = normalizePath(rootPath, map['app-root']);
    });
    return newSpecs;
  } on FileSystemException {
    printError('File $specsPath does not exist.');
    exit(1);
  } on FormatException {
    printError('File $specsPath is not in JSON format.');
    exit(1);
  } catch (e) {
    print('Unknown Exception details:\n $e');
    exit(1);
  }
}

String normalizePath(String rootPath, String relativePath) {
  return path.normalize(path.join(rootPath, relativePath));
}
