// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'device.dart';
import 'key_provider.dart';
import '../globals.dart';
import '../util.dart';

class DeviceSpec implements GroupKeyProvider {
  DeviceSpec(String nickname, { this.specProperties }) {
    specProperties['nickname'] = nickname;
  }

  Map<String, String> specProperties;

  String get nickName => specProperties['nickname'];
  String get deviceID => specProperties['device-id'];
  String get deviceModelName => specProperties['model-name'];
  String get deviceScreenSize => specProperties['screen-size'];
  String get appRootPath => specProperties['app-root'];
  String get appPath => specProperties['app-path'];
  String get observatoryUrl => specProperties['observatory-url'];
  void set observatoryUrl(String url) {
    specProperties['observatory-url'] = url;
  }

  /// Match if property names are not specified or equal to the device property.
  /// Checked property names includes: device-id, model-name, screen-size
  bool matches(Device device) {
    List<String> checkedProperties = [
      'device-id',
      'model-name',
      'os-version',
      'api-level',
      'screen-size'
    ];
    return checkedProperties.every(
      (String propertyName) => isNullOrEqual(propertyName, device)
    );
  }

  bool isNullOrEqual(String propertyName, Device device) {
    return specProperties[propertyName] == null
           ||
           specProperties[propertyName] == device.properties[propertyName];
  }

  @override
  String groupKey() {
    return appPath;
  }

  @override
  String toString() => '<nickname: $nickName, '
                       'id: $deviceID, '
                       'model name: $deviceModelName, '
                       'screen size: $deviceScreenSize, '
                       'port: $observatoryUrl, '
                       'app path: $appPath>';
}

Future<dynamic> loadSpecs(ArgResults argResults) async {
  String specsPath = argResults['specs'];
  try {
    // Read specs file into json format
    dynamic newSpecs = JSON.decode(await new File(specsPath).readAsString());
    // Get the parent directory of the specs file
    String rootPath = new File(specsPath).parent.absolute.path;
    // Normalize the 'test-path' in the specs file and add extra test paths
    // from the command line argument
    List<String> testPathsFromSpec
      = listFilePathsFromGlobPatterns(rootPath, newSpecs['test-paths']);
    printTrace('Test paths from spec: $testPathsFromSpec');
    List<String> testPathsFromCommandLine
      = listFilePathsFromGlobPatterns(Directory.current.path, argResults.rest);
    printTrace('Test paths from command line: $testPathsFromCommandLine');
    newSpecs['test-paths'] = mergeWithoutDuplicate(
      testPathsFromSpec,
      testPathsFromCommandLine
    );
    // Normalize the 'app-path' in the specs file
    newSpecs['devices']?.forEach((String name, Map<String, String> map) {
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
    printError('Unknown Exception details:\n $e');
    exit(1);
  }
}

/// Check if test spec meets the requirements.  If user does not specify any
/// valid test paths neither from the test spec nor from the command line,
/// report error.  If 'devices' property is not specified, report error.  If
/// no device spec is specified, report error.  If screen size property is not
/// one of 'small', 'normal', 'large' and 'xlarge', report error.  If app-root
/// is not specified or is not a directory, report error.  If appPath is not
/// specified or is not a file, report error.
///
/// Note: If a test path does not exist, it will be ignored and thus does not
/// count as a valid test path.  If device nickname is not unique, json decoder
/// will overwrite the previous device spec associated with the same nickname,
/// thus only the last nickname to device spec pair is used.
int sanityCheckSpecs(dynamic spec, String specsPath) {
  if (spec['test-paths'].isEmpty) {
    printError(
      'No test paths found.  '
      'You must specify at least one test path.'
    );
    return 1;
  }
  dynamic deviceSpecs = spec['devices'];
  if (deviceSpecs == null) {
    printError('"devices" property is not specified in $specsPath');
    return 1;
  }
  if (deviceSpecs.isEmpty) {
    printError('No device spec is found in $specsPath');
    return 1;
  }
  for (String nickname in deviceSpecs.keys) {
    dynamic individualDeviceSpec = deviceSpecs[nickname];
    List<String> screenSizes = <String>['small', 'normal', 'large', 'xlarge'];
    if (individualDeviceSpec['screen-size'] != null
        &&
        !screenSizes.contains(individualDeviceSpec['screen-size'])) {
      printError('Screen size must be one of $screenSizes');
      return 1;
    }
    String appRootPath = individualDeviceSpec['app-root'];
    if (appRootPath == null) {
      printError('Application root path is not specified.');
      return 1;
    }
    if (!FileSystemEntity.isDirectorySync(appRootPath)) {
      printError('Application root path is not a directory.');
      return 1;
    }
    String appPath = individualDeviceSpec['app-path'];
    if (appPath == null) {
      printError('Application path is not specified.');
      return 1;
    }
    if (!FileSystemEntity.isFileSync(appPath)) {
      printError('Application path is not a file.');
      return 1;
    }
  }
  return 0;
}

/// Build a list of device specs from mappings loaded from JSON .spec file
Future<List<DeviceSpec>> constructAllDeviceSpecs(dynamic allSpecs) async {
  List<DeviceSpec> deviceSpecs = <DeviceSpec>[];
  for(String name in allSpecs.keys) {
    Map<String, String> spec = allSpecs[name];
    deviceSpecs.add(
      new DeviceSpec(
        name,
        specProperties: spec
      )
    );
  }
  return deviceSpecs;
}
