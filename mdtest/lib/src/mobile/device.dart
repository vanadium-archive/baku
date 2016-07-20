// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'key_provider.dart';
import 'android.dart';

class Device implements GroupKeyProvider {
  Device({
    this.properties,
    String groupKey
  }) {
    this._groupKey = groupKey;
  }

  Map<String, String> properties;
  String _groupKey;

  String get id => properties['device-id'];
  String get modelName => properties['model-name'];
  String get screenSize => properties['screen-size'];
  String get osVersion => properties['os-version'];
  String get apiLevel => properties['api-level'];

  /// default to 'device-id'
  @override
  String groupKey() {
    return properties[_groupKey ?? 'device-id'];
  }

  @override
  String toString()
    => '<device-id: $id, model-name: $modelName, screen-size: $screenSize, '
       'os-version: $osVersion, api-level: $apiLevel>';
}

Future<List<Device>> getDevices({String groupKey}) async {
  List<Device> devices = <Device>[];
  await _getDeviceIDs().then((List<String> ids) async {
    for(String id in ids) {
      devices.add(await _collectDeviceProps(id, groupKey: groupKey));
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
  RegExp startPattern = new RegExp(r'\d+ connected device|No devices detected');
  RegExp deviceIDPattern = new RegExp(r'\d+ ms •.*•\s+(\S+)\s+•.*');
  RegExp stopPattern = new RegExp(r"'flutter devices' took \d+ms; exiting with code");
  await for (var line in lineStream) {
    if (!startReading && startPattern.hasMatch(line.toString())) {
      startReading = true;
      continue;
    }

    if (stopPattern.hasMatch(line.toString()))
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

Future<Device> _collectDeviceProps(String deviceID, {String groupKey}) async {
  return new Device(
    properties: <String, String> {
      'device-id': deviceID,
      'model-name': await getProperty(deviceID, 'ro.product.model'),
      'os-version': await getProperty(deviceID, 'ro.build.version.release'),
      'api-level': await getProperty(deviceID, 'ro.build.version.sdk'),
      'screen-size': await getScreenSize(deviceID)
    },
    groupKey: groupKey
  );
}
