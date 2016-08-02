// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'helper.dart';
import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../algorithms/matching.dart';
import '../globals.dart';
import '../runner/mdtest_command.dart';
import '../test/coverage_collector.dart';

class RunCommand extends MDTestCommand {

  @override
  final String name = 'run';

  @override
  final String description = 'Run multi-device driver tests';

  dynamic _specs;

  List<Device> _devices;

  @override
  Future<int> runCore() async {
    printInfo('Running "mdtest run command" ...');

    this._specs = await loadSpecs(argResults);
    if (sanityCheckSpecs(_specs, argResults['spec']) != 0) {
      printError('Test spec does not meet requirements.');
      return 1;
    }

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

    MDTestRunner runner = new MDTestRunner();

    if (await runner.runAllApps(deviceMapping) != 0) {
      printError('Error when running applications');
      await uninstallTestingApps(deviceMapping);
      return 1;
    }

    await storeMatches(deviceMapping);

    bool testsFailed;
    if (argResults['format'] == 'tap') {
      testsFailed = await runner.runAllTestsToTAP(_specs['test-paths']) != 0;
    } else {
      testsFailed = await runner.runAllTests(_specs['test-paths']) != 0;
    }

    assert(testsFailed != null);
    if (testsFailed) {
      printInfo('Some tests failed');
    } else {
      printInfo('All tests passed');
    }

    if (argResults['coverage']) {
      Map<String, CoverageCollector> collectorPool
        = <String, CoverageCollector>{};
      buildCoverageCollectionTasks(deviceMapping, collectorPool);
      printTrace('Collecting code coverage hitmap (this may take some time)');
      await runCoverageCollectionTasks(collectorPool);
      printInfo('Computing code coverage for each application ...');
      if (await computeAppsCoverage(collectorPool, name) != 0) {
        await uninstallTestingApps(deviceMapping);
        return 1;
      }
    }

    await uninstallTestingApps(deviceMapping);

    return testsFailed ? 1 : 0;
  }

  RunCommand() {
    usesSpecsOption();
    usesCoverageFlag();
    usesTAPReportOption();
  }
}
