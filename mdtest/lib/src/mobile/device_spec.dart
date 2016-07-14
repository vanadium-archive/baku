// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'device.dart';
import 'key_provider.dart';
import '../globals.dart';
import '../util.dart';

class DeviceSpec implements ClusterKeyProvider {
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
  String clusterKey() {
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

Future<dynamic> loadSpecs(String specsPath) async {
  try {
    // Read specs file into json format
    dynamic newSpecs = JSON.decode(await new File(specsPath).readAsString());
    // Get the parent directory of the specs file
    String rootPath = new File(specsPath).parent.absolute.path;
    // Normalize the 'test-path' in the specs file
    // newSpecs['test-path'] = normalizePath(rootPath, newSpecs['test-path']);
    newSpecs['test-paths']
      = newSpecs['test-paths'].map(
        (String testPath) => normalizePath(rootPath, testPath)
      );
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
    printError('Unknown Exception details:\n $e');
    exit(1);
  }
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
