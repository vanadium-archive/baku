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

Future<List<String>> getAndroidDeviceIDs() async {
  List<String> androidIDs = <String>[];
  Process process = await Process.start('adb', ['devices']);
  RegExp androidIDPattern = new RegExp(r'^(\S+)\s+device$');
  Stream lineStream = process.stdout
                             .transform(new Utf8Decoder())
                             .transform(new LineSplitter());
  await for (var line in lineStream) {
    Match androidIDMatcher = androidIDPattern.firstMatch(line.toString());
    if (androidIDMatcher != null) {
      String androidID = androidIDMatcher.group(1);
      androidIDs.add(androidID);
    }
  }
  return androidIDs;
}

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

  ProcessResult wakeUpAndUnlockProcessResult = Process.runSync(
    'adb',
    ['-s', '${device.id}', 'shell', 'input', 'keyevent', 'KEYCODE_MENU']
  );

  return wakeUpAndUnlockProcessResult.exitCode;
}

// Uninstall an Android app
Future<int> uninstallAndroidTestedApp(DeviceSpec spec, Device device) async {
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
    printTrace(
      'Uninstall $packageName on device ${device.id}: ${line.toString().trim()}'
    );
  }

  uninstallProcess.stderr.drain();
  return uninstallProcess.exitCode;
}

/// Get device property
Future<String> getAndroidProperty(String deviceID, String propName) async {
  ProcessResult results = await Process.run(
    'adb',
    ['-s', deviceID, 'shell', 'getprop', propName]
  );
  return results.stdout.toString().trim();
}

/// Get device pixels and dpi to compute screen diagonal size in inches
Future<String> getAndroidScreenSize(String deviceID) async {
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

  return categorizeScreenSize(diagonalSize);
}

Future<Device> collectAndroidDeviceProps(String deviceID, {String groupKey}) async {
  return new Device(
    properties: <String, String> {
      'platform': 'android',
      'device-id': deviceID,
      'model-name': await getAndroidProperty(deviceID, 'ro.product.model'),
      'os-version': expandOSVersion(
        await getAndroidProperty(deviceID, 'ro.build.version.release')
      ),
      'screen-size': await getAndroidScreenSize(deviceID)
    },
    groupKey: groupKey
  );
}
