// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device.dart';

Future<List<Device>> getDevices() async {
  List<Device> devices = <Device>[];
  await _getDeviceIDs().then((List<String> ids) async {
    for(String id in ids) {
      devices.add(await _collectDeviceProps(id));
    }
  });
  return devices;
}

/// Run "flutter devices -v" to collect device ids from the output
Future<List<String>> _getDeviceIDs() async {
  List<String> deviceIDs = <String>[];
  Process process = await Process.start('flutter', ['devices', '-v']);
  Stream lineStream = process.stdout
                             .transform(new Utf8Decoder())
                             .transform(new LineSplitter());
  bool startReading = false;
  RegExp startPattern = new RegExp(r'List of devices attached');
  RegExp deviceIDPattern = new RegExp(r'\s+(\w+)\s+.*');
  RegExp stopPatternWithDevices = new RegExp(r'\d+ connected devices?');
  RegExp stopPatternWithoutDevices = new RegExp(r'No devices detected');
  await for (var line in lineStream) {
    if (!startReading && startPattern.hasMatch(line.toString())) {
      startReading = true;
      continue;
    }

    if (stopPatternWithDevices.hasMatch(line.toString())
        || stopPatternWithoutDevices.hasMatch(line.toString()))
      break;

    if (startReading) {
      Match idMatch = deviceIDPattern.firstMatch(line.toString());
      if (idMatch != null) {
        String deviceID = idMatch.group(1);
        deviceIDs.add(deviceID);
      }
    }
  }

  process.stderr.drain();

  return deviceIDs;
}

Future<Device> _collectDeviceProps(String deviceID) async {
  return new Device(
    id: deviceID,
    modelName: await _getProperty(deviceID, 'ro.product.model')
  );
}

Future<String> _getProperty(String deviceID, String propName) async {
  ProcessResult results = await Process.run('adb', ['-s', deviceID, 'shell', 'getprop', propName]);
  return results.stdout.toString().trim();
}
