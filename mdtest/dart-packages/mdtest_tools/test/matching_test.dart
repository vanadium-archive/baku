// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:mdtest_tools/src/mobile/device_spec.dart';
import 'package:mdtest_tools/src/mobile/device.dart';
import 'package:mdtest_tools/src/algorithms/matching.dart';

import 'package:test/test.dart';

void main() {
  group('individual matches', () {
    test('return empty matches if specs is empty', () {
      List<DeviceSpec> specs = <DeviceSpec>[];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '123',
            'model-name': 'Nexus 9',
            'os-version': '6.0.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      expect(individualMatches.isEmpty, equals(true));
    });

    test('spec match empty set if devices is empty', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'device-id': 'abc',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'android',
            'device-id': 'def',
            'model-name': 'Nexus 6',
            'os-version': '>6.0.2 <7.0.0',
            'screen-size': 'large'
          }
        )
      ];
      List<Device> devices = <Device>[];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      individualMatches.forEach(
        (DeviceSpec spec, Set<Device> matchedDevices)
          => expect(matchedDevices.isEmpty, equals(true))
      );
    });

    test('common cases', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'android',
            'os-version': '>6.0.2 <7.0.0'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '123',
            'model-name': 'iPhone 5',
            'os-version': '8.3.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S Plus',
            'os-version': '9.3.4',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '789',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      expect(
        individualMatches[specs[0]].containsAll([devices[1]]),
        equals(true)
      );
      expect(
        individualMatches[specs[1]].containsAll([devices[2]]),
        equals(true)
      );
    });
  });

  group('first app-device mapping', () {
    test('no matching should return null', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '123',
            'model-name': 'iPhone 5',
            'os-version': '8.3.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S Plus',
            'os-version': '9.3.4',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '789',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      Map<DeviceSpec, Device> appDeviceMapping
        = findMatchingDeviceMapping(specs, individualMatches);
      expect(appDeviceMapping, equals(null));
    });

    test('return first match if matches exist', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'android',
            'model-name': 'Nexus 9',
            'os-version': '>6.0.0'
          }
        ),
        new DeviceSpec(
          'Susan',
          specProperties: <String, String>{
            'platform': 'android',
            'screen-size': 'normal'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '123',
            'model-name': 'iPhone 6S Plus',
            'os-version': '8.3.2',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S Plus',
            'os-version': '9.3.4',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '789',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '101112',
            'model-name': 'Nexus 4',
            'os-version': '4.4.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '131415',
            'model-name': 'Nexus 5',
            'os-version': '4.6.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '16171718',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      Map<DeviceSpec, Device> appDeviceMapping
        = findMatchingDeviceMapping(specs, individualMatches);
      expect(appDeviceMapping[specs[0]], equals(devices[1]));
      expect(appDeviceMapping[specs[1]], equals(devices[2]));
      expect(appDeviceMapping[specs[2]], equals(devices[3]));
    });
  });

  group('all app-device mappings', () {
    test('return empty mapping if no mapping found', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'android',
            'os-version': '>6.0.2 <7.0.0'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '123',
            'model-name': 'iPhone 5',
            'os-version': '8.3.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '789',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allAppDeviceMapping
        = findAllMatchingDeviceMappings(specs, individualMatches);
      expect(allAppDeviceMapping.isEmpty, equals(true));
    });

    test('return all mappings if exist', () {
      List<DeviceSpec> specs = <DeviceSpec>[
        new DeviceSpec(
          'Alice',
          specProperties: <String, String>{
            'platform': 'ios',
            'model-name': 'iPhone 6S Plus',
            'os-version': '^9.0.0',
            'screen-size': 'large'
          }
        ),
        new DeviceSpec(
          'Bob',
          specProperties: <String, String>{
            'platform': 'android',
            'model-name': 'Nexus 9',
            'os-version': '>6.0.0'
          }
        ),
        new DeviceSpec(
          'Susan',
          specProperties: <String, String>{
            'platform': 'android',
            'screen-size': 'normal'
          }
        )
      ];
      List<Device> devices = <Device>[
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '123',
            'model-name': 'iPhone 6S Plus',
            'os-version': '8.3.2',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'ios',
            'device-id': '456',
            'model-name': 'iPhone 6S Plus',
            'os-version': '9.3.4',
            'screen-size': 'large'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '789',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '101112',
            'model-name': 'Nexus 4',
            'os-version': '4.4.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '131415',
            'model-name': 'Nexus 5',
            'os-version': '4.6.2',
            'screen-size': 'normal'
          }
        ),
        new Device(
          properties: <String, String>{
            'platform': 'android',
            'device-id': '16171718',
            'model-name': 'Nexus 9',
            'os-version': '6.5.1',
            'screen-size': 'xlarge'
          }
        )
      ];
      Map<DeviceSpec, Set<Device>> individualMatches
        = findIndividualMatches(specs, devices);
      List<Map<DeviceSpec, Device>> allAppDeviceMapping
        = findAllMatchingDeviceMappings(specs, individualMatches);
      expect(allAppDeviceMapping[0][specs[0]], equals(devices[1]));
      expect(allAppDeviceMapping[0][specs[1]], equals(devices[2]));
      expect(allAppDeviceMapping[0][specs[2]], equals(devices[3]));
      expect(allAppDeviceMapping[1][specs[0]], equals(devices[1]));
      expect(allAppDeviceMapping[1][specs[1]], equals(devices[2]));
      expect(allAppDeviceMapping[1][specs[2]], equals(devices[4]));
      expect(allAppDeviceMapping[2][specs[0]], equals(devices[1]));
      expect(allAppDeviceMapping[2][specs[1]], equals(devices[5]));
      expect(allAppDeviceMapping[2][specs[2]], equals(devices[3]));
      expect(allAppDeviceMapping[3][specs[0]], equals(devices[1]));
      expect(allAppDeviceMapping[3][specs[1]], equals(devices[5]));
      expect(allAppDeviceMapping[3][specs[2]], equals(devices[4]));
    });
  });
}
