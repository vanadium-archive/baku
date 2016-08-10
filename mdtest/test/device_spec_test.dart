// Copyright 2016 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:mdtest/src/mobile/device_spec.dart';
import 'package:mdtest/src/mobile/device.dart';

import 'package:test/test.dart';

void main() {
  group('device spec matches', () {
    Device device;

    setUpAll(() {
      device = new Device(
        properties: <String, String>{
          'platform': 'ios',
          'device-id': '123',
          'model-name': 'iPhone 6S Plus',
          'os-version': '9.3.4',
          'screen-size': 'large',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
    });

    test('platform matches', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'platform': 'ios',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(true));
    });

    test('platform does not match', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'platform': 'android',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(false));
    });

    test('device id matches', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'device-id': '123',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(true));
    });

    test('device id does not match', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'device-id': '456',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(false));
    });

    test('model name matches', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'model-name': 'iPhone 6S Plus',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(true));
    });

    test('model name does not match', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'model-name': 'iPhone 5',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(false));
    });

    test('os version matches', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'platform': 'ios',
          'os-version': '>=9.3.4',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(true));
    });

    test('os version does not match', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'platform': 'ios',
          'os-version': '>9.4.0',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(false));
    });

    test('os version matches', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'screen-size': 'large',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(true));
    });

    test('os version does not match', () {
      DeviceSpec spec = new DeviceSpec(
        'Alice',
        specProperties: <String, String>{
          'screen-size': 'normal',
          'app-root': 'xxx',
          'app-path': 'yyy'
        }
      );
      expect(spec.matches(device), equals(false));
    });
  });
}
