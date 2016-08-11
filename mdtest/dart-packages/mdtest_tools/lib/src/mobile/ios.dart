// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../globals.dart';
import '../util.dart';

Future<List<String>> getIOSDeviceIDs() async {
  List<String> iosIDs = <String>[];
  if (!os.isMacOS) {
    return iosIDs;
  }
  Process process = await Process.start('mobiledevice', ['list_devices']);
  RegExp iosIDPattern = new RegExp(r'^(.*)$');
  Stream lineStream = process.stdout
                             .transform(new Utf8Decoder())
                             .transform(new LineSplitter());

  await for (var line in lineStream) {
    Match iosIDMatcher = iosIDPattern.firstMatch(line.toString());
    if (iosIDMatcher != null) {
      String iosID = iosIDMatcher.group(1);
      iosIDs.add(iosID);
    }
  }
  return iosIDs;
}

/// Uninstall an ios app
Future<int> uninstallIOSTestedApp(DeviceSpec spec, Device device) async {
  String iosProjectProfilePath
    = normalizePath(spec.appRootPath, 'ios/Runner.xcodeproj/project.pbxproj');
  String iosProjectProfile = await new File(iosProjectProfilePath).readAsString();

  RegExp packagePattern
    = new RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+?);', multiLine: true);
  Match packageMatcher = packagePattern.firstMatch(iosProjectProfile);
  if (packageMatcher == null) {
    printError('Package name not found in $iosProjectProfilePath');
    return 1;
  }
  String packageName = packageMatcher.group(1);

  Process uninstallProcess = await Process.start(
    'mobiledevice',
    ['uninstall_app', '-u', '${device.id}', '$packageName']
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
Future<String> getIOSProperty(String deviceID, String propName) async {
  ProcessResult results = await Process.run(
    'mobiledevice',
    ['get_device_prop', '-u', deviceID, propName]
  );
  return results.stdout.toString().trim();
}

Future<Device> collectIOSDeviceProps(String deviceID, {String groupKey}) async {
  String modelName = iosDeviceInfo['productId-to-modelName'][
    await getIOSProperty(deviceID, 'ProductType')
  ];
  num diagonalSize = iosDeviceInfo['modelName-to-screenSize'][modelName];
  return new Device(
    properties: <String, String> {
      'platform': 'ios',
      'device-id': deviceID,
      'model-name': modelName,
      'os-version': expandOSVersion(
        await getIOSProperty(deviceID, 'ProductVersion')
      ),
      'screen-size': categorizeScreenSize(diagonalSize)
    },
    groupKey: groupKey
  );
}

// The information is based on https://www.theiphonewiki.com/wiki/Models
// For now, we only support iPhone and iPad (mini)
final dynamic iosDeviceInfo =
{
  'productId-to-modelName': {
    // iPhone
    'iPhone1,1': 'iPhone',
    'iPhone1,2': 'iPhone 3G',
    'iPhone2,1': 'iPhone 3GS',
    'iPhone3,1': 'iPhone 4',
    'iPhone3,2': 'iPhone 4',
    'iPhone3,3': 'iPhone 4',
    'iPhone4,1': 'iPhone 4S',
    'iPhone5,1': 'iPhone 5',
    'iPhone5,2': 'iPhone 5',
    'iPhone5,3': 'iPhone 5C',
    'iPhone5,4': 'iPhone 5C',
    'iPhone6,1': 'iPhone 5S',
    'iPhone6,2': 'iPhone 5S',
    'iPhone7,2': 'iPhone 6',
    'iPhone7,1': 'iPhone 6 Plus',
    'iPhone8,1': 'iPhone 6S',
    'iPhone8,2': 'iPhone 6S Plus',
    'iPhone8,4': 'iPhone SE',
    // iPad and iPad mini
    'iPad1,1': 'iPad',
    'iPad2,1': 'iPad 2',
    'iPad2,2': 'iPad 2',
    'iPad2,3': 'iPad 2',
    'iPad2,4': 'iPad 2',
    'iPad3,1': 'iPad 3',
    'iPad3,2': 'iPad 3',
    'iPad3,3': 'iPad 3',
    'iPad3,4': 'iPad 4',
    'iPad3,5': 'iPad 4',
    'iPad3,6': 'iPad 4',
    'iPad4,1': 'iPad Air',
    'iPad4,2': 'iPad Air',
    'iPad4,3': 'iPad Air',
    'iPad5,3': 'iPad Air 2',
    'iPad5,4': 'iPad Air 2',
    'iPad6,3': 'iPad Pro (9.7 inch)',
    'iPad6,4': 'iPad Pro (9.7 inch)',
    'iPad6,7': 'iPad Pro (12.9 inch)',
    'iPad6,8': 'iPad Pro (12.9 inch)',
    'iPad2,5': 'iPad mini',
    'iPad2,6': 'iPad mini',
    'iPad2,7': 'iPad mini',
    'iPad4,4': 'iPad mini 2',
    'iPad4,5': 'iPad mini 2',
    'iPad4,6': 'iPad mini 2',
    'iPad4,7': 'iPad mini 3',
    'iPad4,8': 'iPad mini 3',
    'iPad4,9': 'iPad mini 3',
    'iPad5,1': 'iPad mini 4',
    'iPad5,2': 'iPad mini 4'
  },
  'modelName-to-screenSize': {
    // iPhone
    'iPhone': 3.5,
    'iPhone 3G': 3.5,
    'iPhone 3GS': 3.5,
    'iPhone 4': 3.5,
    'iPhone 4S': 3.5,
    'iPhone 5': 4,
    'iPhone 5S': 4,
    'iPhone 5C': 4,
    'iPhone 6': 4.7,
    'iPhone 6 Plus': 5.5,
    'iPhone 6S': 4.7,
    'iPhone 6S Plus': 5.5,
    'iPhone SE': 4,
    // iPad
    'iPad': 9.7,
    'iPad 2': 9.7,
    'iPad 3': 9.7,
    'iPad 4': 9.7,
    'iPad Air': 9.7,
    'iPad Air 2': 9.7,
    'iPad Pro (9.7 inch)': 9.7,
    'iPad Pro (12.9 inch)': 12.9,
    'iPad mini': 7.9,
    'iPad mini 2': 7.9,
    'iPad mini 3': 7.9,
    'iPad mini 4': 7.9
  }
};
