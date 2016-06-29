// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../mobile/device_util.dart';
import '../globals.dart';
import '../runner/mdtest_command.dart';

class RunCommand extends MDTestCommand {

  @override
  final String name = 'run';

  @override
  final String description = 'Run multi-device driver tests';

  dynamic _specs;

  List<Device> _devices;

  @override
  Future<int> runCore() async {
    print('Running "mdtest run command" ...');

    this._specs = await loadSpecs(argResults['specs']);
    print(_specs);

    this._devices = await getDevices();
    if (_devices.isEmpty) {
      printError('No device found.');
      return 1;
    }

    List<DeviceSpec> allDeviceSpecs
      = await constructAllDeviceSpecs(_specs['devices']);
    Map<DeviceSpec, Set<Device>> individualMatches
      = findIndividualMatches(allDeviceSpecs, _devices);
    Map<DeviceSpec, Device> deviceMapping
      = findMatchingDeviceMapping(allDeviceSpecs, individualMatches);
    if(deviceMapping == null) {
      printError('No device specs to devices mapping is found.');
      return 1;
    }

    if (await runAllApps(deviceMapping) != 0) {
      printError('Error when running applications');
      return 1;
    }

    await storeMatches(deviceMapping);

    if (await runTest(_specs['test-path']) != 0) {
      printError('Test execution exit with error.');
      return 1;
    }

    return 0;
  }

  RunCommand() {
    usesSpecsOption();
  }
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

/// Find all matched devices for each device spec
Map<DeviceSpec, Set<Device>> findIndividualMatches(
  List<DeviceSpec> deviceSpecs,
  List<Device> devices) {
  Map<DeviceSpec, Set<Device>> individualMatches
    = new Map<DeviceSpec, Set<Device>>();
  for(DeviceSpec deviceSpecs in deviceSpecs) {
    Set<Device> matchedDevices = new Set<Device>();
    for(Device device in devices) {
      if(deviceSpecs.matches(device))
        matchedDevices.add(device);
    }
    individualMatches[deviceSpecs] = matchedDevices;
  }
  return individualMatches;
}

/// Return the first device spec to device matching, null if no such matching
Map<DeviceSpec, Device> findMatchingDeviceMapping(
  List<DeviceSpec> deviceSpecs,
  Map<DeviceSpec, Set<Device>> individualMatches) {
  Map<DeviceSpec, Device> deviceMapping = <DeviceSpec, Device>{};
  Set<Device> visited = new Set<Device>();
  if (!_findMatchingDeviceMapping(0, deviceSpecs, individualMatches,
                                  visited, deviceMapping)) {
    return null;
  }
  return deviceMapping;
}

/// Find a mapping that matches every device spec to a device. If such
/// mapping is not found, return false, otherwise return true.
bool _findMatchingDeviceMapping(
  int order,
  List<DeviceSpec> deviceSpecs,
  Map<DeviceSpec, Set<Device>> individualMatches,
  Set<Device> visited,
  Map<DeviceSpec, Device> deviceMapping
) {
  if(order == deviceSpecs.length) return true;
  DeviceSpec deviceSpec = deviceSpecs[order];
  Set<Device> matchedDevices = individualMatches[deviceSpec];
  for(Device candidate in matchedDevices) {
    if(visited.add(candidate)) {
      deviceMapping[deviceSpec] = candidate;
      if(_findMatchingDeviceMapping(order + 1, deviceSpecs, individualMatches,
                                    visited, deviceMapping))
        return true;
      else {
        visited.remove(candidate);
        deviceMapping.remove(deviceSpec);
      }
    }
  }
  return false;
}

List<Process> appProcesses = <Process>[];

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
  Process process = await Process.start(
    'flutter',
    ['run', '-d', device.id, '--target=${deviceSpec.appPath}'],
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

/// Store the specs to device mapping as a system temporary file.  The file
/// stores device nickname as well as device id and observatory port for
/// each device
Future<Null> storeMatches(Map<DeviceSpec, Device> deviceMapping) async {
  Map<String, dynamic> matchesData = new Map<String, dynamic>();
  deviceMapping.forEach((DeviceSpec specs, Device device) {
    matchesData[specs.nickName] =
    {
      'device-id': device.id,
      'observatory-url': specs.observatoryUrl
    };
  });
  Directory systemTempDir = Directory.systemTemp;
  File tempFile = new File('${systemTempDir.path}/$defaultTempSpecsName');
  if(await tempFile.exists())
    await tempFile.delete();
  File file = await tempFile.create();
  await file.writeAsString(JSON.encode(matchesData));
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
    if (testStopPattern.hasMatch(line.toString())) {
      process.stderr.drain();
      killAllProcesses(appProcesses);
      break;
    }
  }
  return await process.exitCode;
}

/// Kill all given processes
Future<Null> killAllProcesses(List<Process> processes) async {
  for (Process process in processes) {
    process.kill();
  }
}
