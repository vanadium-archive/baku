// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'key_provider.dart';
import 'android.dart';
import 'ios.dart';
import 'device_spec.dart';
import '../globals.dart';

class Device implements GroupKeyProvider {
  Device({
    this.properties,
    String groupKey
  }) {
    this._groupKey = groupKey;
  }

  Map<String, String> properties;
  String _groupKey;

  String get platform => properties['platform'];
  String get id => properties['device-id'];
  String get modelName => properties['model-name'];
  String get screenSize => properties['screen-size'];
  String get osVersion => properties['os-version'];

  bool isAndroidDevice() => platform == 'android';
  bool isIOSDevice() => platform == 'ios';

  /// default to 'device-id'
  @override
  String groupKey() {
    if (_groupKey == 'os-version') {
      RegExp majorVersionPattern = new RegExp(r'^(\d+)\.\d+\.\d+$');
      Match majorVersionMatch = majorVersionPattern.firstMatch(osVersion);
      if (majorVersionMatch == null) {
        printError('OS version $osVersion does not match semantic version.');
        return null;
      }
      String majorVersion = majorVersionMatch.group(1);
      return '$platform $majorVersion.x.x';
    }
    return properties[_groupKey ?? 'device-id'];
  }

  @override
  String toString()
    => '<platform: $platform, device-id: $id, model-name: $modelName, '
       'screen-size: $screenSize, os-version: $osVersion>';
}

Future<List<Device>> getDevices({String groupKey}) async {
  List<Device> devices = <Device>[];
  List<String> androidIDs = await getAndroidDeviceIDs();
  List<String> iosIDs = await getIOSDeviceIDs();
  await _getDeviceIDs().then((List<String> ids) async {
    for(String id in ids) {
      if (androidIDs.contains(id)) {
        devices.add(await collectAndroidDeviceProps(id, groupKey: groupKey));
      } else if (iosIDs.contains(id)) {
        devices.add(await collectIOSDeviceProps(id, groupKey: groupKey));
      } else {
        // iOS simulator
        printError('iOS simulator $id is not supported.');
      }
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

String expandOSVersion(String osVersion) {
  RegExp singleNumber = new RegExp(r'^\d+$');
  if (singleNumber.hasMatch(osVersion)) {
    osVersion = '$osVersion.0.0';
  }
  RegExp doubleNumber = new RegExp(r'^\d+\.\d+$');
  if (doubleNumber.hasMatch(osVersion)) {
    osVersion = '$osVersion.0';
  }
  RegExp tripleNumber = new RegExp(r'^\d+\.\d+\.\d+$');
  if (!tripleNumber.hasMatch(osVersion)) {
    throw new FormatException(
      'OS version $osVersion does not match semantic version.'
    );
  }
  return osVersion;
}

String categorizeScreenSize(num diagonalSize) {
  if (diagonalSize < 3.6) return 'small';
  if (diagonalSize < 5) return 'normal';
  if (diagonalSize < 8) return 'large';
  return 'xlarge';
}

/// Uninstall tested apps
Future<int> uninstallTestingApps(
  Map<DeviceSpec, Device> deviceMapping
) async {
  int result = 0;

  for (DeviceSpec spec in deviceMapping.keys) {
    Device device = deviceMapping[spec];
    if (device.isAndroidDevice()) {
      result += await uninstallAndroidTestedApp(spec, device);
    } else if (device.isIOSDevice()) {
      result += await uninstallIOSTestedApp(spec, device);
    } else {
      printError(
        'Cannot uninstall testing app from device ${device.id}.  '
        'Platform ${device.platform} is not supported.'
      );
    }
  }

  if (result != 0) {
    printError('Cannot uninstall testing apps from devices');
    return 1;
  }
  return 0;
}
