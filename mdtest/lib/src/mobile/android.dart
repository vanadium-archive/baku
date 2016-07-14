// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../globals.dart';
import '../util.dart';

const String lockProp = 'mHoldingWakeLockSuspendBlocker';

/// Check if the device is locked
Future<bool> _deviceIsLocked(Device device) async {
  Process process = await Process.start(
    'adb',
    ['-s', '${device.id}', 'shell', 'dumpsys', 'power']
  );
  bool isLocked;
  RegExp lockStatusPattern = new RegExp(lockProp + r'=(.*)');
  Stream lineStream = process.stdout
                        .transform(new Utf8Decoder())
                        .transform(new LineSplitter());
  await for (var line in lineStream) {
    Match lockMatcher = lockStatusPattern.firstMatch(line.toString());
    if (lockMatcher != null) {
      isLocked = lockMatcher.group(1) == 'false';
      break;
    }
  }

  process.stderr.drain();
  await process.exitCode;

  return isLocked;
}

/// Unlock devices if the device is locked
Future<int> unlockDevice(Device device) async {

  bool isLocked = await _deviceIsLocked(device);

  if (isLocked == null) {
    printError('adb error: cannot find device $lockProp property');
    return 1;
  }

  if (!isLocked) return 0;

  Process wakeUpAndUnlockProcess = await Process.start(
    'adb',
    ['-s', '${device.id}', 'shell', 'input', 'keyevent', 'KEYCODE_MENU']
  );
  wakeUpAndUnlockProcess.stdout.drain();
  wakeUpAndUnlockProcess.stderr.drain();

  return await wakeUpAndUnlockProcess.exitCode;
}

/// Uninstall tested apps
Future<int> uninstallTestedApps(Map<DeviceSpec, Device> deviceMapping) async {
  int result = 0;

  for (DeviceSpec spec in deviceMapping.keys) {
    Device device = deviceMapping[spec];

    String androidManifestPath
      = normalizePath(spec.appRootPath, 'android/AndroidManifest.xml');
    String androidManifest = await new File(androidManifestPath).readAsString();

    RegExp packagePattern
      = new RegExp(r'<manifest[\s\S]*?package="(\S+)"\s+[\s\S]*?>', multiLine: true);
    Match packageMatcher = packagePattern.firstMatch(androidManifest);
    if (packageMatcher == null) {
      printError('Package name not found in $androidManifestPath');
      return 1;
    }
    String packageName = packageMatcher.group(1);

    Process uninstallProcess = await Process.start(
      'adb',
      ['-s', '${device.id}', 'uninstall', '$packageName']
    );

    Stream lineStream = uninstallProcess.stdout
                         .transform(new Utf8Decoder())
                         .transform(new LineSplitter());
    await for (var line in lineStream) {
      printTrace('Uninstall $packageName on device ${device.id}: ${line.toString().trim()}');
    }

    uninstallProcess.stderr.drain();
    result += await uninstallProcess.exitCode;
  }

  if (result != 0) {
    printError('Cannot uninstall testing apps from devices');
    return 1;
  }
  return 0;
}

/// Get device property
Future<String> getProperty(String deviceID, String propName) async {
  ProcessResult results = await Process.run(
    'adb',
    ['-s', deviceID, 'shell', 'getprop', propName]
  );
  return results.stdout.toString().trim();
}

/// Get device pixels and dpi to compute screen diagonal size in inches
Future<String> getScreenSize(String deviceID) async {
  Process sizeProcess = await Process.start(
    'adb',
    ['-s', '$deviceID', 'shell', 'wm', 'size']
  );
  RegExp sizePattern = new RegExp(r'Physical size:\s*(\d+)x(\d+)');
  Stream sizeLineStream = sizeProcess.stdout
                                     .transform(new Utf8Decoder())
                                    .transform(new LineSplitter());
  int xSize;
  int ySize;
  await for (var line in sizeLineStream) {
    Match sizeMatcher = sizePattern.firstMatch(line.toString());
    if (sizeMatcher != null) {
      xSize = int.parse(sizeMatcher.group(1));
      ySize = int.parse(sizeMatcher.group(2));
      break;
    }
  }

  if (xSize == null || ySize == null) {
    printError('Screen size not found.');
    return null;
  }

  sizeProcess.stderr.drain();

  Process densityProcess = await Process.start(
    'adb',
    ['-s', '$deviceID', 'shell', 'wm', 'density']
  );
  RegExp densityPattern = new RegExp(r'Physical density:\s*(\d+)');
  Stream densityLineStream = densityProcess.stdout
                                           .transform(new Utf8Decoder())
                                           .transform(new LineSplitter());
  int density;
  await for (var line in densityLineStream) {
    Match densityMatcher = densityPattern.firstMatch(line.toString());
    if (densityMatcher != null) {
      density = int.parse(densityMatcher.group(1));
      break;
    }
  }

  if (density == null) {
    printError('Density not found.');
    return null;
  }

  densityProcess.stderr.drain();

  double xInch = xSize / density;
  double yInch = ySize / density;
  double diagonalSize = sqrt(xInch * xInch + yInch * yInch);

  if (diagonalSize < 3.5) return 'small';
  if (diagonalSize < 5) return 'normal';
  if (diagonalSize < 8) return 'large';
  return 'xlarge';
}
