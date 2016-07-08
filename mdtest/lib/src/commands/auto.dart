// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'helper.dart';
import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../mobile/key_provider.dart';
import '../mobile/android.dart';
import '../algorithms/coverage.dart';
import '../algorithms/matching.dart';
import '../globals.dart';
import '../runner/mdtest_command.dart';

class AutoCommand extends MDTestCommand {
  @override
  final String name = 'auto';

  @override
  final String description
    = 'Automatically run applications based on a subset of spec to device '
      'settings that maximize the device coverage';

  dynamic _specs;

  List<Device> _devices;

  @override
  Future<int> runCore() async {
    print('Running "mdtest auto command" ...');

    this._specs = await loadSpecs(argResults['specs']);

    this._devices = await getDevices();
    if (_devices.isEmpty) {
      printError('No device found.');
      return 1;
    }

    List<DeviceSpec> allDeviceSpecs
      = await constructAllDeviceSpecs(_specs['devices']);
    Map<DeviceSpec, Set<Device>> individualMatches
      = findIndividualMatches(allDeviceSpecs, _devices);
    List<Map<DeviceSpec, Device>> allDeviceMappings
      = findAllMatchingDeviceMappings(allDeviceSpecs, individualMatches);
    if(allDeviceMappings.isEmpty) {
      printError('No device specs to devices mapping is found.');
      return 1;
    }

    Map<String, List<Device>> deviceClusters = buildCluster(_devices);
    Map<String, List<DeviceSpec>> deviceSpecClusters
      = buildCluster(allDeviceSpecs);

    ClusterInfo clusterInfo = new ClusterInfo(deviceClusters, deviceSpecClusters);
    Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
      = buildCoverage2MatchMapping(allDeviceMappings, clusterInfo);
    Set<Map<DeviceSpec, Device>> chosenMappings
      = findMinimumMappings(cov2match, clusterInfo);
    printMatches(chosenMappings);

    List<int> errRounds = [];
    int roundNum = 1;
    for (Map<DeviceSpec, Device> deviceMapping in chosenMappings) {
      MDTestRunner runner = new MDTestRunner();

      if (await runner.runAllApps(deviceMapping) != 0) {
        printError('Error when running applications');
        await uninstallTestedApps(deviceMapping);
        errRounds.add(roundNum++);
        continue;
      }

      await storeMatches(deviceMapping);

      if (await runner.runTest(_specs['test-path']) != 0) {
        printError('Test execution exit with error.');
        await uninstallTestedApps(deviceMapping);
        errRounds.add(roundNum++);
        continue;
      }

      await uninstallTestedApps(deviceMapping);
    }

    if (errRounds.isNotEmpty) {
      printError('Error in Round #${errRounds.join(", #")}');
      return 1;
    }

    return 0;
  }

  AutoCommand() {
    usesSpecsOption();
  }
}
