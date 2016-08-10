// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:mdtest/src/mobile/device_spec.dart';
import 'package:mdtest/src/mobile/device.dart';
import 'package:mdtest/src/mobile/key_provider.dart';

import 'package:test/test.dart';

void main() {
  group('build device groups', () {
    test('by device id', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '456',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['123'].length, equals(1));
      expect(deviceGroups['123'][0], equals(devices[0]));
      expect(deviceGroups['456'].length, equals(1));
      expect(deviceGroups['456'][0], equals(devices[1]));
    });

    test('by platform, same platform', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'platform'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '456',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'platform'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['android'].length, equals(2));
      expect(deviceGroups['android'][0], equals(devices[0]));
      expect(deviceGroups['android'][1], equals(devices[1]));
    });

    test('by platform, different platforms', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'platform'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'platform'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['android'].length, equals(1));
      expect(deviceGroups['android'][0], equals(devices[0]));
      expect(deviceGroups['ios'].length, equals(1));
      expect(deviceGroups['ios'][0], equals(devices[1]));
    });

    test('by model name, same model name', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'model-name'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '456',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'model-name'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['Nexus 9'].length, equals(2));
      expect(deviceGroups['Nexus 9'][0], equals(devices[0]));
      expect(deviceGroups['Nexus 9'][1], equals(devices[1]));
    });

    test('by model name, different model names', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'model-name'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'model-name'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['Nexus 9'].length, equals(1));
      expect(deviceGroups['Nexus 9'][0], equals(devices[0]));
      expect(deviceGroups['iPhone 6S'].length, equals(1));
      expect(deviceGroups['iPhone 6S'][0], equals(devices[1]));
    });

    test('by OS version, same OS version', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '456',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'os-version'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['android 6.x.x'].length, equals(2));
      expect(deviceGroups['android 6.x.x'][0], equals(devices[0]));
      expect(deviceGroups['android 6.x.x'][1], equals(devices[1]));
    });

    test('group by OS version, different OS versions', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'os-version'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'os-version'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['android 6.x.x'].length, equals(1));
      expect(deviceGroups['android 6.x.x'][0], equals(devices[0]));
      expect(deviceGroups['ios 9.x.x'].length, equals(1));
      expect(deviceGroups['ios 9.x.x'][0], equals(devices[1]));
    });

    test('by screen size, same screen size', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'screen-size'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '456',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'screen-size'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['xlarge'].length, equals(2));
      expect(deviceGroups['xlarge'][0], equals(devices[0]));
      expect(deviceGroups['xlarge'][1], equals(devices[1]));
    });

    test('by screen size, different screen sizes', () {
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          },
          groupKey: 'screen-size'
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S',
            'os-version': '9.3.2',
            'screen-size': 'large'
          },
          groupKey: 'screen-size'
        )
      ];
      Map<String, List<Device>> deviceGroups = buildGroups(devices);
      expect(deviceGroups['xlarge'].length, equals(1));
      expect(deviceGroups['xlarge'][0], equals(devices[0]));
      expect(deviceGroups['large'].length, equals(1));
      expect(deviceGroups['large'][0], equals(devices[1]));
    });
  });

  group('build spec groups', () {
    test('by app path, same app path', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        )
      ];
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      expect(specGroups['yyy'].length, 2);
      expect(specGroups['yyy'][0], equals(specs[0]));
      expect(specGroups['yyy'][1], equals(specs[1]));
    });

    test('by app path, different app paths', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'yyy'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: {
            'app-root': 'xxx',
            'app-path': 'zzz'
          }
        )
      ];
      Map<String, List<DeviceSpec>> specGroups = buildGroups(specs);
      expect(specGroups['yyy'].length, equals(1));
      expect(specGroups['yyy'][0], equals(specs[0]));
      expect(specGroups['zzz'].length, equals(1));
      expect(specGroups['zzz'][0], equals(specs[1]));
    });
  });
}
