// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'helper.dart';
import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../mobile/key_provider.dart';
import '../algorithms/coverage.dart';
import '../algorithms/matching.dart';
import '../globals.dart';
import '../runner/mdtest_command.dart';
import '../test/coverage_collector.dart';

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
    printInfo('Running "mdtest auto command" ...');

    this._specs = await loadSpecs(argResults);
    if (sanityCheckSpecs(_specs, argResults['spec']) != 0) {
      printError('Test spec does not meet requirements.');
      return 1;
    }

    this._devices = await getDevices(groupKey: argResults['groupby']);
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

    Map<String, List<Device>> deviceGroups = buildGroups(_devices);
    Map<String, List<DeviceSpec>> deviceSpecGroups
      = buildGroups(allDeviceSpecs);

    GroupInfo groupInfo = new GroupInfo(deviceGroups, deviceSpecGroups);
    Map<CoverageMatrix, Map<DeviceSpec, Device>> cov2match
      = buildCoverage2MatchMapping(allDeviceMappings, groupInfo);
    CoverageMatrix appDeviceCoverageMatrix = new CoverageMatrix(groupInfo);
    Set<Map<DeviceSpec, Device>> chosenMappings
      = findMinimumMappings(cov2match, appDeviceCoverageMatrix);
    printMatches(chosenMappings);

    Map<String, CoverageCollector> collectorPool
      = <String, CoverageCollector>{};

    List<int> errRounds = [];
    List<int> failRounds = [];
    int roundNum = 0;
    for (Map<DeviceSpec, Device> deviceMapping in chosenMappings) {
      roundNum++;
      printInfo('Begining of Round #$roundNum');
      MDTestRunner runner = new MDTestRunner();

      if (await runner.runAllApps(deviceMapping) != 0) {
        printError('Error when running applications on #Round $roundNum');
        await uninstallTestingApps(deviceMapping);
        errRounds.add(roundNum);
        printInfo('End of Round #$roundNum\n');
        continue;
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
        printInfo('Some tests in Round #$roundNum failed');
        failRounds.add(roundNum);
      } else {
        printInfo('All tests in Round #$roundNum passed');
      }

      appDeviceCoverageMatrix.hit(deviceMapping);

      if (argResults['coverage']) {
        printTrace('Collecting code coverage hitmap (this may take some time)');
        buildCoverageCollectionTasks(deviceMapping, collectorPool);
        await runCoverageCollectionTasks(collectorPool);
      }

      await uninstallTestingApps(deviceMapping);
      printInfo('End of Round #$roundNum\n');
    }

    if (!briefMode) {
      printHitmap(
        'App-device coverage hit matrix:',
        appDeviceCoverageMatrix
      );
    }

    if (errRounds.isNotEmpty) {
      printInfo('Error in Round #${errRounds.join(', #')}');
      return 1;
    }

    if (failRounds.isNotEmpty) {
      printInfo('Some tests failed in Round #${failRounds.join(', #')}');
    } else {
      printInfo('All tests in all rounds passed');
    }

    if (argResults['coverage']) {
      printInfo('Computing code coverage for each application ...');
      if (await computeAppsCoverage(collectorPool, name) != 0)
        return 1;
    }

    return failRounds.isNotEmpty ? 1 : 0;
  }

  AutoCommand() {
    usesSpecsOption();
    usesCoverageFlag();
    usesTAPReportOption();
    argParser.addOption('groupby',
      defaultsTo: 'device-id',
      allowed: [
        'device-id',
        'platform',
        'model-name',
        'os-version',
        'screen-size'
      ],
      help: 'Device property used to group devices to'
            'adjust app-device coverage criterion.'
    );
  }
}
