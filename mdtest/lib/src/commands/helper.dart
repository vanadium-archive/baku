// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../mobile/android.dart';
import '../globals.dart';

class MDTestRunner {
  List<Process> appProcesses;

  MDTestRunner() {
    appProcesses = <Process>[];
  }

  /// Invoke runApp function for each device spec to device mapping in parallel
  Future<int> runAllApps(Map<DeviceSpec, Device> deviceMapping) async {
    List<Future<int>> runAppList = <Future<int>>[];
    for (DeviceSpec deviceSpec in deviceMapping.keys) {
      Device device = deviceMapping[deviceSpec];
      runAppList.add(runApp(deviceSpec, device));
    }
    int res = 0;
    List<int> results = await Future.wait(runAppList);
    for (int result in results)
        res += result;
    return res == 0 ? 0 : 1;
  }

  /// Create a process that runs 'flutter run ...' command which installs and
  /// starts the app on the device.  The function finds a observatory port
  /// through the process output.  If no observatory port is found, then report
  /// error.
  Future<int> runApp(DeviceSpec deviceSpec, Device device) async {
    if (await unlockDevice(device) != 0) {
      printError('Device ${device.id} fails to wake up.');
      return 1;
    }

    Process process = await Process.start(
      'flutter',
      ['run', '-d', '${device.id}', '--target=${deviceSpec.appPath}'],
      workingDirectory: deviceSpec.appRootPath
    );
    appProcesses.add(process);
    Stream lineStream = process.stdout
                               .transform(new Utf8Decoder())
                               .transform(new LineSplitter());
    RegExp portPattern = new RegExp(r'Observatory listening on (http.*)');
    await for (var line in lineStream) {
      print(line.toString().trim());
      Match portMatch = portPattern.firstMatch(line.toString());
      if (portMatch != null) {
        deviceSpec.observatoryUrl = portMatch.group(1);
        break;
      }
    }

    process.stderr.drain();

    if (deviceSpec.observatoryUrl == null) {
      printError('No observatory url is found.');
      return 1;
    }

    return 0;
  }

  /// Create a process and invoke 'dart testPath' to run the test script.  After
  /// test result is returned (either pass or fail), kill all app processes and
  /// return the current process exit code
  Future<int> runTest(String testPath) async {
    Process process = await Process.start('dart', ['$testPath']);
    RegExp testStopPattern = new RegExp(r'All tests passed|Some tests failed');
    Stream stdoutStream = process.stdout
                                 .transform(new Utf8Decoder())
                                 .transform(new LineSplitter());
    await for (var line in stdoutStream) {
      print(line.toString().trim());
      if (testStopPattern.hasMatch(line.toString()))
        break;
    }
    killAppProcesses();
    process.stderr.drain();
    return await process.exitCode;
  }

  /// Kill all app processes
  Future<Null> killAppProcesses() async {
    for (Process process in appProcesses) {
      process.kill();
    }
  }
}
