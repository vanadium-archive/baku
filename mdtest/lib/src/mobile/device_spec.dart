// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'device.dart';
import 'key_provider.dart';
import '../globals.dart';

class DeviceSpec implements ClusterKeyProvider {
  DeviceSpec(
    {
      this.nickName,
      this.deviceID,
      this.deviceModelName,
      this.appRootPath,
      this.appPath,
      this.observatoryUrl
    }
  );

  final String nickName;
  final String deviceID;
  final String deviceModelName;
  final String appRootPath;
  final String appPath;
  String observatoryUrl;

  // TODO(kaiyuanw): rewrite matches function later if necessary
  bool matches(Device device) {
    if(deviceID == device.id) {
      return deviceModelName == null ?
               true : deviceModelName == device.modelName;
    } else {
      return deviceID == null ?
               (deviceModelName == null ?
                 true : deviceModelName == device.modelName)
               : false;
    }
  }

  @override
  String clusterKey() {
    return appPath;
  }

  @override
  String toString() => '<nickname: $nickName, id: $deviceID, '
                       'model name: $deviceModelName, port: $observatoryUrl, '
                       'app path: $appPath>';
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

/// Build a list of device specs from mappings loaded from JSON .spec file
Future<List<DeviceSpec>> constructAllDeviceSpecs(dynamic allSpecs) async {
  List<DeviceSpec> deviceSpecs = <DeviceSpec>[];
  for(String name in allSpecs.keys) {
    Map<String, String> specs = allSpecs[name];
    deviceSpecs.add(
      new DeviceSpec(
        nickName: name,
        deviceID: specs['device-id'],
        deviceModelName: specs['model-name'],
        appRootPath: specs['app-root'],
        appPath: specs['app-path']
      )
    );
  }
  return deviceSpecs;
}
