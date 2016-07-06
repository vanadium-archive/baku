// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'runner.dart';
import '../mobile/device.dart';
import '../mobile/device_spec.dart';
import '../algorithms/matching.dart';
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

    MDTestRunner runner = new MDTestRunner();

    if (await runner.runAllApps(deviceMapping) != 0) {
      printError('Error when running applications');
      return 1;
    }

    await storeMatches(deviceMapping);

    if (await runner.runTest(_specs['test-path']) != 0) {
      printError('Test execution exit with error.');
      return 1;
    }

    return 0;
  }

  RunCommand() {
    usesSpecsOption();
  }
}
